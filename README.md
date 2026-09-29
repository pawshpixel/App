# 302

A merge game that begins again. Built in Godot 4.4+.

Design bible: https://claude.ai/artifact/8KEvN6c9tbPKcQBqCsdkdB

## Open it

1. Install Godot 4.4 or newer (the standard version, not .NET).
2. Project Manager → **Import** → select `project.godot` in this folder → **Import & Edit**.
3. Press **F5** (or the ▶ button) to play.

## What's in this slice

Everything plays with placeholder squares, so you can draw into a game that already works.

- All 13 chapters plus the tutorial, straight from the bible's item data
- Tap a generator button to get an item, drag two identical items together to merge
- Tap an item to see its name and merge path (`?` for tiers you haven't found)
- The companion sits in the corner asleep, and its eye opens the moment you make the Cat
- It covers its eye in the war, goes dark after the crater, and places the Paw Print and the Brain
- End of Loop 1: "it was you..." → CONTINUE / TERMINATE
- Loop 2: descriptions switch on, the eye is open from the start, the opening question, and Neuron 303

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

Put any of these under `"chapters"` → `"c10"` (for example) to change just one chapter.

**The tutorial** stays short on purpose: one Neuron button that gives exactly 16 (17 in Loop 2, leaving one unpaired), and a counter that climbs to 302 as they merge into The Worm ★.

There are no chapter screens. The title at the top of the panel changes and the board drifts into the next world's colors, so the whole game plays as one continuous stream.

## Where things live

| Path | What |
| --- | --- |
| `data/chapters.json` | Every chapter, chain, item name and description |
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

Plays both loops start to finish and checks the eye, the war and Neuron 303. It resets your saved progress.
