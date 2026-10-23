#!/usr/bin/env python3
"""Exercise scratchpad workflows without moving the user's desktop windows."""

import copy
import fcntl
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "scratchpad", Path(__file__).resolve().parents[1] / "assets/scripts/scratchpad.py"
)
scratchpad = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scratchpad)


class Desktop:
    def __init__(self):
        # Deliberately give each output a workspace with the same index.
        self.workspaces = [
            {"id": 10, "idx": 1, "name": None, "output": "A", "is_focused": True},
            {"id": 20, "idx": 1, "name": "scratch", "output": "B", "is_focused": False},
            {"id": 30, "idx": 1, "name": None, "output": "C", "is_focused": False},
        ]
        self.windows = {
            1: {"id": 1, "workspace_id": 10, "app_id": "browser", "is_focused": False, "is_floating": False},
            2: {"id": 2, "workspace_id": 10, "app_id": None, "is_focused": True, "is_floating": False},
        }
        self.actions = []

    def query(self, name):
        return copy.deepcopy(self.workspaces if name == "Workspaces" else list(self.windows.values()))

    def focus(self, wid):
        for window in self.windows.values():
            window["is_focused"] = window["id"] == wid
        for workspace in self.workspaces:
            workspace["is_focused"] = workspace["id"] == self.windows[wid]["workspace_id"]

    def action(self, name, **arguments):
        self.actions.append((name, arguments))
        if name == "MoveWindowToWorkspace":
            window = self.windows[arguments["window_id"]]
            old_workspace = window["workspace_id"]
            window["workspace_id"] = arguments["reference"]["Id"]
            if window["is_focused"] and old_workspace != window["workspace_id"]:
                window["is_focused"] = False
                other = next((w for w in self.windows.values()
                              if w["workspace_id"] == old_workspace), None)
                if other:
                    self.focus(other["id"])
        elif name == "FocusWorkspace":
            for workspace in self.workspaces:
                workspace["is_focused"] = workspace["id"] == arguments["reference"]["Id"]
            for window in self.windows.values():
                window["is_focused"] = False
        elif name == "FocusWindow":
            self.focus(arguments["id"])
        elif name == "MoveWindowToFloating":
            self.windows[arguments["id"]]["is_floating"] = True


class ScratchpadTests(unittest.TestCase):
    def setUp(self):
        self.desktop = Desktop()
        self.state = {}

    def run_command(self, command):
        scratchpad.manage(self.desktop, self.state, command)

    def test_arbitrary_window_round_trip_restores_focus(self):
        self.run_command("stash")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 20)
        self.assertTrue(self.desktop.windows[1]["is_focused"])
        self.run_command("toggle")
        self.assertFalse(self.desktop.windows[2]["is_floating"])
        self.assertTrue(self.desktop.windows[2]["is_focused"])
        self.run_command("toggle")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 20)
        self.assertTrue(self.desktop.windows[1]["is_focused"])

    def test_round_trip_preserves_both_modes_and_background_layout(self):
        for floating in (False, True):
            with self.subTest(floating=floating):
                self.setUp()
                self.desktop.windows[2]["is_floating"] = floating
                self.desktop.windows[2]["layout"] = {
                    "window_size": [640, 480], "tile_pos_in_workspace_view": [120.0, 90.0]
                }
                self.desktop.windows[1]["layout"] = {
                    "window_size": [900, 1000], "pos_in_scrolling_layout": [1, 1]
                }
                self.run_command("stash")
                background = copy.deepcopy(self.desktop.windows[1])
                original_layout = copy.deepcopy(self.desktop.windows[2]["layout"])
                self.run_command("toggle")
                self.assertEqual(self.desktop.windows[2]["is_floating"], floating)
                self.assertEqual(self.desktop.windows[2]["layout"], original_layout)
                self.run_command("toggle")
                self.assertEqual(self.desktop.windows[1], background)
                self.assertEqual(self.desktop.windows[2]["is_floating"], floating)
                self.assertFalse(any(name in {
                    "MoveWindowToFloating", "MoveWindowToTiling", "CenterWindow",
                    "SetWindowWidth", "SetWindowHeight", "MoveFloatingWindow"
                } for name, _ in self.desktop.actions))

    def test_refocus_visible_window_does_not_reinsert_or_reposition(self):
        self.run_command("stash")
        self.run_command("toggle")
        self.desktop.focus(1)
        self.desktop.actions.clear()
        self.run_command("toggle")
        self.assertEqual(self.desktop.actions, [("FocusWindow", {"id": 2})])
        self.run_command("toggle")
        self.assertTrue(self.desktop.windows[1]["is_focused"])

    def test_cycling_single_window_uses_its_position_after_hiding(self):
        self.run_command("stash")
        self.run_command("toggle")
        self.run_command("next")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 10)
        self.assertTrue(self.desktop.windows[2]["is_focused"])
        self.assertFalse(self.desktop.windows[2]["is_floating"])

    def test_cross_monitor_summon_uses_global_workspace_id(self):
        self.run_command("stash")
        self.desktop.windows[3] = {"id": 3, "workspace_id": 30, "is_focused": False}
        self.desktop.focus(3)
        self.run_command("toggle")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 30)
        self.assertTrue(self.desktop.windows[2]["is_focused"])
        moves = [args for name, args in self.desktop.actions if name == "MoveWindowToWorkspace"]
        self.assertEqual(moves[-1]["reference"], {"Id": 30})
        self.assertTrue(all(args["focus"] is False for args in moves))

    def test_cycle_wraps_multiple_applications(self):
        self.run_command("stash")
        self.run_command("stash")
        self.run_command("toggle")
        self.assertTrue(self.desktop.windows[1]["is_focused"])
        self.run_command("next")
        self.assertTrue(self.desktop.windows[2]["is_focused"])
        self.assertEqual(self.desktop.windows[1]["workspace_id"], 20)
        self.run_command("next")
        self.assertTrue(self.desktop.windows[1]["is_focused"])
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 20)

    def test_unfocused_visible_window_is_focused_then_hidden(self):
        self.run_command("stash")
        self.run_command("toggle")
        self.desktop.focus(1)
        self.run_command("toggle")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 10)
        self.assertTrue(self.desktop.windows[2]["is_focused"])
        self.run_command("toggle")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 20)

    def test_closed_windows_are_pruned_and_stash_recovers_lost_state(self):
        self.run_command("stash")
        self.state = {"order": [999]}
        self.run_command("toggle")
        self.assertEqual(self.state["order"], [2])
        self.assertTrue(self.desktop.windows[2]["is_focused"])

    def test_return_window_moved_elsewhere_does_not_switch_workspaces(self):
        self.run_command("stash")
        self.run_command("toggle")
        self.desktop.windows[1]["workspace_id"] = 30
        self.desktop.actions.clear()
        self.run_command("toggle")
        self.assertFalse(any(name == "FocusWindow" for name, _ in self.desktop.actions))
        self.assertTrue(self.desktop.workspaces[0]["is_focused"])

    def test_release_keeps_window_in_place(self):
        self.run_command("stash")
        self.run_command("toggle")
        self.desktop.actions.clear()
        self.run_command("release")
        self.assertEqual(self.state["order"], [])
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 10)
        self.assertEqual(self.desktop.actions, [])

    def test_empty_pool_and_missing_focus_do_nothing(self):
        self.run_command("toggle")
        self.desktop.windows[2]["is_focused"] = False
        self.run_command("stash")
        self.assertEqual(self.desktop.actions, [])

    def test_toggle_from_stash_recovers_to_ordinary_workspace(self):
        self.run_command("stash")
        self.desktop.focus(2)
        self.run_command("toggle")
        self.assertEqual(self.desktop.windows[2]["workspace_id"], 10)
        self.assertTrue(self.desktop.windows[2]["is_focused"])
        self.assertIn(("FocusWorkspace", {"reference": {"Id": 10}}), self.desktop.actions)

    def test_recovery_falls_back_when_last_workspace_disappeared(self):
        self.run_command("stash")
        self.state["last_workspace"] = 999
        self.desktop.focus(2)
        self.run_command("toggle")
        self.assertNotEqual(self.desktop.windows[2]["workspace_id"], 20)
        self.assertTrue(self.desktop.windows[2]["is_focused"])

    def test_stashing_last_window_keeps_focus_outside_stash(self):
        original_action = self.desktop.action
        def remove_emptied_workspace(name, **arguments):
            old_workspace = self.desktop.windows.get(arguments.get("window_id"), {}).get("workspace_id")
            original_action(name, **arguments)
            if name == "MoveWindowToWorkspace" and not any(
                w["workspace_id"] == old_workspace for w in self.desktop.windows.values()
            ):
                self.desktop.workspaces = [w for w in self.desktop.workspaces if w["id"] != old_workspace]
                self.desktop.focus(arguments["window_id"])
        self.desktop.action = remove_emptied_workspace
        self.run_command("stash")
        self.run_command("stash")
        focused = next(w for w in self.desktop.workspaces if w["is_focused"])
        self.assertEqual(focused["id"], 30)
        self.run_command("toggle")
        self.assertEqual(self.desktop.windows[1]["workspace_id"], 30)
        self.assertTrue(self.desktop.windows[1]["is_focused"])

    def test_membership_survives_separate_command_invocations(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = {"NIRI_SOCKET": "/test/niri.sock", "XDG_RUNTIME_DIR": directory}
            with patch.dict(scratchpad.os.environ, environment), patch.object(
                scratchpad, "Niri", return_value=self.desktop
            ):
                for command in ("stash", "toggle", "toggle", "toggle"):
                    with patch.object(scratchpad.sys, "argv", ["scratchpad.py", command]):
                        scratchpad.main()
                saved = json.loads(next(Path(directory).glob("*.json")).read_text())
                self.assertEqual(saved["order"], [2])
                self.assertTrue(self.desktop.windows[2]["is_focused"])

    def test_overlapping_shortcut_is_dropped_without_moving_windows(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = {"NIRI_SOCKET": "/test/niri.sock", "XDG_RUNTIME_DIR": directory}
            with patch.dict(scratchpad.os.environ, environment), patch.object(
                scratchpad, "Niri", return_value=self.desktop
            ), patch.object(scratchpad.sys, "argv", ["scratchpad.py", "stash"]):
                scratchpad.main()
                self.desktop.actions.clear()
                with next(Path(directory).glob("*.json")).open("r+") as stream:
                    fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    scratchpad.main()
                self.assertEqual(self.desktop.actions, [])


if __name__ == "__main__":
    unittest.main()
