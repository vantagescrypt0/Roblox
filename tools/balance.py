"""Balance model for SKYBLOX: how long the skills and player level take, and how many coins
an hour each stage earns, worked out from the game's own mechanics. It fits the XP curves
and each resource's XP and price to the targets (Decision Log, 2026-10-27):

  a skill 1 -> 99 in ~25 hours of steady play, level 10 after ~1 hour
  player level 1 -> 50 in ~80 hours (5 after ~1 hour, 10 after ~4 hours)
  coins, the billion scale (your call, 2026-11-02): early ~3k an hour, mid ~150k, the top of
  the worlds ~2M+; a billion is hard but doable for a smart player, and the elite go far past
  it by owning many late-game nodes

How fast you gather: STEADY of your time is spent gathering (the rest is walking to shops,
crafting, menus). Breaking a block takes its break time (shared/Mining.luau: hardness x 1.5
/ tool efficiency) plus OVERHEAD to aim and move on; a crop harvest is just the overhead.
The worlds have far more nodes than one player can use (2,095 wild wheat, 477 coal, 175
birch logs...), so the player's own speed is the limit. tool_tier() is the best tool a
player has at a skill level.

What it fits: each resource gets a target XP an hour (RATE x a base) and coins an hour
(COINS), which set its XP and sell price; then the skill curve (A * level^Q) and the player
curve are solved to the hour targets. Copy the printed numbers into the game:
Leveling.luau (curves), BlockService GATHER and Crops.luau (XP), Items.luau (prices).

    python tools/balance.py
"""

import math

STEADY = 0.8
OVERHEAD = {"Mining": 1.2, "Woodcutting": 1.5, "Farming": 1.2, "Combat": 4.0}
# A fully charged sword swing and each tier's sword (Combat.luau, Tools.luau); a monster's
# "hardness" below is its health, and a kill takes as many swings as that needs
SWING = 0.625
SWORD = {1: 20, 2: 24, 3: 27, 4: 31, 5: 34, 6: 38, 7: 41}
# By hand, Wooden, Stone, Iron, then the late-game tiers: Amethyst (Crystal, from the
# Warzone, matches it), Sapphire, Ruby, Starsteel
EFFICIENCY = {0: 1, 1: 2, 2: 4, 3: 6, 4: 8, 5: 10, 6: 12, 7: 14}
# Mining level at which a pickaxe of each late tier can be made (the level of its ore)
LATE_TIERS = {4: 35, 5: 50, 6: 65, 7: 80}

MAX_SKILL = 99
MAX_PLAYER = 50
TARGET_L10, TARGET_L99 = 1.0, 25.0
TARGET_P5, TARGET_P10, TARGET_P50 = 1.0, 4.0, 80.0

# XP an hour of the level-1 resource, which sets the size of every XP number (bigger
# numbers only look grander; the hours don't change)
BASE_XP_RATE = 60000
# Player XP per action, as a share of the skill XP
PLAYER_SHARE = 1 / 3
# Beginner quests' player XP (Quests.luau), all done in about the first hour
QUEST_XP = 5000
# Crafting XP for a recipe, as a share of the skill XP its raw materials gave
CRAFT_SHARE = 1.5

# Resources: (name, skill level to unlock, tool tier needed (0 = none), hardness or None
# for crops, XP an hour at unlock as a multiple of BASE_XP_RATE, coins an hour at unlock)
ACTIVITIES = {
    "Mining": [
        ("Coal", 1, 1, 3, 1.0, 3000),
        ("Iron", 1, 2, 3, 1.3, 10000),
        ("Gold", 10, 3, 3, 2.2, 40000),
        # The deep cave: each about 3x the coins of the one before
        ("Silver", 20, 3, 3.5, 2.6, 120000),
        ("Amethyst", 35, 3, 4, 3.0, 400000),
        ("Sapphire", 50, 4, 4.5, 3.4, 2000000),
        # Late game: priced by LATE_PRICE, not these
        ("Ruby", 65, 5, 5, 3.8, 0),
        ("Starstone", 80, 6, 5.5, 4.2, 0),
    ],
    "Woodcutting": [
        ("Oak", 1, 0, 2, 1.2, 3000),
        ("Birch", 10, 0, 2, 1.55, 15000),
        ("Spruce", 20, 0, 2.5, 1.9, 50000),
        ("Cherry", 30, 0, 3, 2.25, 140000),
        ("Maple", 40, 0, 3.5, 2.6, 450000),
        ("Redwood", 55, 0, 4, 3.0, 1800000),
        ("Mangrove", 70, 0, 4.5, 3.4, 0),
        ("Starwood", 85, 0, 5, 3.8, 0),
    ],
    "Farming": [
        ("Wheat", 1, 0, None, 1.0, 3000),
        ("Carrot", 5, 0, None, 1.3, 9000),
        ("Potato", 10, 0, None, 1.55, 25000),
        ("Pumpkin", 15, 0, None, 1.9, 60000),
        ("Melon", 25, 0, None, 2.3, 160000),
        ("Sugarcane", 40, 0, None, 2.7, 1500000),
        ("Strawberry", 50, 0, None, 3.2, 0),
        ("Dragonfruit", 65, 0, None, 3.7, 0),
        ("Starfruit", 80, 0, None, 4.2, 0),
    ],
    # The Slaying World: the "hardness" here is the monster's health, and the coins are its drop's
    "Combat": [
        ("Slime", 1, 0, 60, 1.2, 3000),
        ("Thornling", 10, 0, 110, 1.55, 15000),
        ("BoarBrute", 20, 0, 180, 1.9, 50000),
        ("Rattlebones", 30, 0, 260, 2.25, 140000),
        ("Sporeling", 40, 0, 360, 2.6, 450000),
        ("FrostYeti", 55, 0, 520, 3.0, 1800000),
        ("Cinderkin", 70, 0, 700, 3.4, 0),
        ("Voidling", 85, 0, 900, 3.8, 0),
    ],
}
# The curves below were fitted to these three; Combat is fitted to the curves, so it doesn't move them
CURVE_SKILLS = ("Mining", "Woodcutting", "Farming")


# The late game: not in the Grinding Worlds, only from nodes on your own island (loot crates and
# Warzone chests; your call, 2026-11-02). They keep an XP and a price, but nobody grinds them
# at world pace, so they don't count toward how long a skill takes.
ISLAND_ONLY = {"Ruby", "Starstone", "Mangrove", "Starwood", "Strawberry", "Dragonfruit", "Starfruit", "Cinderkin", "Voidling"}
# What they sell for. Their supply is the limit, not the player's speed, so these are set by what
# one node, plot or tree should earn, not by a coins-an-hour target:
#   (units an hour from one, where they come from)
LATE_PRICE = {
    "Ruby": 5000,  # a node: 15 an hour
    "Starstone": 20000,  # a node: 12 an hour
    "Mangrove": 1500,  # a tree: ~30 logs, regrown in 30 minutes
    "Starwood": 6000,  # a tree: ~14 logs, regrown in 30 minutes
    "Strawberry": 4000,  # a plot: 10 an hour
    "Dragonfruit": 8000,  # a plot: ~8.6 an hour
    "Starfruit": 20000,  # a plot: 7.5 an hour
    # A spawner makes one every 4 and 5 minutes, like a Ruby and a Starstone node, but each is a
    # real fight (700 and 900 health), so they pay about 3x what a node of that rank does
    "Cinderkin": 15000,
    "Voidling": 50000,
}
# Late tools need Ruby or Starstone, so someone working only in the worlds stops at Sapphire
WORLD_TOP_TIER = 5

# Resources that aren't a grind of their own, priced against the ones above:
# (name, like resource, XP and price multiple of it)
#   Stone: island boulders only (a few nodes); quicker to break than ore
#   Glowberry: Warzone seeds only (Farming 8)
EXTRAS = [("Stone", "Coal", 0.75, 1.0), ("Glowberry", "Potato", 1.15, 4.0)]


def bonus(level, skill=None):  # Leveling.BonusChance: a double drop, +1% a level (not Combat's drops)
    return 0 if skill == "Combat" else min(max(level - 1, 0) * 0.01, 0.75)


def tool_tier(level, skill="Mining"):
    """Best tool at this skill level: Wooden at first, Stone soon after (beginner quests),
    Iron by level 5 (an Iron pickaxe or axe needs the skill at 4 and Crafting 3). Miners
    then make each late tier from its ore; the other skills stay on Iron for now (their late
    tools need the deep cave's ores)"""
    if skill == "Mining":
        for tier in sorted(LATE_TIERS, reverse=True):
            if level >= LATE_TIERS[tier]:
                return tier
    if level >= 5:
        return 3
    if level >= 2:
        return 2
    return 1


def actions_per_hour(skill, activity, level, top_tier=None):
    _, unlock, need, hardness, *_ = activity
    tier = tool_tier(level, skill)
    if top_tier:
        tier = min(tier, top_tier)
    if level < unlock or tier < need:
        return 0.0
    seconds = OVERHEAD[skill]
    if skill == "Combat":
        seconds += math.ceil(hardness / SWORD[tier]) * SWING
    elif hardness is not None:
        seconds += max(hardness * 1.5 / EFFICIENCY[tier], 0.05)
    return STEADY * 3600 / seconds


def unlock_level(skill, activity):
    """The first level a resource can be used (its unlock, or when the tool it needs comes)"""
    level = activity[1]
    while actions_per_hour(skill, activity, level) == 0:
        level += 1
    return level


# Each resource's XP and price from its target rates, measured with an Iron tool (level 5+)
# so every resource is compared the same way: a better ore always gives more per block
REFERENCE_LEVEL = 5
XP, PLAYER_XP, PRICE = {}, {}, {}
for _skill, _list in ACTIVITIES.items():
    for _a in _list:
        _at = max(unlock_level(_skill, _a), REFERENCE_LEVEL)
        _rate = actions_per_hour(_skill, _a, _at)
        XP[_a[0]] = max(1, round(BASE_XP_RATE * _a[4] / _rate / 5) * 5)
        PLAYER_XP[_a[0]] = max(1, round(XP[_a[0]] * PLAYER_SHARE))
        PRICE[_a[0]] = LATE_PRICE.get(_a[0]) or max(1, round(_a[5] / (_rate * (1 + bonus(_at, _skill)))))
EXTRA_XP, EXTRA_PRICE = {}, {}
for _name, _like, _xp_mult, _price_mult in EXTRAS:
    EXTRA_XP[_name] = round(XP[_like] * _xp_mult / 5) * 5
    EXTRA_PRICE[_name] = max(1, round(PRICE[_like] * _price_mult))


def best(skill, level, table):
    top, top_rate = None, 0.0
    for activity in ACTIVITIES[skill]:
        if activity[0] in ISLAND_ONLY:
            continue
        rate = actions_per_hour(skill, activity, level, WORLD_TOP_TIER) * table[activity[0]]
        if table is PRICE:
            rate *= 1 + bonus(level, skill)
        if rate > top_rate:
            top, top_rate = activity, rate
    return top, top_rate


def curve(a, q):
    return lambda level: round(a * level**q / 5) * 5


def skill_hours(skill, to_next):
    hours, reached = 0.0, {1: 0.0}
    for level in range(1, MAX_SKILL):
        hours += to_next(level) / best(skill, level, XP)[1]
        reached[level + 1] = hours
    return reached


def solve_skill_curve():
    """A and Q so the average skill reaches 10 in TARGET_L10 and 99 in TARGET_L99 hours"""
    def average(q):
        tens, nines = [], []
        for skill in CURVE_SKILLS:
            r = skill_hours(skill, lambda level: level**q)
            tens.append(r[10])
            nines.append(r[99])
        return sum(tens) / len(tens), sum(nines) / len(nines)

    low, high = 0.2, 2.0
    for _ in range(60):
        q = (low + high) / 2
        ten, nine = average(q)
        if nine / ten > TARGET_L99 / TARGET_L10:
            high = q
        else:
            low = q
    ten, _ = average(q)
    return TARGET_L10 / ten, q


def player_timeline(skill_curve):
    """(hour, player XP) training the skills one after another to 99, both orders
    averaged; quest XP comes in over the first hour"""
    orders = (("Farming", "Mining", "Woodcutting"), ("Mining", "Woodcutting", "Farming"),
              ("Woodcutting", "Farming", "Mining"))
    lines = []
    for order in orders:
        t, xp, line = 0.0, 0.0, []
        for skill in order:
            for level in range(1, MAX_SKILL):
                activity, rate = best(skill, level, XP)
                dt = skill_curve(level) / rate
                t += dt
                xp += actions_per_hour(skill, activity, level, WORLD_TOP_TIER) * PLAYER_XP[activity[0]] * dt
                line.append((t, xp + QUEST_XP * min(t, 1.0)))
        lines.append(line)
    return lines


def player_hours(lines, to_next):
    results = []
    for line in lines:
        reached, need, level = {1: 0.0}, to_next(1), 1
        for t, xp in line:
            while level < MAX_PLAYER and xp >= need:
                level += 1
                reached[level] = t
                need += to_next(level)
        results.append(reached)
    return {lv: sum(r.get(lv, 999) for r in results) / len(results) for lv in range(1, MAX_PLAYER + 1)}


def solve_player_curve(lines):
    """B and R so player level 10 takes TARGET_P10 hours and 50 TARGET_P50"""
    best_fit = None
    for r10 in range(80, 141):
        r = r10 / 100
        low, high = 1.0, 5000.0
        for _ in range(50):
            b = (low + high) / 2
            hours = player_hours(lines, lambda level: b * level**r)
            if hours[10] > TARGET_P10:
                high = b
            else:
                low = b
        hours = player_hours(lines, lambda level: b * level**r)
        error = abs(hours[50] - TARGET_P50) / TARGET_P50 * 2 + abs(hours[5] - TARGET_P5) / TARGET_P5 * 0.3
        if best_fit is None or error < best_fit[0]:
            best_fit = (error, b, r)
    return best_fit[1], best_fit[2]


def main():
    a, q = solve_skill_curve()
    skill_curve = curve(a, q)
    print(f"Skill curve: XPToNext(level) = {a:.1f} * level^{q:.3f}  (rounded to 5s)")
    print("  level 10 needs", sum(skill_curve(n) for n in range(1, 10)), "XP in all,",
          "99 needs", sum(skill_curve(n) for n in range(1, 99)))
    print(f"  {'skill':12} {'L10':>6} {'L25':>6} {'L50':>6} {'L75':>6} {'L99':>6}   (hours)")
    for skill in ACTIVITIES:
        r = skill_hours(skill, skill_curve)
        print(f"  {skill:12} " + " ".join(f"{r[n]:6.1f}" for n in (10, 25, 50, 75, 99)))

    lines = player_timeline(skill_curve)
    b, r = solve_player_curve(lines)
    player_curve = curve(b, r)
    hours = player_hours(lines, player_curve)
    print(f"\nPlayer curve: XPToNext(level) = {b:.1f} * level^{r:.3f}  (rounded to 5s)")
    print("  50 needs", sum(player_curve(n) for n in range(1, 50)), "XP in all;",
          " ".join(f"L{n} {hours[n]:.1f}h" for n in (5, 10, 25, 50)))

    print("\nResources (XP, player XP, shop price):")
    for skill, activities in ACTIVITIES.items():
        for act in activities:
            name = act[0]
            print(f"  {skill:12} {name:9} L{act[1]:<3} XP {XP[name]:4}  player XP {PLAYER_XP[name]:3}  sells for {PRICE[name]:5}")
    for name, *_ in EXTRAS:
        print(f"  {'(extra)':12} {name:9}      XP {EXTRA_XP[name]:4}  player XP {round(EXTRA_XP[name] * PLAYER_SHARE):3}  sells for {EXTRA_PRICE[name]:5}")

    # Slaying's slivers: as many hours to a spawner as to the node of the same rank
    print("\nMonsters (the world's six): kills an hour with an Iron sword, sliver odds for those hours:")
    for act, hours_to_one, need in zip(ACTIVITIES["Combat"], (1, 1.7, 3.3, 5, 9, 13), (10, 10, 12, 12, 15, 15)):
        rate = actions_per_hour("Combat", act, max(act[1], 5))
        print(f"  {act[0]:12} {rate:5.0f} kills/h, 1 sliver in {round(rate * hours_to_one / need / 5) * 5:4}, {need} make a spawner")

    # Crafting XP: CRAFT_SHARE x the skill XP of the raw materials in it
    raw = {"Planks": XP["Oak"] / 4, "Sticks": XP["Oak"] / 8, "Stone": EXTRA_XP["Stone"],
           "IronIngot": XP["Iron"] + XP["Coal"], "GoldIngot": XP["Gold"] + XP["Coal"],
           "Crystal": XP["Gold"] * 4}
    print("\nCrafting XP (per craft):")
    for recipe, inputs in (("Planks (1 Wood)", {"Planks": 4}), ("Sticks (2 Planks)", {"Sticks": 4}),
                           ("Furnace (8 Stone)", {"Stone": 8}), ("Iron Ingot", {"IronIngot": 1}),
                           ("Gold Ingot", {"GoldIngot": 1})):
        total = sum(raw[k] * n for k, n in inputs.items()) * CRAFT_SHARE
        print(f"  {recipe:18} {round(total / 5) * 5}")
    print("  tool materials (per head piece):", {k: round(v * CRAFT_SHARE) for k, v in raw.items()})
    ingots_per_hour = actions_per_hour("Mining", ACTIVITIES["Mining"][1], 50) / 2
    craft_rate = ingots_per_hour * (XP["Iron"] + XP["Coal"]) * CRAFT_SHARE
    to99 = sum(skill_curve(n) for n in range(1, 99))
    print(f"  smelting everything you mine: {craft_rate:,.0f} Crafting XP an hour, 99 in ~{to99 / craft_rate:.0f} h")

    print("\nGetting rich in the worlds alone (one skill, selling everything):")
    for skill in ACTIVITIES:
        coins, hours = 0.0, 0.0
        for level in range(1, MAX_SKILL):
            dt = skill_curve(level) / best(skill, level, XP)[1]
            hours += dt
            coins += best(skill, level, PRICE)[1] * dt
        top = best(skill, MAX_SKILL, PRICE)[1]
        print(f"  {skill:12} at 99: {coins:13,.0f} coins after {hours:4.0f} h, then {top:10,.0f} an hour;",
              f"a billion after {hours + max(0, 1e9 - coins) / top:4.0f} h")

    print("\nXP and coins an hour at each level (best resource for each):")
    for skill in ACTIVITIES:
        for level in (1, 5, 10, 20, 30, 50, 99):
            xa, xr = best(skill, level, XP)
            ca, cr = best(skill, level, PRICE)
            print(f"  {skill:12} L{level:<3} XP {xr:8,.0f}/h ({xa[0]:7})   coins {cr:9,.0f}/h ({ca[0]})")


if __name__ == "__main__":
    main()
