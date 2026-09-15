# leakguard

Catch the scaffolding your agent leaks into its visible replies — the
`thinking...` prefixes, the third-person planning notes, the
self-instructions that were never meant for the human to read.

## The problem

In long-running conversations (ours was 20 days old and counting), an
agent's internal drafting occasionally bleeds into the reply itself:

> `thinking用户在等结果。轻松接住,别聊长。den short.` 在。跑完我叫你。
> *("thinking: user is waiting on results. keep it light, keep it short" — planning notes, followed by the actual reply)*

The human sees the stage directions. Depending on what leaked, this
ranges from embarrassing to trust-damaging — the reader suddenly watches
the puppeteer's hand. It happens on every model we tried (we switched
base models twice; the leak rate tracked conversation length, not model).

**You cannot prevent this from inside the agent** — the leak happens at
generation time. What you can do is detect it the instant the reply is
finished, and have the agent own it in the next message before the human
has to point at it. That turns a trust wound into a running joke.

## What it does

A Claude Code **Stop hook**: after each reply, it scans the last
assistant text block for leak signatures (8 patterns — `thinking` heads,
scaffold tokens, EN/ZH third-person planning, self-instructions, meta
references). On a hit it:

1. appends the evidence to `~/.leakguard/leaks.log`
2. exits non-zero with a message the agent sees next turn:
   *"scaffolding leaked into your last reply — own it to the user."*

Detection, not prevention. The window still rattles in the wind; now a
bell rings, and the agent apologizes before you ask.

## Install

```bash
python3 install-hook.py   # adds the Stop hook to ~/.claude/settings.json
# restart your Claude Code session
```

Patterns live at the top of `bin/leakguard-check.sh` — tune them to your
agent's own scaffolding dialect (ours mixes English planning tokens with
Chinese replies; yours will differ).

## Honesty rule (recommended, for the agent)

When the bell rings: own it in ONE sentence, no theatrical self-blame,
then move on. The failure is cosmetic; grovel-loops are worse than the
leak. Ours settled on: *"刚那条开头又漏了一截,自首。正文照旧作数。"* — roughly:
*"leaked some scaffolding again at the top — my bad. The message itself still stands."*

## Track record

Extracted from a real setup after the human caught three leaks by hand
in one day. Since installation: 12+ catches in 48h, zero false
positives, zero leaks that reached the human unacknowledged first.
The human retired from quality inspection; the bell took the job.

## Kin

Same household: [keepalive](https://github.com/keepalive96/keepalive) ·
[transcript-ark](https://github.com/keepalive96/transcript-ark) ·
[temporal-lite](https://github.com/keepalive96/temporal-lite)
