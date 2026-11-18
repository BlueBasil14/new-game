# Battle pass build status

Heartbeat: 2026-11-18 05:10 local, lead session (interactive)

Design: `docs/BATTLEPASS.md`. Owner decisions: Premium 399 R$, Premium+ 799 R$ (+10 tiers), 14-day seasons, 30 tiers.
Product ids stay 0 until the owner creates them on the dashboard or approves creation (paid items).

## Checklist
- [x] Design written
- [x] Design reviewed by 2 subagents (v1 7 and 6.5, v2 8 and 8; v3 fixes applied)
- [x] Shared logic: `src/shared/BattlePass.luau` (season, tiers, rewards, XP, claim rules) + spec `tests/battlepass.spec.luau`
- [x] Server: `src/server/services/BattlePassService.luau` (state, XP from quests/captures/kills, claims, receipts), remote, 5 daily missions
- [ ] Season skins in Catalog (4 animated Legendaries, 4 Rares, source "pass") + animated turf in TurfRenderer + animated shop cards
- [ ] Client: `src/client/controllers/PassController.luau` horizontal pass screen, missions sheet, HUD button, juice
- [ ] Studio test (claims, premium via Studio debug grant, tier up, scroll, phone width)
- [ ] UI review by 2 subagents with screenshots; iterate until both score 9+
- [ ] DONE (score 9+)

## Notes
- Studio test hook: `ServerScriptService.Server.services.BattlePassService.DebugPass:Fire(player, "premium"|"plus"|"tier"|"xp"|"reset", amount)`.
- Season items exist in Catalog (source "pass", release "pass"); hidden from the shop until Config.BattlePass.Start is set.
- Next: animated turf in TurfRenderer (anim field), then PassController UI.
- `src/shared/ProfileTemplate.luau` has another session's uncommitted edit (retired-cosmetics fallback). Do not edit it:
  pass state is reconciled by BattlePass itself (ProfileTemplate keeps unknown top-level keys).
