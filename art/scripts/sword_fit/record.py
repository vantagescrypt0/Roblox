"""Records the real game: for each sword and armour, every rendered frame of a rest, a real swing and a sprint, on the
player's own character. Writes recorded.json for real_check.py to measure."""
import json
import os
import sys
import time

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
HERE = os.path.dirname(os.path.abspath(__file__))
source = open(os.path.join(REPO, "tools", "studio_mcp.py"), encoding="utf-8").read()
source = source[: source.rindex("main()")]
bridge = {"__name__": "bridge", "__file__": os.path.join(REPO, "tools", "studio_mcp.py")}
exec(compile(source, "studio_mcp", "exec"), bridge)
Server, pick_target = bridge["Server"], bridge["pick_target"]

RECORD = r"""
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local character = game.Players.LocalPlayer.Character
local chest = character.UpperTorso
local old = workspace:FindFirstChild("Recording")
if old then old:Destroy() end
local store = Instance.new("StringValue")
store.Name = "Recording"
store.Parent = workspace
local frames = {}
local began = os.clock()
local names = { "RightUpperArm", "RightLowerArm", "RightHand", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand" }
local function comps(c)
	return { c:GetComponents() }
end
local connection
connection = RunService.RenderStepped:Connect(function()
	local held = character:FindFirstChild("Held")
	if not held then return end
	local t = os.clock() - began
	local frame = { t = t, item = held:GetAttribute("Item"), held = comps(chest.CFrame:ToObjectSpace(held.CFrame)), grip = comps(held:GetAttribute("Grip")) }
	for _, name in names do
		frame[name] = comps(chest.CFrame:ToObjectSpace(character[name].CFrame))
	end
	local shield = character:FindFirstChild("Shield")
	if shield then frame.Shield = comps(chest.CFrame:ToObjectSpace(shield.CFrame)) end
	table.insert(frames, frame)
	if t > @SECONDS@ then
		connection:Disconnect()
		store.Value = HttpService:JSONEncode(frames)
	end
end)
return "recording"
"""

READ = r"""
local store = workspace:FindFirstChild("Recording")
if not store or store.Value == "" then return "0#" end
local size = 90000
local pages = math.ceil(#store.Value / size)
return `{pages}#` .. store.Value:sub((@PAGE@ - 1) * size + 1, @PAGE@ * size)
"""

SWING = r"""
local player = game.Players:GetPlayers()[1]
local held = player.Character:FindFirstChild("Held")
if not held then return "no held" end
held:SetAttribute("SwungAt", workspace:GetServerTimeNow())
return "swung"
"""

SPRINT = r"""
local player = game.Players:GetPlayers()[1]
player:SetAttribute("Sprinting", @ON@)
return "sprint"
"""


def call(s, target, tool, args):
    args = dict(args)
    args["studio_id"] = target
    return s.call("tools/call", {"name": tool, "arguments": args}, 120)


def text(res):
    return "".join(c.get("text", "") for c in res.get("result", {}).get("content", [])) or str(res)[:300]


def run(s, target, code, where):
    return text(call(s, target, "execute_luau", {"code": code, "datamodel_type": where}))


def read_frames(s, target):
    page, pages, body = 1, 1, ""
    while page <= pages:
        head, _, part = run(s, target, READ.replace("@PAGE@", str(page)), "Client").partition("#")
        pages = int(head) if head.isdigit() else 0
        body += part
        page += 1
    return json.loads(body) if body.startswith("[") else []


s = Server()
s.call("initialize", {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "skycore-bridge", "version": "1"}}, 30)
s.send("notifications/initialized", notify=True)
target = pick_target(s, None)
SLOTS = {"StarsteelSword": 5, "RubySword": 6, "CrystalSword": 7, "SapphireSword": 8, "AmethystSword": 9}
SETS = {"Bare": [], "Mining": ["MiningHelmet7", "MiningChestplate7"], "Woodcutting": ["WoodcuttingHelmet7", "WoodcuttingChestplate7"], "Farming": ["FarmingHelmet7", "FarmingChestplate7"]}
out = []
worn = set()
for set_name, wear in SETS.items():
    want = set(wear)
    fires = [f'game.ReplicatedStorage.Remotes.Equip:FireServer("{item}")' for item in sorted(worn - want) + sorted(want - worn)]
    if fires:
        run(s, target, "\n".join(fires) + '\nreturn "worn"', "Client")
    worn = want
    time.sleep(1.5)
    for sword, slot in SLOTS.items():
        run(s, target, f"game.ReplicatedStorage.Remotes.SelectSlot:FireServer({slot})\nreturn 1", "Client")
        time.sleep(1.5)
        print(set_name, sword, run(s, target, RECORD.replace("@SECONDS@", "1.2"), "Client"), run(s, target, SWING, "Server"), flush=True)
        time.sleep(2.5)
        frames = read_frames(s, target)
        print("  swing frames", len(frames), flush=True)
        out.append(dict(set=set_name, sword=sword, kind="swing", frames=frames))
        # Sprinting, with a swing while running
        run(s, target, SPRINT.replace("@ON@", "true"), "Server")
        time.sleep(1.0)
        run(s, target, RECORD.replace("@SECONDS@", "1.0"), "Client")
        run(s, target, SWING, "Server")
        time.sleep(2.3)
        frames = read_frames(s, target)
        print("  sprint frames", len(frames), flush=True)
        out.append(dict(set=set_name, sword=sword, kind="sprint", frames=frames))
        run(s, target, SPRINT.replace("@ON@", "false"), "Server")
        time.sleep(0.7)
        with open(os.path.join(HERE, "recorded.json"), "w") as f:
            json.dump(out, f)
s.close()
print("DONE", flush=True)
