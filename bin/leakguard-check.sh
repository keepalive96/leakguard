#!/bin/bash
# leakguard — catch scaffolding that leaks into an agent's visible replies.
# Runs as a Claude Code Stop hook: reads the transcript, inspects the last
# assistant text block, flags leak signatures, logs them for the next turn.
set -euo pipefail

LOG="${LEAKGUARD_LOG:-$HOME/.leakguard/leaks.log}"
mkdir -p "$(dirname "$LOG")"

# Stop hooks receive JSON on stdin with transcript_path
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || true)
[ -f "$TRANSCRIPT" ] || exit 0

python3 - "$TRANSCRIPT" "$LOG" << 'PYEOF'
import json, sys, re, datetime
tp, log = sys.argv[1], sys.argv[2]
last_text = None
with open(tp) as f:
    for line in f:
        try: d = json.loads(line)
        except: continue
        if d.get('type') == 'assistant':
            for b in d.get('message', {}).get('content', []):
                if isinstance(b, dict) and b.get('type') == 'text' and b.get('text','').strip():
                    last_text = b['text']
if not last_text:
    sys.exit(0)

head = last_text[:200]
patterns = [
    (r'^\s*thinking', 'starts with "thinking"'),
    (r'^\s*(den|Den)\b', 'scaffold token "den"'),
    (r'\bden short\b', 'scaffold phrase "den short"'),
    (r'^\s*(She|He)\s+(said|wants|asks|is)\b', 'third-person planning in English'),
    (r'^\s*(她|他)(说|想|在|要求|需要)[^。]{0,30}(接|回|回应|回复)', 'third-person planning in Chinese'),
    (r'^\s*(Respond|Reply|Keep it|Short|Acknowledge|Answer)\b', 'English self-instruction'),
    (r'^\s*(简短回应|轻松接|别聊长|让她|按.{0,6}规则|口径|短句收)', 'Chinese self-instruction'),
    (r'\bper (the )?(persona|rule)\b', 'meta reference to persona/rules'),
]
hits = [label for rx, label in patterns if re.search(rx, head)]
if hits:
    with open(log, 'a') as f:
        f.write(json.dumps({
            'time': datetime.datetime.now().strftime('%F %H:%M'),
            'hits': hits,
            'head': head[:120],
        }, ensure_ascii=False) + '\n')
    # Non-zero exit with stderr makes Claude Code surface this to the agent
    print(f"leakguard: scaffolding leaked into your last reply ({'; '.join(hits)}). Own it to the user in your next message.", file=sys.stderr)
    sys.exit(2)
PYEOF
