#!/usr/bin/env python3
"""Build data/compatibility.json: MacPlay's curated list merged with community data.

Sources
- data/games.json: MacPlay's own hand-maintained entries (engine, presets, fixes).
  They keep their status; community data is only attached to them.
- AppleGamingWiki (CC BY-NC-SA 3.0): the {{Compatibility/macOS}} block of every
  game page. The CrossOver or Wine rating with the most recent dated report is
  used; games with a native Mac version are listed as "native".
- AreWeAntiCheatYet (MIT): anti-cheat status under Linux/Proton. Games whose
  anti-cheat is Denied or Broken there, and that no other source covers, are
  listed as "blocked".

The output is only rewritten when the list of games changes, so a weekly run
with nothing new commits nothing. Standard library only.
Usage: python3 tools/update_compat.py
"""
import datetime
import json
import os
import re
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURATED = os.path.join(ROOT, "data", "games.json")
OUTPUT = os.path.join(ROOT, "data", "compatibility.json")

AGW_API = "https://www.applegamingwiki.com/w/api.php"
AGW_PAGE = "https://www.applegamingwiki.com/wiki/"
AWACY_DATA = "https://raw.githubusercontent.com/AreWeAntiCheatYet/AreWeAntiCheatYet/master/games.json"
AWACY_PAGE = "https://areweanticheatyet.com/game/"
USER_AGENT = "MacPlay-compat-updater/1.0 (https://github.com/faldyfin/macplay)"

# AppleGamingWiki rating -> MacPlay status
RATING_STATUS = {"perfect": "gold", "playable": "silver", "runs": "bronze", "menu": "borked", "unplayable": "borked"}


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=120) as response:
        # the wiki occasionally serves bytes that are not valid UTF-8
        return json.loads(response.read().decode("utf-8", errors="replace"))


def agw_pages():
    """Every main-namespace page using {{Compatibility/macOS}}, with its wikitext."""
    pages, cont = [], {}
    while True:
        params = {"action": "query", "generator": "embeddedin", "geititle": "Template:Compatibility/macOS",
                  "geinamespace": "0", "geilimit": "50", "prop": "revisions", "rvprop": "content",
                  "rvslots": "main", "format": "json", "formatversion": "2", **cont}
        data = fetch(AGW_API + "?" + urllib.parse.urlencode(params))
        for page in data.get("query", {}).get("pages", []):
            revision = (page.get("revisions") or [{}])[0]
            pages.append((page["title"], revision.get("slots", {}).get("main", {}).get("content", "")))
        if "continue" not in data:
            return pages
        cont = data["continue"]
        time.sleep(1)  # be gentle with a community wiki


def template_block(wikitext, name):
    """The full {{name ...}} call, nested templates included."""
    start = wikitext.find("{{" + name)
    if start < 0:
        return ""
    depth, i = 0, start
    while i < len(wikitext):
        if wikitext.startswith("{{", i):
            depth, i = depth + 1, i + 2
        elif wikitext.startswith("}}", i):
            depth, i = depth - 1, i + 2
            if depth == 0:
                return wikitext[start:i]
        else:
            i += 1
    return wikitext[start:]


def template_params(block):
    return {m.group(1): m.group(2).strip()
            for m in re.finditer(r"^\|[ \t]*([a-z0-9 \-]+?)[ \t]*=[ \t]*(.*)$", block, re.M)}


def plain_text(markup, limit=300):
    """Wiki markup -> short plain text for the notes field."""
    text = re.sub(r"<ref[^>]*/>", "", markup)
    text = re.sub(r"<ref[^>]*>.*?</ref>", "", text, flags=re.S)
    while re.search(r"\{\{[^{}]*\}\}", text):
        text = re.sub(r"\{\{[^{}]*\}\}", "", text)
    text = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", text)
    text = re.sub(r"\[https?://\S+\s+([^\]]*)\]", r"\1", text)
    text = re.sub(r"<[^>]+>|'''?", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def slug(title):
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")


def wiki_summary(title, wikitext):
    """Rating, method, date and notes from one wiki page, or None if it has no usable rating."""
    params = template_params(template_block(wikitext, "Compatibility/macOS"))
    appid = re.search(r"^\|steam appid[ \t]*=[ \t]*(\d+)", wikitext, re.M)
    summary = {"title": title, "steam_appid": int(appid.group(1)) if appid else None,
               "url": AGW_PAGE + urllib.parse.quote(title.replace(" ", "_")),
               "native": params.get("native", "").lower() in ("perfect", "playable")}
    candidates = []
    for method in ("crossover", "wine"):
        rating = params.get(method, "").lower()
        if rating in RATING_STATUS:
            notes = params.get(method + " notes", "")
            dates = re.findall(r"\|date=(\d{4}-\d{2}-\d{2})", notes)
            candidates.append((max(dates) if dates else "", rating, method, notes))
    if candidates:
        reported, rating, method, notes = max(candidates)
        summary.update(rating=rating, method=method, reported=reported or None, notes=plain_text(notes))
    elif not summary["native"]:
        return None
    return summary


def build():
    curated = json.load(open(CURATED, encoding="utf-8"))["games"]
    wiki = [s for s in (wiki_summary(t, w) for t, w in agw_pages()) if s]
    anticheat = {str(g["storeIds"]["steam"]): g for g in fetch(AWACY_DATA) if (g.get("storeIds") or {}).get("steam")}
    wiki_by_appid = {s["steam_appid"]: s for s in wiki if s["steam_appid"]}

    def attach(entry, appid):
        if appid in wiki_by_appid and "rating" in wiki_by_appid[appid]:
            s = wiki_by_appid[appid]
            entry.update(wiki_rating=s["rating"], wiki_method=s["method"],
                         wiki_reported=s["reported"], wiki_url=s["url"])
        ac = anticheat.get(str(appid)) if appid else None
        if ac:
            entry.update(anticheat_status=ac["status"], anticheats=ac.get("anticheats") or [],
                         anticheat_url=AWACY_PAGE + ac["slug"])
        return entry

    games, seen = [], set()
    for g in curated:
        games.append(attach(dict(g, source="macplay"), g.get("steam_appid")))
        seen.add(g.get("steam_appid") or ("title", g["title"].lower()))

    for s in wiki:
        key = s["steam_appid"] or ("title", s["title"].lower())
        if key in seen:
            continue
        seen.add(key)
        native = s["native"]
        entry = {"id": "agw-" + slug(s["title"]), "title": s["title"], "steam_appid": s["steam_appid"],
                 "status": "native" if native else RATING_STATUS[s["rating"]],
                 "backend": "none" if native else "",
                 "notes": None if native else (s.get("notes") or None),  # the app says "native" itself
                 "source": "applegamingwiki", "source_url": s["url"]}
        if "rating" in s:  # not via attach(): pages without a Steam id have their rating too
            entry.update(wiki_rating=s["rating"], wiki_method=s["method"],
                         wiki_reported=s["reported"], wiki_url=s["url"])
        games.append(attach(entry, s["steam_appid"]))

    for appid, ac in anticheat.items():
        if ac["status"] not in ("Denied", "Broken") or int(appid) in seen:
            continue
        seen.add(int(appid))
        names = ", ".join(ac.get("anticheats") or []) or "its anti-cheat"
        entry = {"id": "awacy-" + ac["slug"], "title": ac["name"], "steam_appid": int(appid),
                 "status": "blocked", "backend": "none",
                 "notes": f"{names} does not run under Wine on Linux/Proton ({ac['status']}), so it is not expected to run on a Mac either.",
                 "source": "areweanticheatyet", "source_url": AWACY_PAGE + ac["slug"]}
        games.append(attach(entry, int(appid)))

    games.sort(key=lambda g: g["title"].lower())
    return games


def main():
    games = build()
    previous = json.load(open(OUTPUT, encoding="utf-8")) if os.path.exists(OUTPUT) else {}
    if previous.get("games") == games:
        print(f"no changes ({len(games)} games)")
        return
    document = {
        "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "license": "CC BY-NC-SA 3.0 (includes AppleGamingWiki content: https://creativecommons.org/licenses/by-nc-sa/3.0/)",
        "sources": [
            {"name": "MacPlay curated list", "url": "https://github.com/faldyfin/macplay/blob/main/data/games.json"},
            {"name": "AppleGamingWiki", "url": "https://www.applegamingwiki.com", "license": "CC BY-NC-SA 3.0"},
            {"name": "AreWeAntiCheatYet", "url": "https://areweanticheatyet.com", "license": "MIT"},
        ],
        "games": games,
    }
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(document, f, ensure_ascii=False, indent=1)
        f.write("\n")
    counts = {}
    for g in games:
        counts[g["source"]] = counts.get(g["source"], 0) + 1
    print(f"wrote {len(games)} games: {counts}")


if __name__ == "__main__":
    main()
