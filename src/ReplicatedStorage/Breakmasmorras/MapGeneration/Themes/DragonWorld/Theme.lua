local theme = {
    Id = "DragonWorld",
    Palette = require(script.Parent.Palette),
    Biomes = require(script.Parent.Biomes),
    Props = require(script.Parent.Props),
    Landmarks = require(script.Parent.Landmarks),
    Structures = require(script.Parent.Structures),
    StructureCategories = { Temple = "Ruins", RuinCluster = "Ruins", CapsuleSite = "Technology", Camp = "Rock", Crater = "Rock" },
    GroundRules = { LayerNames = { "Base", "Terrain", "Path", "Detail", "Vegetation" } },
    CliffRules = { RequiresTopSurface = true, FaceMaterials = { "Rock", "Ground" } },
    VegetationRules = { MinSpacing = 5, DensityByBiome = true, GroundCover = { "GrassTuft", "Flowers", "TallGrass" } },
    PathRules = { MinWidth = 8, MaxWidth = 20, PreferCurved = true },
    WaterRules = { Types = { "River", "Pond", "Lake", "Waterfall" }, BridgeWhenCrossed = true },
}
return theme
