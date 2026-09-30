local Config = {
    ArenaSize = 160,
    DefaultCharacter = "iruko",
    MaxLevel = 30,
    SupportXPRatio = 0.5,
    DevelopmentUnlockAll = true,
    CameraOffset = Vector3.new(0, 65, 48),
    EnemyLimit = 24,
    MapTheme = "DragonWorld",
    EnergyRegen = 16,
    DashEffect = "evade",
    RemoteBurst = 18,
    RemoteRate = 12,
    SaveInterval = 45,
    SessionLease = 180,
    InventoryLimit = 60,
    ShinyChance = 0.01,
    RollPity = 10,
    RollWeights = { iruko = 55, renli = 20, kurino = 20, gaoro = 5 },
}
function Config.xpForLevel(level)
    return 80 + (level - 1) * 35
end
return Config
