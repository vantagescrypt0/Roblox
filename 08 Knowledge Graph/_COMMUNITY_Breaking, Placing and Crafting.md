---
type: community
cohesion: 0.06
members: 70
---

# Breaking, Placing and Crafting

**Cohesion:** 0.06 - loosely connected
**Members:** 70 nodes

## Members
- [[BlockService.Start()]] - code - game/src/server/Services/BlockService.luau
- [[BlockService.luau]] - code - game/src/server/Services/BlockService.luau
- [[BlockWorld.cellAt()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.destroy()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.drawAll()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.get()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.hasNeighbour()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.key()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.luau]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.new()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.part()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.position()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.set()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.setRaw()]] - code - game/src/server/Util/BlockWorld.luau
- [[BlockWorld.unkey()]] - code - game/src/server/Util/BlockWorld.luau
- [[Blocks.luau]] - code - game/src/shared/Blocks.luau
- [[Decision Minecraft-style block islands (break and place, saved)]] - concept - 07 Roadmap/Decision Log.md
- [[Decision block toughness + tool power (Minecraft rules)]] - concept - 07 Roadmap/Decision Log.md
- [[IslandService.GetIsland()]] - code - game/src/server/Services/IslandService.luau
- [[IslandService.OnIslandCreated()]] - code - game/src/server/Services/IslandService.luau
- [[IslandService.Rebuild()]] - code - game/src/server/Services/IslandService.luau
- [[IslandService.RecordChange()]] - code - game/src/server/Services/IslandService.luau
- [[IslandService.SendHome()]] - code - game/src/server/Services/IslandService.luau
- [[IslandService.Start()]] - code - game/src/server/Services/IslandService.luau
- [[IslandService.luau]] - code - game/src/server/Services/IslandService.luau
- [[Items.luau]] - code - game/src/shared/Items.luau
- [[Mining.BreakTime()]] - code - game/src/shared/Mining.luau
- [[Mining.UsesTool()]] - code - game/src/shared/Mining.luau
- [[Mining.luau]] - code - game/src/shared/Mining.luau
- [[Quests.luau]] - code - game/src/shared/Quests.luau
- [[Recipes.luau]] - code - game/src/shared/Recipes.luau
- [[Tool path quests wood - planks - sticks - pickaxe - stone]] - concept - 03 Design/Tutorial & Quests.md
- [[Tools.luau]] - code - game/src/shared/Tools.luau
- [[Tools pickaxe, axe, shovel, sword in Wooden  Stone  Crystal]] - concept - 04 Content/Content Index.md
- [[addTree()]] - code - game/src/server/Services/IslandService.luau
- [[announce()]] - code - game/src/server/Services/IslandService.luau
- [[blockedByCharacter()]] - code - game/src/server/Services/BlockService.luau
- [[build()_1]] - code - game/src/server/Services/IslandService.luau
- [[catchFallers()]] - code - game/src/server/Services/IslandService.luau
- [[claimPlot()]] - code - game/src/server/Services/IslandService.luau
- [[clampTier()]] - code - game/src/server/Services/IslandService.luau
- [[edgeRadius()]] - code - game/src/server/Services/IslandService.luau
- [[exposed()]] - code - game/src/server/Util/BlockWorld.luau
- [[generate()]] - code - game/src/server/Services/IslandService.luau
- [[inReach()]] - code - game/src/server/Services/BlockService.luau
- [[isCell()]] - code - game/src/server/Services/BlockService.luau
- [[makePart()]] - code - game/src/server/Util/BlockWorld.luau
- [[makePortalSurface()_1]] - code - game/src/server/Services/IslandService.luau
- [[makeSpawn()]] - code - game/src/server/Services/IslandService.luau
- [[nearStation()]] - code - game/src/server/Services/CraftingService.luau
- [[occludes()]] - code - game/src/server/Util/BlockWorld.luau
- [[onBreak()]] - code - game/src/server/Services/BlockService.luau
- [[onDataLoaded()_1]] - code - game/src/server/Services/IslandService.luau
- [[onPlace()]] - code - game/src/server/Services/BlockService.luau
- [[onPlayerRemoving()]] - code - game/src/server/Services/IslandService.luau
- [[plotCenter()]] - code - game/src/server/Services/IslandService.luau
- [[refresh()]] - code - game/src/server/Util/BlockWorld.luau
- [[regrowRocks()]] - code - game/src/server/Services/IslandService.luau
- [[regrowTrees()]] - code - game/src/server/Services/IslandService.luau
- [[replicatedstorage_shared_blocks]] - concept
- [[replicatedstorage_shared_config]] - concept
- [[replicatedstorage_shared_mining]] - concept
- [[rollRockBlock()]] - code - game/src/server/Services/IslandService.luau
- [[script_parent_blocks]] - concept
- [[script_parent_hotbarservice]] - concept
- [[script_parent_tools]] - concept
- [[set()]] - code - game/src/server/Services/TownService.luau
- [[spawnCharacter()]] - code - game/src/server/Services/IslandService.luau
- [[template()]] - code - game/src/server/Util/BlockWorld.luau
- [[undergroundBlock()]] - code - game/src/server/Services/IslandService.luau

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Breaking_Placing_and_Crafting
SORT file.name ASC
```

## Connections to other communities
- 27 edges to [[_COMMUNITY_Farming, Combat and Inventory]]
- 9 edges to [[_COMMUNITY_Mouse and Touch Controls]]
- 4 edges to [[_COMMUNITY_Decisions and Island Tiers]]
- 2 edges to [[_COMMUNITY_Player Data and Held Items]]
- 1 edge to [[_COMMUNITY_Skills, Levels and Content]]
- 1 edge to [[_COMMUNITY_Tutorial and Roadmap]]

## Top bridge nodes
- [[IslandService.luau]] - degree 33, connects to 3 communities
- [[BlockService.luau]] - degree 19, connects to 2 communities
- [[onBreak()]] - degree 15, connects to 2 communities
- [[replicatedstorage_shared_blocks]] - degree 7, connects to 2 communities
- [[Decision Minecraft-style block islands (break and place, saved)]] - degree 5, connects to 2 communities