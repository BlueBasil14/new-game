# Sky Chest

TurfLoop Main: universe 10776297454 / place 80441552680451. Original basic chest made from native Roblox Parts with purple body, pale lid, gold bands/latch and navy trim.

Every 300 seconds, a chest falls for 3 seconds into the central arena area, announces itself, and emits landing particles. It expires after 120 seconds. The first living player within 8 studs receives one persisted free spin. Winner selection runs entirely on the server and removes the chest before any yielding save.

Wheel outcomes: 500 coins 35%; 25 gems 25%; 1,500 coins 20%; 75 gems 10%; 3-minute 2x speed 8%; Sky Blue skin 2%. Duplicate skin converts to 100 gems. Speed extends its expiry with repeat wins and does not multiply the permanent speed pass. Eligibility, selection, grants and credits are server-owned; profiles preserve unused free and paid spins. Claimed rewards use the existing economy and inventory systems.

Developer product 3732125306, Sky Chest Spin, fixed price 39 Robux. Product description and wheel disclose all probabilities. Paid purchase and spending require PolicyService eligibility; failure to retrieve policy disables paid access. Free credits are consumed first. Receipts persist paid credits through the existing idempotent receipt system.

Client: cream/navy panel, lilac rotating wheel, six original icon cards, slowing tick sounds, prize reveal, currency/skin/speed burst, and optional repeat-purchase button. Low-detail mode reduces particle counts. No purchase is automatically prompted.

Validation: 44 source files compile, xref clean, 14 headless server scenarios pass. Dedicated scenario covers no-credit rejection, restricted-account rejection, free-before-paid, paid receipt replay protection, eligible paid spin, 180-second speed, and duplicate-skin conversion. Solo Studio verified debug drop, physical pickup, free wheel spin, 500-coin result and subsequent 39 Robux offer. No real-money purchase was performed; no two-client race or mobile layout test performed.

Release prerequisite: declare paid random items in Roblox's Maturity & Compliance / Content rating questionnaire before publishing publicly. Dashboard content-rating page returned blank/unusable controls during setup, so this declaration was not submitted. Game remains saved, not published by this task.

Studio-only diagnostic: ServerScriptService.Server.services.SkyChestService.DebugDrop BindableEvent can be fired with a Vector3 to exercise the drop near a tester. It does not exist in live servers. The normal first drop remains at five minutes.
