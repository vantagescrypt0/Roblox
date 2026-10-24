---
type: community
cohesion: 0.19
members: 16
---

# Player Data and Held Items

**Cohesion:** 0.19 - loosely connected
**Members:** 16 nodes

## Members
- [[DataService.OnChanged()]] - code - game/src/server/Services/DataService.luau
- [[DataService.OnDataLoaded()]] - code - game/src/server/Services/DataService.luau
- [[DataService.Start()]] - code - game/src/server/Services/DataService.luau
- [[DataService.luau]] - code - game/src/server/Services/DataService.luau
- [[HotbarService.GetHeldItem()]] - code - game/src/server/Services/HotbarService.luau
- [[HotbarService.Start()]] - code - game/src/server/Services/HotbarService.luau
- [[HotbarService.luau]] - code - game/src/server/Services/HotbarService.luau
- [[Leaderstats.Start()]] - code - game/src/server/Services/Leaderstats.luau
- [[QuestService.Start()]] - code - game/src/server/Services/QuestService.luau
- [[isSlot()]] - code - game/src/server/Services/HotbarService.luau
- [[onPlayerAdded()]] - code - game/src/server/Services/DataService.luau
- [[onSelectSlot()]] - code - game/src/server/Services/HotbarService.luau
- [[onSetHotbar()]] - code - game/src/server/Services/HotbarService.luau
- [[refreshHeld()]] - code - game/src/server/Services/HotbarService.luau
- [[script_parent_combatservice]] - concept
- [[script_parent_parent_packages_profilestore]] - concept

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Player_Data_and_Held_Items
SORT file.name ASC
```

## Connections to other communities
- 12 edges to [[_COMMUNITY_Farming, Combat and Inventory]]
- 2 edges to [[_COMMUNITY_Breaking, Placing and Crafting]]
- 2 edges to [[_COMMUNITY_Mouse and Touch Controls]]
- 1 edge to [[_COMMUNITY_Islands Research]]
- 1 edge to [[_COMMUNITY_Decisions and Island Tiers]]

## Top bridge nodes
- [[HotbarService.luau]] - degree 12, connects to 3 communities
- [[DataService.luau]] - degree 9, connects to 2 communities
- [[HotbarService.GetHeldItem()]] - degree 5, connects to 2 communities
- [[refreshHeld()]] - degree 6, connects to 1 community
- [[onSetHotbar()]] - degree 5, connects to 1 community