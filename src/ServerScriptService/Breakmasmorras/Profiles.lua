local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Breakmasmorras")
local Config, Characters, Progression = require(Shared.Config), require(Shared.Characters), require(Shared.Progression)
local Profiles = {}
Profiles.__index = Profiles

function Profiles.new()
    local namespace = RunService:IsStudio() and "Breakmasmorras_Studio_v1" or "Breakmasmorras_Live_v1"
    local available, store = pcall(function()
        return DataStoreService:GetDataStore(namespace)
    end)
    if not available then
        warn("Breakmasmorras: DataStore indisponível; esta sessão usará progresso temporário: " .. tostring(store))
        store = nil
    end
    return setmetatable({ Store = store,
        Token = game.JobId .. HttpService:GenerateGUID(false), Sessions = {} }, Profiles)
end

function Profiles:load(player)
    if not self.Store then
        return Progression.new(Characters, Config.DevelopmentUnlockAll), "Temporário: DataStore indisponível; esta sessão não será salva."
    end
    local profile, blocked, invalid
    local ok = pcall(function()
        self.Store:UpdateAsync("Player_" .. player.UserId, function(old)
            blocked, invalid = false, false
            local record = old or {}
            if type(record) ~= "table" then invalid = true return nil end
            local lock = record.Lock
            if lock and lock.Token ~= self.Token and lock.Expires > os.time() then blocked = true return nil end
            if record.Data then
                local valid, clean = pcall(Progression.sanitize, record.Data, Characters, Config)
                if not valid then invalid = true return nil end
                profile = clean
            else profile = Progression.new(Characters, Config.DevelopmentUnlockAll) end
            return { Data = profile, Lock = { Token = self.Token, Expires = os.time() + Config.SessionLease } }, player.UserId > 0 and { player.UserId } or {}
        end)
    end)
    if blocked or invalid then return nil, blocked and "Perfil aberto em outro servidor; tente novamente." or "Perfil inválido; gravação cancelada." end
    if not ok or not profile then
        -- Never save a fallback profile over data that failed to load.
        return Progression.new(Characters, Config.DevelopmentUnlockAll), "Temporário: DataStore indisponível; esta sessão não será salva."
    end
    self.Sessions[player] = { Busy = false, Closing = false, Status = "Salvamento ativo" }
    return profile, "Salvamento ativo"
end

function Profiles:save(player, data, release)
    local session = self.Sessions[player]
    if not session or session.Closing then return false end
    if release then
        while session.Busy do task.wait(0.1) end
        if session.Closing then return false end
        session.Closing = true
    elseif session.Busy then return false end
    session.Busy = true
    -- Immutable data snapshot before UpdateAsync yields.
    local snapshot = HttpService:JSONDecode(HttpService:JSONEncode(data))
    local owned = false
    local ok
    for attempt = 1, 3 do
        ok = pcall(function()
            self.Store:UpdateAsync("Player_" .. player.UserId, function(record)
            owned = type(record) == "table" and record.Lock and record.Lock.Token == self.Token
            if not owned then return nil end
                return { Data = snapshot, Lock = not release and { Token = self.Token, Expires = os.time() + Config.SessionLease } or nil }, player.UserId > 0 and { player.UserId } or {}
            end)
        end)
        if ok then break end
        if attempt < 3 then task.wait(attempt) end
    end
    session.Busy = false
    if release then self.Sessions[player] = nil
    elseif not ok then session.Status = "Falha ao salvar; nova tentativa no autosave"
    elseif not owned then
        session.Status = "Sessão perdida: reconecte para preservar seus dados"
        session.Closing = true
        player:Kick("A sessão de dados foi transferida. Reconecte para evitar perda de progresso.")
    else session.Status = "Salvo automaticamente" end
    return ok and owned
end

return Profiles
