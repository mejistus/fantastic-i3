#!/usr/bin/env python
import json
from subprocess import check_output

workspaces = json.loads(check_output(["i3-msg", "-t", "get_workspaces"]))
workspace_nums = [ws["num"] for ws in workspaces]
f = next(ws["num"] for ws in workspaces if ws["focused"])
print(f)
