# Headless server playtest

Status: IN PROGRESS (this file is updated incrementally).

| scenario | status |
|---|---|
| a_boot | PASS: Main boots, 8 remotes + Request, world built, 10 runners within 5 s, bots claim ~11k cells in 120 s, no warn/error/misuse |
| z_mock_selftest | PASS: proves the mock rejects unknown props/methods/classes/enums, wrong types, read-only writes, callback reads, bad remote payloads, infinite WaitForChild |


## How to run

```
node tools/luau/headless.mjs            # every scenario in tests/headless/
node tools/luau/headless.mjs boot soak  # only scenarios whose file name contains one of the words
```

## Defects found

| # | file:line | symptom | fix |
|---|-----------|---------|-----|

## Mock fixes (mock was wrong, not the game)

## Suspicious / unsettled
