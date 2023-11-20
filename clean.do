#!/usr/bin/env python

# Optimize python path:
from util import performance
performance.optimize_path()

# Imports
import sys
import os
import glob

# Special clean that removes b~main files before
# doing the normal clean.
if __name__ == "__main__":
  assert len(sys.argv) == 4
  for hgx in glob.glob("b~*"):
    os.remove(hgx)
  from rules.build_clean import build_clean
  rule = build_clean()
  rule.build(*sys.argv[1:])

# Exit fast:
performance.exit()
