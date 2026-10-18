# Driver → Ecommerce API integration checkpoint — 2026-10-18

Scope: the 48 canonical journey screens in `lib/features/reference_journey`, using the real `Ecommerce_Api` contracts. This is an **incremental integration checkpoint**, not a certificate of complete worldwide delivery-app parity.

## Verified API contracts used

| Driver journey | API contract | Screens | Implementation on integration branch |
|---|---|---|---|
| Auth / driver identity | `api/Auth/login`, `api/Drivers/{userId}`, `api/driver-journey/me` | 02–03, 12, 44 | Existing authenticated profile flow |
| Online/offline and preferences | `PUT api/driver-journey/me/status`, `GET/PUT api/driver-journey/me/preferences` | 03, 12, 35 | New safe actions; preserve server-owned preference fields |
| Shifts and weekly schedule | `POST api/driver-journey/shifts/start`, `/end`, `GET/PUT api/driver-journey/me/availability` | 16, 41 | Start/end and add/remove windows; preserve other windows |
| Offers | `GET api/driver-journey/offers`, `POST api/driver-journey/offers/{id}/accept|reject` | 04, 23 | Select exact offer ID; explicit confirmation |
| Shipment state machine | `GET api/Shipments`, `POST api/Shipments/{id}/accept|pickup|depart|near-customer|deliver|fail` | 05–08, 18, 25, 40 | Select explicitly eligible shipment; server enforces transition |
| Pickup & delivery evidence | `POST api/Shipments/{id}/proof`, `GET api/Shipments/{id}/proofs` | 07, 26, 28–29 | Textual verification reference / recipient entry; **not** photo/signature capture |
| Scheduled trips | `GET api/driver-journey/scheduled-trips`, `POST .../{id}/join|withdraw` | 16, 27 | Explicit trip selection |
| Driver returns | `GET api/driver-journey/returns`, `POST .../{id}/accept|pickup|complete` | 39 | Driver-only tasks with status-specific actions |
| Wallet, bank, payouts | `api/wallets/me`, `GET/PUT api/driver-journey/bank-accounts|bank-account`, `GET/POST api/driver-journey/payouts` | 09–10, 30, 38, 46 | View account; enter real bank details and request payout using server currency |
| Notifications | `GET api/notifications`, `POST api/notifications/mark-all-read` | 11, 34 | Live feed and mark-all-read |
| Chat/support | `GET api/chats`, `POST api/chats/{id}/messages`, `GET/POST api/support/tickets`, `POST api/support/tickets/{id}/messages`, `POST api/support/live-chat` | 19, 21 | Send in existing chat; create/reply ticket; open support chat |
| Driver incident | `POST api/driver-journey/incidents` | 18, 20, 45 | Existing server-backed report form |
| Driver earnings/referrals/performance/maintenance/documents | Read routes in `api/driver-journey` | 14–15, 17, 22, 24, 32–33, 42–43, 47–48 | Genuine read-only data; not all mutation / image flows implemented |

Screens 01, 13, 31, 34, 36–37 and others include presentation, onboarding, unsupported capability descriptions or locally managed state, as indicated by the catalog. Rendering 48 screens does **not** mean every one supports all reference interactions.

## Safety / correctness

- No action silently takes the first available offer/shipment/return: exact server record selection is mandatory.
- The client re-reads shipment eligibility; backend still owns authorization, offer expiry, concurrency and transitions.
- Payout input is entered by the driver, tied to a selected bank account and the actual wallet currency.
- Bank details are not logged by the integration code, and ticket/chat actions use the authenticated user.
- After a successful mutation, the 48 screen source caches for that user are invalidated.
- Independent screen fetches happen concurrently with a shared in-flight shipment query.
- Server branch also requires approval/verification for driver online, shift start, scheduled-trip join and rejects empty shipment proof.

## Remaining work before claiming **complete delivery product**

1. **Staging end-to-end tests** using approved driver/customer accounts, real persistence and a complete `Pending → Assigned → Accepted → PickedUp → InTransit → NearCustomer → Delivered` transition, plus fail/retry/reassignment cases. No production financial/order writes are performed by this review.
2. **Device evidence:** camera/gallery attachment upload via authenticated media endpoint, signature pad, QR/barcode capture & verification, vehicle/document uploads. Current proof action only stores provided reference/recipient text.
3. **Realtime & mobile background:** location service during active delivery, SignalR reconnect with JWT, push registration/revocation and FCM/APNs project configuration; permission lifecycle on both Android/iOS.
4. **Maps/routing:** production Maps API configuration, route directions/ETA using street routes, navigation fallback and safe location permission behavior.
5. **Onboarding / approvals:** comprehensive driver application, review & document verification, user-facing OTP/password recovery flows and administrative assignment approval.
6. **Operational completeness:** maintenance entry workflows, proof-aware pickup checklists, dispute handling, incident attachments/SOS, customer/driver direct-chat discovery and realtime updates.
7. **Finance:** full driver earnings/COD settlement ledger, verified bank lifecycle, payouts processed by a real payment provider, idempotency/anti-duplication and accounting reconciliation.
8. **Quality gates:** real device UI snapshots for all 48 reference screens, accessibility/RTL checks, Dart full test suite, API integration tests on real relational provider, plus isolated API/UI contract tests for new actions.

## Release policy

- Integration changes remain in draft PRs until CI passes and manual authenticated workflow tests pass.
- Build an installable `android-arm64` Debug APK (without `CI_SMOKE_HOME`) only after merging vetted app changes.
- This checkpoint does not deploy `Ecommerce_Api` or the mobile app to production.
