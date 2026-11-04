"""Talks to Roblox Studio's own MCP server (StudioMCP.exe) over stdio, for when this session
hasn't loaded it as a tool.
  python studio_mcp.py list
  python studio_mcp.py studios
  python studio_mcp.py call <tool> '<json args>'
  python studio_mcp.py luau <file.luau> [studio_id] [datamodel_type]   runs the file
Images in a result are saved next to this script and their path is printed.
With no studio_id, call and luau use the only local place that's open. A published place
(its name carries a placeId) is always refused. A Studio opened before "Studio as MCP server"
was turned on never connects: open the place again.
"""
import base64
import json
import os
import subprocess
import sys
import threading
import queue
import time

BAT = os.path.join(os.environ["LOCALAPPDATA"], "Roblox", "mcp.bat")


class Server:
    def __init__(self):
        self.p = subprocess.Popen(
            ["cmd.exe", "/c", BAT],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            bufsize=1,
        )
        self.out = queue.Queue()
        threading.Thread(target=self._read, daemon=True).start()
        self.id = 0

    def _read(self):
        for line in self.p.stdout:
            line = line.strip()
            if line.startswith("{"):
                self.out.put(json.loads(line))

    def send(self, method, params=None, notify=False):
        msg = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        if not notify:
            self.id += 1
            msg["id"] = self.id
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()
        return None if notify else self.id

    def wait(self, wanted, timeout):
        end = time.time() + timeout
        while time.time() < end:
            try:
                msg = self.out.get(timeout=max(0.1, end - time.time()))
            except queue.Empty:
                break
            if msg.get("id") == wanted:
                return msg
        raise TimeoutError(f"no answer in {timeout}s")

    def call(self, method, params=None, timeout=60):
        return self.wait(self.send(method, params), timeout)

    def close(self):
        try:
            self.p.stdin.close()
            self.p.terminate()
        except OSError:
            pass


def studio_list(s):
    res = s.call("tools/call", {"name": "list_roblox_studios", "arguments": {}}, 30)
    text = "".join(c.get("text", "") for c in res.get("result", {}).get("content", []))
    try:
        return sorted(json.loads(text).get("studios", []), key=lambda x: x["id"])
    except ValueError:
        return []


def wait_for_studios(s, timeout=25, settle=6):
    # A fresh server starts empty: each Studio retries about every 5 s and has no name at first
    end = time.time() + timeout
    studios, since = [], time.time()
    while time.time() < end:
        now = studio_list(s)
        if now != studios:
            studios, since = now, time.time()
        if studios and all(x.get("name") for x in studios) and time.time() - since >= settle:
            break
        time.sleep(1)
    return studios


def is_published(studio):
    return "placeId:" in (studio.get("name") or "")


def pick_target(s, studio_id):
    if studio_id:
        studio = None
        for _ in range(25):
            studio = next((x for x in studio_list(s) if x["id"] == studio_id and x.get("name")), None)
            if studio:
                break
            time.sleep(1)
        if not studio:
            sys.exit(f"Studio {studio_id} isn't connected. Run: studio_mcp.py studios")
    else:
        studios = wait_for_studios(s)
        local = [x for x in studios if not is_published(x)]
        if len(local) != 1:
            sys.exit(f"Need exactly one local place or a studio_id. Connected: {json.dumps(studios)}")
        studio = local[0]
    if is_published(studio):
        sys.exit(f"Refused: {studio['name']} is a published place")
    return studio["id"]


def main():
    s = Server()
    try:
        s.call(
            "initialize",
            {
                "protocolVersion": "2025-03-26",
                "capabilities": {},
                "clientInfo": {"name": "skycore-bridge", "version": "1"},
            },
            30,
        )
        s.send("notifications/initialized", notify=True)
        mode = sys.argv[1]
        if mode == "studios":
            print(json.dumps({"studios": wait_for_studios(s)}))
            return
        if mode == "list":
            tools = s.call("tools/list")["result"]["tools"]
            for t in tools:
                props = list((t.get("inputSchema") or {}).get("properties", {}).keys())
                print(f"{t['name']}{props}: {(t.get('description') or '')[:170]}")
        else:
            if mode == "luau":
                tool = "execute_luau"
                args = {"code": open(sys.argv[2], encoding="utf-8").read()}
                if len(sys.argv) > 3 and sys.argv[3]:
                    args["studio_id"] = sys.argv[3]
                args["datamodel_type"] = sys.argv[4] if len(sys.argv) > 4 else "Edit"
            else:
                tool = sys.argv[2]
                args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
            if tool != "list_roblox_studios":
                args["studio_id"] = pick_target(s, args.get("studio_id"))
            res = s.call("tools/call", {"name": tool, "arguments": args}, 180)
            if "error" in res:
                print("ERROR", res["error"])
            else:
                for c in res["result"].get("content", []):
                    if c.get("type") == "image":
                        name = os.path.join(os.path.dirname(os.path.abspath(__file__)), f"capture_{int(time.time())}.png")
                        with open(name, "wb") as f:
                            f.write(base64.b64decode(c["data"]))
                        print("image:", name)
                    else:
                        print(c.get("text", c.get("type")))
    finally:
        s.close()


main()
