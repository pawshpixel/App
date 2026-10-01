# 302

A merge game that begins again. Built in Godot 4.4+.

Design bible: https://claude.ai/artifact/8KEvN6c9tbPKcQBqCsdkdB

## Open it

1. Install Godot 4.4 or newer (the standard version, not .NET).
2. Project Manager → **Import** → select `project.godot` in this folder → **Import & Edit**.
3. Press **F5** (or the ▶ button) to play.

## What's in this slice

Everything plays with placeholder squares, so you can draw into a game that already works.

- All 14 chapters plus the tutorial, straight from the bible's item data
- Tap a generator button to get an item, drag two identical items together to merge
- Tap an item to see its name and merge path (`?` for tiers you haven't found)
- The companion sits in the corner asleep, and its eye opens the moment you make the Cat
- It covers its eye in the war, goes dark after the crater, and places the Paw Print and the Brain
- End of Loop 1: "it was you..." → CONTINUE / TERMINATE
- Loop 2: descriptions switch on, the eye is open from the start, the opening question, and Neuron 303

### The machine and the people against it

- **The chatbot that stops answering** (The Feed): tap the AI Chatbot and it answers honestly. Once Breaking News is made, it only says "i can't answer political questions." In Loop 2 the old answer shows struck through above it. Its lines live in `VOICES` in `tools/chapters.py`.
- **The Data Center keeps taking**: once it's built (The City), it sits fixed in the bottom-right corner of every board for the rest of the loop. Every few taps it fills a nearby cell with Static, and the top panel counts the water it has used (about 8.4 billion gallons by the end of Loop 1).
- **The Group Chat** (The Feed): a hope track that drops much less often and is optional. Making the Town Hall Chair cancels every Static on the board and slows the machine by half for the rest of the loop.
- **The Race** (new chapter, after War + Freedom): the Accord, the Land and the Bill. A RIVAL bar climbs with every tap and never reaches 100%. The chapter can't end until the Dry Well exists.
- **Redactions** (Loop 2+): the items in `REDACTED` (`tools/chapters.py`) come back blacked out. Tap the companion to restore one. You earn a restore every few merges, and three more for building the Town Hall Chair.
- **This part is real** (off): an optional last screen after TERMINATE with real-world links. It's switched off, so the endings are unchanged. Set `"enabled": true` in `data/real_world.json` to try it.

**DEV buttons** (bottom of the screen): `skip ▶` finishes the chapter, `auto-merge` does one merge for you,
`loop +1` jumps to the next loop, `reset` wipes progress. Turn them off with `DEV_MODE` in `scripts/loop_state.gd`.

## Pacing (how long chapters take)

All the numbers live in `data/pacing.json`. Change one, save, press F5.

| Knob | What it does |
| --- | --- |
| `mode` | `mystery`: one themed generator per chapter (The Void, Tide Pool…) that drops a random item. `per_track`: one button per chain (the old style). The **pacing** dev button flips between them while you play. |
| `start_cells` | How many cells are lit when a chapter starts. The rest is static until you discover things. |
| `unlock_per_new_item` | Cells that light up each time you make an item for the first time in that chapter. |
| `static_chance` | How often the generator drops Static. Two Static cancel out. |
| `upgrade_chance` | How often the generator drops something one step up a chain. |
| `max_chain_depth` | Chains longer than this also drop items partway up, so an 11-item chain doesn't need 1,024 taps. |
| `recycle` | Drag an item onto the generator to throw it away. |
| `hope_weight` | How often hope tracks (The Group Chat) drop, compared with normal tracks. 1.0 = just as often. |
| `machine_every` | The Data Center takes a cell every this many taps (doubled once the Town Hall Chair exists). |
| `machine_gallons_per_tap` | Water the Data Center adds to the counter on every tap. |
| `rival_per_tap` | How fast the RIVAL bar climbs in The Race. |
| `restore_every_merges` | Loop 2+: merges needed to earn one redaction restore. |

Put any of these under `"chapters"` → `"c10"` (for example) to change just one chapter.

**The tutorial** stays short on purpose: one Neuron button that gives exactly 16 (17 in Loop 2, leaving one unpaired), and a counter that climbs to 302 as they merge into The Worm ★.

There are no chapter screens. The title at the top of the panel changes and the board drifts into the next world's colors, so the whole game plays as one continuous stream.

## Where things live

| Path | What |
| --- | --- |
| `data/chapters.json` | Every chapter, chain, item name and description, plus the chatbot's lines and the redaction list |
| `data/real_world.json` | The last screen's text and links |
| `scripts/main.gd` | Game flow: chapters, generators, the eye, end of loop |
| `scripts/board.gd` | The 7 × 8 grid, dragging and merging |
| `scripts/tile.gd` | How one item looks (swap in your PNGs here) |
| `scripts/companion.gd` | Placeholder companion drawn in code |
| `scripts/info_panel.gd` | Name, description, merge path |
| `scripts/loop_state.gd` | Loop number, eye state, save file |
| `assets/fonts/` | JetBrains Mono (SIL Open Font License) |

## Changing items

Item data is written once in `tools/chapters.py` (the same data that builds the bible), then exported:

```
python3 tools/export_chapters.py
```

## Tests

```
godot --headless --path . res://tests/playthrough.tscn
```

Plays both loops start to finish and checks the eye, the war, Neuron 303, the chatbot, the machine, the rival bar and redactions. It resets your saved progress.
