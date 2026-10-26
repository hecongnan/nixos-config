#!/usr/bin/env python3
"""Compatibility entry point: run manual and automatic scratchpad regressions."""
from pathlib import Path
import unittest

if __name__ == "__main__":
    suite = unittest.defaultTestLoader.discover(str(Path(__file__).resolve().parent), pattern="test_*.py")
    result = unittest.TextTestRunner(verbosity=1).run(suite)
    raise SystemExit(not result.wasSuccessful())
