local Progression = {}
local function integer(value, fallback, maximum)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return fallback end
    return math.max(0, math.min(maximum, math.floor(value)))
end
local slots = { Weapon = true, Armor = true, Accessory = true, Artifact = true }

function Progression.new(catalog, unlockAll)
    local units = { iruko = { Level = 1, XP = 0, Shiny = false } }
    if unlockAll then
        for id in pairs(catalog) do units[id] = { Level = 1, XP = 0, Shiny = false } end
    end
    return { Version = 1, Main = "iruko", Units = units, Gold = 0, Spins = 5,
        Souls = {}, Pity = 0, Inventory = {}, Equipment = {}, Runs = 0 }
end

function Progression.sanitize(raw, catalog, config)
    assert(type(raw) == "table", "Perfil inválido")
    assert(raw.Version == nil or raw.Version == 1, "Versão de perfil não suportada")
    local data = Progression.new(catalog, false)
    for id, definition in pairs(catalog) do
        for _, variant in ipairs({ id, id .. "_shiny" }) do
            local unit = type(raw.Units) == "table" and raw.Units[variant]
            if type(unit) == "table" then
                local level = math.max(1, integer(unit.Level, 1, config.MaxLevel))
                data.Units[variant] = { Level = level, XP = level == config.MaxLevel and 0 or integer(unit.XP, 0, config.xpForLevel(level) - 1), Shiny = variant ~= id }
            end
            local soul = type(raw.Souls) == "table" and raw.Souls[variant]
            data.Souls[variant] = integer(soul, 0, 1000000)
        end
    end
    if config.DevelopmentUnlockAll then
        for id in pairs(catalog) do
            if not data.Units[id] then data.Units[id] = { Level = 1, XP = 0, Shiny = false } end
        end
    end
    if type(raw.Main) == "string" and data.Units[raw.Main] then data.Main = raw.Main end
    if type(raw.Support) == "string" and raw.Support ~= data.Main and data.Units[raw.Support] then data.Support = raw.Support end
    data.Gold, data.Spins = integer(raw.Gold, 0, 100000000), integer(raw.Spins, 5, 1000000)
    data.Pity, data.Runs = integer(raw.Pity, 0, config.RollPity - 1), integer(raw.Runs, 0, 1000000)
    local ids = {}
    for _, item in ipairs(type(raw.Inventory) == "table" and raw.Inventory or {}) do
        if #data.Inventory >= config.InventoryLimit then break end
        if type(item) == "table" and type(item.Id) == "string" and #item.Id <= 64 and not ids[item.Id]
            and slots[item.Slot] and type(item.Name) == "string" then
            ids[item.Id] = true
            table.insert(data.Inventory, { Id = item.Id, Slot = item.Slot, Name = string.sub(item.Name, 1, 80),
                Rarity = item.Rarity == "Rare" and "Rare" or "Common", Power = math.max(1, integer(item.Power, 1, 25)) })
        end
    end
    if type(raw.Equipment) == "table" then
        for slot in pairs(slots) do
            for _, item in ipairs(data.Inventory) do
                if item.Slot == slot and raw.Equipment[slot] == item.Id then data.Equipment[slot] = item.Id end
            end
        end
    end
    return data
end

function Progression.pack(state)
    return { Version = 1, Main = state.Main, Support = state.Support, Units = state.Units,
        Gold = state.Gold, Spins = state.Spins, Souls = state.Souls, Pity = state.Pity,
        Inventory = state.Inventory, Equipment = state.Equipment, Runs = state.Runs }
end

function Progression.bonuses(state)
    local result = { Attack = 1, HP = 1, Speed = 1, Skill = 1 }
    local keys = { Weapon = "Attack", Armor = "HP", Accessory = "Speed", Artifact = "Skill" }
    for _, item in ipairs(state.Inventory or {}) do
        if state.Equipment[item.Slot] == item.Id then result[keys[item.Slot]] = 1 + item.Power / 100 end
    end
    return result
end

function Progression.equip(state, itemId)
    for _, item in ipairs(state.Inventory) do
        if item.Id == itemId then state.Equipment[item.Slot] = item.Id return true end
    end
    return false
end

function Progression.roll(state, config, integerRoll, chanceRoll)
    if state.Spins < 1 then return nil end
    local selected
    if state.Pity >= config.RollPity - 1 then selected = "gaoro"
    else
        local pick, sum = integerRoll(1, 100), 0
        for _, id in ipairs({ "iruko", "renli", "kurino", "gaoro" }) do
            sum = sum + config.RollWeights[id]
            if pick <= sum then selected = id break end
        end
    end
    if not selected then return nil end
    state.Spins = state.Spins - 1
    state.Pity = selected == "gaoro" and 0 or state.Pity + 1
    local shiny = chanceRoll() < config.ShinyChance
    local key = selected .. (shiny and "_shiny" or "")
    local duplicate = state.Units[key] ~= nil
    if duplicate then state.Souls[key] = (state.Souls[key] or 0) + 1
    else state.Units[key] = { Level = 1, XP = 0, Shiny = shiny } end
    return { Id = selected, UnitId = key, Shiny = shiny, Duplicate = duplicate }
end

return Progression
