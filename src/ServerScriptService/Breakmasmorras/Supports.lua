local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Characters=require(Shared.Characters)
local EffectCatalog=require(Shared.EffectCatalog)
local Rules=require(Shared.Rules)
local Combat=require(script.Parent.Combat)
local Rigs=require(script.Parent.Rigs)
local Supports={}
Supports.__index=Supports
function Supports.new(combat) return setmetatable({Combat=combat,Actors={}},Supports) end
function Supports:remove(player)
    local actor=self.Actors[player]
    if actor then actor.Model:Destroy() end
    self.Actors[player]=nil
end
function Supports:equip(player)
    self:remove(player)
    local state=self.Combat.States[player]
    local _,root=Combat.actor(player)
    if not state or not state.Support or not root then return end
    local unit=state.Units[state.Support]
    local model,humanoid,supportRoot=Rigs.spawn(self.Combat.World.Supports,
        Characters[Rules.baseId(state.Support)].Name..(unit.Shiny and " Shiny" or "").." · Support",
        root.Position+Vector3.new(5,0,4),Rules.damage(100,unit.Level,unit.Shiny),unit.Shiny and 24 or 20)
    humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
    self.Actors[player]={Model=model,Humanoid=humanoid,Root=supportRoot,Next=0,NextMove=0}
end
function Supports:update()
    local now=os.clock()
    for player,actor in pairs(self.Actors) do
        local state=self.Combat.States[player]
        local _,mainRoot=Combat.actor(player)
        if not state or not mainRoot or not actor.Model.Parent then self:remove(player)
        else
            local gap=(actor.Root.Position-mainRoot.Position).Magnitude
            if gap>50 then actor.Model:PivotTo(CFrame.new(mainRoot.Position+Vector3.new(5,0,4))) end
            if now>=actor.NextMove then
                actor.NextMove=now+0.3
                if gap>7 then actor.Humanoid:MoveTo(mainRoot.Position+Vector3.new(5,0,4)) end
            end
            local closest,distance=nil,60
            for _,enemy in ipairs(self.Combat.Enemies) do
                if enemy.Model.Parent and enemy.Humanoid.Health>0 then
                    local current=(enemy.Root.Position-mainRoot.Position).Magnitude
                    if current<distance then closest,distance=enemy,current end
                end
            end
            if closest and now>=actor.Next then
                local definition=Characters[Rules.baseId(state.Support)]
                local skill=definition.Support
                local effect=EffectCatalog[skill.Effect]
                if effect and type(effect.Logic.Support)=="function" then
                    actor.Next=now+skill.Cooldown
                    state.SupportParticipated=true
                    local unit=state.Units[state.Support]
                    effect.Logic.Support(self.Combat,{
                        State=state,Skill=skill,Definition=definition,MainRoot=mainRoot,Now=now,Config=effect.Config,
                        Amount=skill.Amount and Rules.damage(skill.Amount,unit.Level,unit.Shiny) or nil,
                    })
                end
            end
        end
    end
end
return Supports
