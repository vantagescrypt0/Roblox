---
type: community
cohesion: 0.33
members: 15
---

# Inventory and Coins

**Cohesion:** 0.33 - loosely connected
**Members:** 15 nodes

## Members
- [[DataService.GetData()]] - code - game/src/server/Services/DataService.luau
- [[DataService.MarkChanged()]] - code - game/src/server/Services/DataService.luau
- [[InventoryService.Add()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.AddCoins()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.Count()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.Remove()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.RemoveMany()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.SpendCoins()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.UseTool()]] - code - game/src/server/Services/InventoryService.luau
- [[InventoryService.luau]] - code - game/src/server/Services/InventoryService.luau
- [[ProgressionService.AddPlayerXP()]] - code - game/src/server/Services/ProgressionService.luau
- [[autoHotbar()]] - code - game/src/server/Services/InventoryService.luau
- [[clearIfEmpty()]] - code - game/src/server/Services/InventoryService.luau
- [[giveReward()]] - code - game/src/server/Services/QuestService.luau
- [[sellItem()]] - code - game/src/server/Services/MarketService.luau

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Inventory_and_Coins
SORT file.name ASC
```

## Connections to other communities
- 10 edges to [[_COMMUNITY_Market, Mobs and Quests]]
- 10 edges to [[_COMMUNITY_Warzone Raids]]
- 7 edges to [[_COMMUNITY_Farming]]
- 6 edges to [[_COMMUNITY_Combat and Held Tools]]
- 4 edges to [[_COMMUNITY_Block Breaking and Toughness]]
- 2 edges to [[_COMMUNITY_Island Plots and Spawning]]
- 2 edges to [[_COMMUNITY_Hotbar and Item Icons]]
- 1 edge to [[_COMMUNITY_Skills, Levels and Content]]
- 1 edge to [[_COMMUNITY_Islands Research and Pillars]]

## Top bridge nodes
- [[DataService.GetData()]] - degree 21, connects to 4 communities
- [[DataService.MarkChanged()]] - degree 17, connects to 4 communities
- [[InventoryService.Add()]] - degree 9, connects to 4 communities
- [[ProgressionService.AddPlayerXP()]] - degree 7, connects to 4 communities
- [[InventoryService.luau]] - degree 13, connects to 3 communities