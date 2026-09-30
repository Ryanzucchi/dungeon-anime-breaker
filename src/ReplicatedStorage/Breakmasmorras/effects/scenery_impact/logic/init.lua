local config = require(script.Parent:WaitForChild("config"))

local Impact = {}
function Impact.quality(name)
    return config.Quality[name] and name or config.DefaultQuality
end
function Impact.level(value)
    if type(value) ~= "number" then return 1 end
    return math.clamp(math.floor(value), 1, 4)
end
function Impact.settings(level, quality)
    local normalized = Impact.level(level)
    local mode = config.Quality[Impact.quality(quality)]
    local levelSettings = config.Levels[tostring(normalized)]
    return mode, levelSettings, normalized
end
return Impact
