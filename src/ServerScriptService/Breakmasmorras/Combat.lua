local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Characters=require(Shared.Characters)
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local Progression=require(Shared.Progression)
local EffectCatalog=require(Shared.EffectCatalog)
local Combat={}
Combat.__index=Combat
function Combat.actor(player)
    local model=player.Character
    if not model then return nil end
    local root=model:FindFirstChild("HumanoidRootPart")
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return nil end
    return model,root,humanoid
end
function Combat.new(states,world,effects)
    return setmetatable({States=states,World=world,Effects=effects,EffectCatalog=EffectCatalog,Enemies={}},Combat)
end
function Combat:emit(kind,position,color,radius,endpoint,duration,impactLevel,impactProfile)
    self.Effects:FireAllClients({Kind=kind,Position=position,Color=color,Radius=radius or 4,Endpoint=endpoint,Duration=duration or 0.4,ImpactLevel=impactLevel,ImpactProfile=impactProfile})
end
function Combat:wallEnd(origin,target)
    if (target-origin).Magnitude<0.01 then return origin end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    local walls={}
    for _,container in ipairs({self.World.Folder,self.World.Dungeon}) do
        if container then
            for _,value in ipairs(container:GetDescendants()) do
                if value:IsA("BasePart") and value.Name=="Wall" then table.insert(walls,value) end
            end
        end
    end
    params.FilterDescendantsInstances=walls
    local result=workspace:Raycast(origin,target-origin,params)
    if result then return result.Position-(target-origin).Unit*2 end
    return target
end
function Combat:move(player,state,direction,distance,invulnerability)
    local model,root=Combat.actor(player)
    if not model then return end
    local endpoint=self:wallEnd(root.Position,root.Position+direction*distance)
    endpoint=Vector3.new(endpoint.X,root.Position.Y,endpoint.Z)
    model:PivotTo(CFrame.lookAt(endpoint,endpoint+direction))
    root.AssemblyLinearVelocity=Vector3.zero
    if invulnerability then state.InvulnerableUntil=os.clock()+(type(invulnerability)=="number" and invulnerability or 0.25) end
end
function Combat:playerDamage(player,amount)
    local state=self.States[player]
    local _,_,humanoid=Combat.actor(player)
    if not state or not humanoid or os.clock()<state.InvulnerableUntil then return end
    local absorbed=math.min(state.Shield,amount)
    state.Shield=state.Shield-absorbed
    humanoid:TakeDamage(amount-absorbed)
end
function Combat:enemyDamage(enemy,amount,player,skill)
    if enemy.Humanoid.Health<=0 or not enemy.Model.Parent then return end
    local state=self.States[player]
    if not state then return end
    local now=os.clock()
    local definition=Characters[Rules.baseId(state.Main)]
    local passive=self.EffectCatalog[definition.PassiveEffect]
    if passive and type(passive.Logic.Damage)=="function" then amount=passive.Logic.Damage(amount,skill,enemy,now,passive.Config) end
    if enemy.BreakUntil>now then amount=amount*1.2 end
    enemy.Contributors[player]=true
    enemy.Posture=enemy.Posture+amount*0.6
    if enemy.Posture>=enemy.MaxPosture then
        enemy.Posture=0
        enemy.BreakUntil=now+(enemy.Boss and 2 or 1.3)
        self:emit("break",enemy.Root.Position,Color3.fromRGB(255,240,130),5)
    end
    if skill.Stun then enemy.StunUntil=math.max(enemy.StunUntil,now+skill.Stun*(enemy.Boss and 0.15 or 1)) end
    if skill.Slow then enemy.SlowUntil=math.max(enemy.SlowUntil,now+skill.Slow*(enemy.Boss and 0.4 or 1)) end
    enemy.Humanoid:TakeDamage(amount)
    self:emit("hit",enemy.Root.Position,Color3.fromRGB(255,255,255),1.8)
end
function Combat:area(player,center,radius,damage,skill)
    for _,enemy in ipairs(self.Enemies) do
        if enemy.Model.Parent and enemy.Humanoid.Health>0 then
            local offset=enemy.Root.Position-center
            if Vector3.new(offset.X,0,offset.Z).Magnitude<=radius then self:enemyDamage(enemy,damage,player,skill) end
        end
    end
end
function Combat:line(player,origin,direction,range,width,damage,skill,color)
    local endpoint=self:wallEnd(origin,origin+direction*range)
    local length=(endpoint-origin).Magnitude
    local candidates={}
    for _,enemy in ipairs(self.Enemies) do
        if enemy.Model.Parent and enemy.Humanoid.Health>0 then
            local offset=enemy.Root.Position-origin
            offset=Vector3.new(offset.X,0,offset.Z)
            local along=offset:Dot(direction)
            if along>=0 and along<=length and (offset-direction*along).Magnitude<=width then
                table.insert(candidates,{Enemy=enemy,Distance=along})
            end
        end
    end
    table.sort(candidates,function(a,b) return a.Distance<b.Distance end)
    for index,candidate in ipairs(candidates) do
        if skill.Effect~="projectile" or index==1 then self:enemyDamage(candidate.Enemy,damage,player,skill) end
    end
    self:emit("line",origin,color,width,endpoint)
end
function Combat:cast(player,slot,aim)
    local state=self.States[player]
    local model,root=Combat.actor(player)
    if not state or not state.InDungeon or not model or type(slot)~="string" or #slot>12 then return end
    if typeof(aim)~="Vector3" or not Rules.finite(aim.X) or not Rules.finite(aim.Y) or not Rules.finite(aim.Z) then return end
    if math.abs(aim.X)>10000 or math.abs(aim.Y)>10000 or math.abs(aim.Z)>10000 then return end
    local now=os.clock()
    if now<(state.Cooldowns[slot] or 0) then return end
    local delta=Vector3.new(aim.X-root.Position.X,0,aim.Z-root.Position.Z)
    local direction
    if slot=="Dash" then
        direction=Vector3.new(aim.X,0,aim.Z)
        if direction.Magnitude<0.05 then direction=root.CFrame.LookVector end
    else
        direction=delta.Magnitude>0.01 and delta.Unit or root.CFrame.LookVector
    end
    direction=Vector3.new(direction.X,0,direction.Z)
    if direction.Magnitude<0.01 then return end
    direction=direction.Unit
    if slot=="Dash" then
        local dash=self.EffectCatalog[Config.DashEffect]
        if not dash or type(dash.Logic.Dash)~="function" then return end
        state.Cooldowns.Dash=now+dash.Config.Cooldown
        dash.Logic.Dash(self,{Player=player,State=state,Root=root,Direction=direction,Config=dash.Config})
        return
    end
    local definition=Characters[Rules.baseId(state.Main)]
    local skill=definition.Skills[slot]
    if not skill or state.Energy<skill.Cost then return end
    local effect=self.EffectCatalog[skill.Effect]
    if not effect or type(effect.Logic.Skill)~="function" then return end
    state.Energy=state.Energy-skill.Cost
    local haste=now<state.HasteUntil and state.Haste or 1
    state.Cooldowns[slot]=now+skill.Cooldown/(slot=="M1" and haste or 1)
    state.LastCombat=now
    local unit=state.Units[state.Main]
    local bonuses=Progression.bonuses(state)
    local damage=Rules.damage(skill.Damage,unit.Level,unit.Shiny)*definition.Attack*bonuses.Attack*(slot=="M1" and 1 or bonuses.Skill)
    if slot=="M1" then
        state.Combo=state.Combo+1
        if state.Combo>=3 then
            state.Combo=0
            local passive=self.EffectCatalog[definition.PassiveEffect]
            if passive and type(passive.Logic.Combo)=="function" then passive.Logic.Combo(state,now,passive.Config) end
        end
    end
    local passive=self.EffectCatalog[definition.PassiveEffect]
    if passive and type(passive.Logic.Empower)=="function" then damage=damage*passive.Logic.Empower(state,slot,passive.Config) end
    local center=root.Position+direction*math.min(delta.Magnitude,skill.Range)
    center=self:wallEnd(root.Position,center)
    if skill.Range==0 then center=root.Position end
    effect.Logic.Skill(self,{Player=player,State=state,Model=model,Root=root,Skill=skill,Damage=damage,
        Color=definition.Color,ImpactProfile=definition.ImpactProfile,Direction=direction,Center=center,Now=now,Config=effect.Config})
end
function Combat:update(delta)
    local now=os.clock()
    for player,state in pairs(self.States) do
        local _,root,humanoid=Combat.actor(player)
        state.Energy=math.min(100,state.Energy+delta*Config.EnergyRegen)
        if now>=state.ShieldUntil then state.Shield=0 end
        if humanoid then
            local definition,unit=Characters[Rules.baseId(state.Main)],state.Units[state.Main]
            humanoid.WalkSpeed=definition.Speed*(unit.Shiny and 1.2 or 1)*Progression.bonuses(state).Speed
            if now<state.HasteUntil then humanoid.WalkSpeed=humanoid.WalkSpeed*state.Haste end
            local passive=self.EffectCatalog[definition.PassiveEffect]
            if state.InDungeon and passive and type(passive.Logic.Update)=="function" then passive.Logic.Update(self,state,root,definition,now,passive.Config) end
        end
    end
end
return Combat
