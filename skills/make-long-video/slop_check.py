#!/usr/bin/env python3
"""Pre-publish 'inauthentic / AI slop' checks for videos/<slug>/ (stdlib only). Run from the project.
  slop_check.py <slug>      prints PASS/WARN/FAIL lines; exit 1 if any FAIL
Checks what YouTube's policy names: templated/repetitive structure vs your other videos, claims without
sources, thin commentary, misleading metadata, missing AI disclosure note. It cannot judge originality: a human does.
"""
import json, re, sys
from pathlib import Path

def root():
    cwd = Path.cwd()
    return next((d / "videos" for d in [cwd, *cwd.parents] if (d / "videos").is_dir()), cwd / "videos")

def grams(t, n=5):
    w = re.findall(r"\w+", t.lower()); return {" ".join(w[i:i + n]) for i in range(len(w) - n + 1)}

def main(slug):
    R, V = root(), root() / slug
    plan, out = json.loads((V / "plan.json").read_text()), []
    add = lambda lvl, msg: out.append((lvl, msg))
    seq = [s["template"] for s in plan["scenes"]]
    narr = (V / "narration.md").read_text() if (V / "narration.md").exists() else " ".join(s["narration"] for s in plan["scenes"])
    # 1 template / repetition vs earlier videos
    others = [p.parent for p in R.glob("*/plan.json") if p.parent.name != slug]
    for o in others:
        oseq = [s["template"] for s in json.loads((o / "plan.json").read_text())["scenes"]]
        same = sum(a == b for a, b in zip(seq, oseq)) / max(len(seq), len(oseq))
        og = grams((o / "narration.md").read_text()) if (o / "narration.md").exists() else set()
        ov = len(grams(narr) & og) / max(1, len(grams(narr)))
        if same > 0.6 or ov > 0.1: add("FAIL", f"too similar to {o.name}: scene-template order {same:.0%}, narration 5-gram overlap {ov:.0%}")
        elif same > 0.4: add("WARN", f"scene-template order {same:.0%} same as {o.name}: vary structure")
    if not others: add("PASS", "no earlier videos to compare for templated structure")
    if len(set(seq)) < 3: add("WARN", f"only {len(set(seq))} scene templates used: add variety")
    if not any(s["template"] == "hero" for s in plan["scenes"]): add("WARN", "no custom 'hero' scene: every scene is a stock template")
    # 2 claims / sources
    claims = plan.get("claims", [])
    if not claims: add("FAIL", "plan.json has no claims[]: nothing is fact-checked")
    bad = [c for c in claims if c.get("status") in ("verified", "attributed") and not c.get("source_urls")]
    if bad: add("FAIL", f"{len(bad)} claims without a source URL")
    elif claims: add("PASS", f"{len(claims)} claims, all with sources")
    if not (V / "sources.md").exists(): add("FAIL", "sources.md missing")
    # 3 commentary depth: opinion/analysis markers, not just reporting
    if not plan.get("aha"): add("FAIL", "plan.json has no 'aha' (the original insight of the video)")
    if not re.search(r"\b(minha opini|eu acho|na minha|o que importa|o que muda|faça|fa[cç]a|troque|use|evite)\w*", narr, re.I): add("WARN", "no opinion or actionable takeaway wording found: is this just reading the news?")
    # 4 package metadata
    pk = V / "package" / "package.md"
    if pk.exists():
        t = pk.read_text()
        tags = re.search(r"## Tags\s+(.+)", t, re.S)
        n = len([x for x in re.split(r"[,\n]", tags.group(1)) if x.strip()]) if tags else 0
        if n > 15: add("WARN", f"{n} tags: keep about 15 relevant ones, no keyword stuffing")
        if not (re.search(r"(?i)divulga|voz sint|narra[cç][aã]o (gerada|sint)|intelig[eê]ncia artificial", t) or re.search(r"\bIA\b", t)): add("WARN", "no AI-use note in the description (see Anti-slop section: disclosure decision)")
        if re.search(r"(?i)urgente|chocante|você não vai acreditar|apocalipse", t): add("WARN", "title/description has clickbait or fake-urgency words")
        if "## Fontes" not in t: add("FAIL", "description has no Fontes section")
    else: add("WARN", "package.md not built yet")
    for lvl, msg in out: print(f"{lvl:<5} {msg}")
    sys.exit(1 if any(l == "FAIL" for l, _ in out) else 0)

main(sys.argv[1])
