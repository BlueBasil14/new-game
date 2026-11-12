#!/usr/bin/env python3
"""Roblox saturation check: for each search query, list top results by live player count.

Usage: roblox_saturation.py "query one" "query two" ...
Prints, per query: total CCU across first page, and top N games (CCU, like ratio, name).
"""
import json, sys, time, urllib.parse, urllib.request, uuid

def search(q):
    url = ("https://apis.roblox.com/search-api/omni-search?searchQuery="
           + urllib.parse.quote(q) + "&sessionId=" + str(uuid.uuid4()) + "&pageType=all")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=25) as r:
                data = json.load(r)
            break
        except Exception as e:
            if attempt == 3:
                return None, str(e)
            time.sleep(2 * (attempt + 1))
    games = []
    for grp in data.get("searchResults", []):
        if grp.get("contentGroupType") != "Game":
            continue
        for c in grp.get("contents", []):
            up, down = c.get("totalUpVotes", 0), c.get("totalDownVotes", 0)
            games.append({"name": c.get("name", ""), "ccu": c.get("playerCount", 0),
                          "like": round(100 * up / (up + down)) if up + down else None,
                          "votes": up + down, "sponsored": c.get("isSponsored", False),
                          "placeId": c.get("rootPlaceId")})
    return games, None

def main():
    top_n = 6
    for q in sys.argv[1:]:
        games, err = search(q)
        if err:
            print(f"## {q}\n  ERROR {err}\n"); continue
        ranked = sorted(games, key=lambda g: -g["ccu"])
        print(f"## {q}  (results={len(games)}, sumCCU={sum(g['ccu'] for g in games)}, >=1k: {sum(1 for g in games if g['ccu']>=1000)})")
        for g in ranked[:top_n]:
            print(f"  {g['ccu']:>7}  {str(g['like'])+'%':>5}  {g['votes']:>8}v  {g['name'][:70]}")
        print()
        time.sleep(0.6)

if __name__ == "__main__":
    main()
