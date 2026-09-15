#!/usr/bin/env python3
"""Install the leakguard Stop hook into ~/.claude/settings.json (idempotent).
Run from the repo root: python3 install-hook.py"""
import json, os, sys
repo = os.path.dirname(os.path.abspath(__file__))
cmd = f"bash {repo}/bin/leakguard-check.sh"
p = os.path.expanduser('~/.claude/settings.json')
d = json.load(open(p)) if os.path.exists(p) else {}
stop = d.setdefault('hooks', {}).setdefault('Stop', [])
if any('leakguard' in json.dumps(e) for e in stop):
    print('already installed, skipping')
    sys.exit(0)
stop.append({"matcher": "", "hooks": [{"type": "command", "command": cmd, "timeout": 15}]})
json.dump(d, open(p, 'w'), ensure_ascii=False, indent=2)
print(f'installed: {cmd}\nrestart your Claude Code session to activate.')
