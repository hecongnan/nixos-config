#!/usr/bin/env python3
"""Manage arbitrary scratchpad windows through the running Niri's IPC socket."""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import socket
import sys


class Niri:
    def __init__(self, path):
        self.path = path

    def request(self, request):
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(5)
            connection.connect(self.path)
            connection.sendall(json.dumps(request).encode() + b"\n")
            with connection.makefile("r") as stream:
                reply = json.loads(stream.readline())
        if "Err" in reply:
            raise RuntimeError(reply["Err"])
        return reply["Ok"]

    def query(self, name):
        return self.request(name)[name]

    def action(self, name, **arguments):
        self.request({"Action": {name: arguments}})


def manage(niri, state, command, workspace_name="scratch"):
    workspaces = niri.query("Workspaces")
    stash = next((w for w in workspaces if w["name"] == workspace_name), None)
    current = next((w for w in workspaces if w["is_focused"]), None)
    if stash is None:
        raise RuntimeError(f"缺少工作区 {workspace_name!r}，请先应用 scratchpad 配置")
    if current is None:
        return
    def ordinary_workspace(available):
        ordinary = [w for w in available if w["id"] != stash["id"]]
        return next((w for w in ordinary if w["id"] == state.get("last_workspace")),
                    next((w for w in ordinary if w.get("output") == current.get("output")),
                         next(iter(ordinary), None)))

    recovering = current["id"] == stash["id"]
    if recovering:
        if command not in ("toggle", "next"):
            return
        destination = ordinary_workspace(workspaces)
        if destination is None:
            raise RuntimeError("没有可用的普通工作区")
        niri.action("FocusWorkspace", reference={"Id": destination["id"]})
        current = destination
    state["last_workspace"] = current["id"]

    windows = {w["id"]: w for w in niri.query("Windows")}
    focused = next((w for w in windows.values() if w["is_focused"]), None)
    # Recover windows from the workspace if runtime state was lost, and discard
    # closed windows. Window IDs and state are scoped to this compositor session.
    order = [wid for wid in state.get("order", []) if wid in windows]
    order.extend(wid for wid, w in windows.items()
                 if w["workspace_id"] == stash["id"] and wid not in order)
    state["order"] = order
    modes = state.setdefault("restore_modes", {})
    for key in list(modes):
        if key not in {str(wid) for wid in windows}:
            del modes[key]

    def move(wid, workspace_id):
        # IDs are global across outputs; indices are local to each monitor.
        niri.action("MoveWindowToWorkspace", window_id=wid,
                    reference={"Id": workspace_id}, focus=False)

    def hide(window):
        nonlocal current
        move(window["id"], stash["id"])
        # Restore the pre-summon mode only after leaving the visible workspace,
        # so restoring tiling cannot reflow its other windows.
        key = str(window["id"])
        if key in modes:
            original_floating = modes[key]
            if original_floating != window.get("is_floating", False):
                niri.action("MoveWindowToFloating" if original_floating else "MoveWindowToTiling",
                            id=window["id"])
            del modes[key]
        # Niri can remove an emptied unnamed workspace and focus scratch.
        # Keep the user on an ordinary workspace, including before cycling.
        available = niri.query("Workspaces")
        active = next((w for w in available if w["is_focused"]), None)
        if active and active["id"] == stash["id"]:
            active = ordinary_workspace(available)
            if active:
                niri.action("FocusWorkspace", reference={"Id": active["id"]})
        if active and active["id"] != stash["id"]:
            current = active
            state["last_workspace"] = current["id"]
        previous = windows.get(state.get("return_window"))
        if (window["is_focused"] and previous is not None
                and previous["id"] != window["id"]
                and previous["workspace_id"] == current["id"]):
            # Recheck after moving: never follow a closed/moved return window
            # onto another workspace just to restore keyboard focus.
            live = {w["id"]: w for w in niri.query("Windows")}
            previous = live.get(previous["id"])
            if previous and previous["workspace_id"] == current["id"]:
                niri.action("FocusWindow", id=previous["id"])
        state.pop("return_window", None)

    if command == "stash":
        if focused is not None:
            hide(focused)
            if focused["id"] in order:
                order.remove(focused["id"])
            order.append(focused["id"])
        return

    if not order:
        return
    if command == "release":
        if focused and focused["id"] in order:
            order.remove(focused["id"])
            modes.pop(str(focused["id"]), None)
            state.pop("return_window", None)
        return

    # Hide the focused scratchpad before toggling off or cycling. An unfocused
    # scratchpad is brought into focus, rather than unexpectedly disappearing.
    if focused and focused["id"] in order and not recovering:
        order.remove(focused["id"])
        order.append(focused["id"])
        hide(focused)
        if command == "toggle":
            return
        # The next window follows last-stashed-first order, then wraps around.
        order.insert(0, order.pop())
    elif command == "next":
        order.insert(0, order.pop())

    target = order[-1]
    live = niri.query("Windows")
    target_window = next((w for w in live if w["id"] == target), None)
    if target_window is None:
        return
    # Floating is temporary: remember the mode before the first summon, and
    # convert while still hidden so the destination's tiling stays untouched.
    modes.setdefault(str(target), target_window.get("is_floating", False))
    if not target_window.get("is_floating", False):
        niri.action("MoveWindowToFloating", id=target)
    # Refocusing a visible scratchpad must not reinsert its column or change
    # its floating position. Preserve the original return focus as well.
    if target_window["workspace_id"] == current["id"]:
        niri.action("FocusWindow", id=target)
        return
    # The fresh query above also captures the actual return focus after cycling.
    previous = next((w for w in live if w["is_focused"]), None)
    if previous and previous["id"] != target:
        state["return_window"] = previous["id"]
    move(target, current["id"])
    niri.action("FocusWindow", id=target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("stash", "toggle", "next", "release"))
    args = parser.parse_args()
    path = os.environ.get("NIRI_SOCKET")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not path or not runtime:
        parser.error("需要 Niri 会话的 NIRI_SOCKET 和 XDG_RUNTIME_DIR")
    key = hashlib.sha256(path.encode()).hexdigest()[:16]
    state_path = Path(runtime) / f"niri-scratchpad-{key}.json"
    descriptor = os.open(state_path, os.O_CREAT | os.O_RDWR, 0o600)
    with os.fdopen(descriptor, "r+", encoding="utf-8") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        stream.seek(0)
        try:
            state = json.load(stream)
        except json.JSONDecodeError:
            state = {}
        try:
            manage(Niri(path), state, args.command)
        finally:
            # Keep membership after a partial IPC failure so another invocation
            # can recover; hidden windows also remain accessible in Overview.
            stream.seek(0)
            json.dump(state, stream)
            stream.truncate()


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError) as error:
        print(f"niri-scratchpad: {error}", file=sys.stderr)
        sys.exit(1)
