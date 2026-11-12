# HEAVY QUEUE

Tasks that need Opus/Fable judgment. Do not hand these to Haiku.

| ID | Why heavy | Status |
|---|---|---|
| T-LOG-02 FloodFill | Correctness and performance at 160×160; every territory bug traces here | DONE (untested in Studio) |
| T-LOG-05 ArenaSim | Encodes all of G2; touches grid, economy events, bots, replication | DONE (untested in Studio) |
| T-SRV-01 DataService | Data loss is unrecoverable; session locking | DONE (untested in Studio) |
| T-SRV-02 ArenaService | Replication protocol + anti-exploit | DONE (untested in Studio) |
| T-SRV-08 Main / request router | Security boundary for every client request | DONE (untested in Studio) |
| T-CLI-01 TurfRenderer | Performance-critical on mobile | DONE (untested in Studio) |
| T-INT-01 Cross-system review | Touches everything | WIP |
| Post-launch: EditableImage turf renderer | New architecture; verify current API docs first | TODO |
| Post-launch: team mode | Changes G2 rules | TODO |
