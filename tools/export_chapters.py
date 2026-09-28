"""Export tools/chapters.py (the same data the design bible is built from) to data/chapters.json for Godot.

Run from the repo root:  python3 tools/export_chapters.py
"""
import json
import re
from pathlib import Path

from chapters import CHAPTERS

ROOT = Path(__file__).resolve().parent.parent

# Placeholder-tile colors per track, taken from the 302 Palette page.
TRACK_COLORS = {
    "tut": ["#e87b9b"],
    "c1": ["#ffe9c4", "#2f7fd0"],
    "c2": ["#4fb8e0", "#d4a03a"],
    "c3": ["#ff9c3a", "#c8e8ff"],
    "c4": ["#f5a05a", "#c8a45a"],
    "c5": ["#f5a05a", "#e8e4f0"],
    "c6": ["#6080b0", "#c8d8f0"],
    "c7": ["#f0c060", "#ff7ad9", "#e07830"],
    "c8": ["#7ab4f5", "#ff6b6b"],
    "c9": ["#8aa89a", "#ddeedd"],
    "c10": ["#d42020", "#f0f0f0"],
    "c11": ["#c4bedd", "#7a7098"],
    "c12": ["#f5a05a", "#9b6dff", "#e87b9b"],
    "archive": ["#d9c28a", "#dfe8e6"],
    "c13": ["#5de8c1", "#5de8c1"],
}
STAR_COLORS = {
    "tut": "#e87b9b", "c1": "#ffd98a", "c2": "#d4a03a", "c3": "#c8e8ff", "c4": "#f5a05a",
    "c5": "#c8a45a", "c6": "#c8d8f0", "c7": "#f0c060", "c8": "#ff6b6b", "c9": "#ddeedd",
    "c10": "#f0f0f0", "c11": "#7a7098", "c12": "#9b6dff", "archive": "#d9c28a", "c13": "#5de8c1",
}
BOARD_COLORS = {
    "tut": "#07090f", "c1": "#0b0a1c", "c2": "#07141a", "c3": "#140c0a", "c4": "#140e08",
    "c5": "#12100a", "c6": "#0a0e16", "c7": "#16110a", "c8": "#0e0c16", "c9": "#0e1210",
    "c10": "#120808", "c11": "#f4f2f8", "c12": "#0c0a14", "archive": "#12110c", "c13": "#07090f",
}
# The one mystery generator each chapter uses when pacing mode is "mystery".
SOURCES = {
    "tut": "Neuron", "c1": "The Void", "c2": "Tide Pool", "c3": "The Sky", "c4": "Campfire",
    "c5": "Workshop", "c6": "Crossroads", "c7": "Toy Chest", "c8": "Phone", "c9": "Front Door",
    "c10": "Border", "c11": "Waiting Room", "c12": "Nightstand", "archive": "Filing Cabinet", "c13": "Terminal",
}
SPECIAL = {
    "tut": {"generator_limit": {"1": 302, "2": 303}, "counter": True, "prefill": 28, "collapse_final": True},
    "c7": {"companion_spawn": {"item": "paw_print", "after_taps": 6}, "requires": ["cat"], "eye_trigger": "cat"},
    "c12": {"companion_spawn": {"item": "brain", "when_made": "mushrooms"}},
}
NO_GENERATOR = {("c7", 2): "after_companion", ("c12", 2): "never"}


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.replace("★", "").lower()).strip("_")


def recipe(text: str) -> list:
    if "+" not in text:
        return []  # formed by a special rule (the tutorial's worm), not a two-item merge
    a, b = [p.strip() for p in text.split("+")]
    return [slug(a), slug(b)]


out = []
for c in CHAPTERS:
    tracks = []
    for i, t in enumerate(c["tracks"]):
        tracks.append({
            "title": t["title"],
            "color": TRACK_COLORS[c["key"]][i],
            "generator": NO_GENERATOR.get((c["key"], i), "always"),
            "items": [{"id": slug(n), "name": n, "desc": d} for n, d in t["items"]],
        })
    fn, fr, fd = c["final"]
    ch = {
        "key": c["key"], "num": c["num"], "title": c["title"], "hidden": bool(c.get("hidden")),
        "board_color": BOARD_COLORS[c["key"]], "star_color": STAR_COLORS[c["key"]],
        "source": SOURCES[c["key"]],
        "tracks": tracks,
        "final": {"id": slug(fn), "name": fn, "desc": fd, "recipe": recipe(fr)},
        "special": SPECIAL.get(c["key"], {}),
    }
    if c.get("extra_final"):
        en, er, ed = c["extra_final"]
        ch["extra"] = {"id": slug(en), "name": en, "desc": ed, "recipe": recipe(er)}
    out.append(ch)

ids = [i["id"] for ch in out for t in ch["tracks"] for i in t["items"]] + [ch["final"]["id"] for ch in out]
assert len(ids) == len(set(ids)), "duplicate item ids"

(ROOT / "data" / "chapters.json").write_text(json.dumps({"chapters": out}, indent=1, ensure_ascii=False))
print(f"wrote {len(out)} chapters, {len(ids)} items")
