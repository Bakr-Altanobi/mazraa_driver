# Screens and workflow checklist

Legend: **Connected** uses a verified server contract; **Local** is client-only preference/content; **Blocked** is intentionally unavailable because the backend contract is missing.

| Area | Screen / state | Location | Status | Verification |
|---|---|---|---|---|
| Launch | Branded splash + session restore | `features/auth/auth_screens.dart` | Connected | Widget/runtime code + analyzer |
| Onboarding | Intro and language-aware copy | same | Local | Widget-rendered |
| Auth | Driver login + validation/errors | same | Connected | Live production login + widget tests |
| Auth | Driver registration, OTP, recovery | login explanatory sheet | Blocked | No safe endpoint |
| Home | Map-focused dashboard | `features/home/home_screen.dart` | Connected/conditional | Uses real shipments, wallet, GPS; Maps requires key |
| Home | Online/offline toggle | status banner | Blocked | No self-service endpoint |
| Shipments | All, active, history, search | `shipment_screens.dart` | Connected | Production list read |
| Shipments | Available offers | filter empty state | Blocked | Server filters unassigned rows |
| Shipment | Details, map points, estimates | details screen | Connected | Typed contract + API source review |
| Shipment | Accept/reject/pickup/near/deliver/fail | details action area | Connected where transition exists | Unit state-machine tests; no production mutation |
| Shipment | PickedUp → InTransit | gap banner | Blocked | Missing endpoint confirmed in controller/state service |
| Pickup | Product verification, QR/barcode, proof photo | shipment workflow | Blocked | No verified proof DTO/upload endpoints |
| Delivery | OTP/PIN, signature, photo proof | shipment workflow | Blocked | No verified proof-of-delivery contract |
| Incidents | Failure reason | shipment details | Connected | Uses real `/fail` request |
| Incidents | Closed store, damaged cargo, emergency, reassignment, returns | — | Blocked | No verified structured incident endpoints |
| Tracking | Foreground one-shot location upload | details screen | Connected | Permission and payload implemented; no production mutation |
| Navigation | External Google Maps | details screen | Connected when coordinates exist | URL contract implemented |
| Navigation | Embedded Google map | reusable map panel | Conditional | Requires native key and build flag |
| Wallet | Balance and monthly summary | `wallet_screen.dart` | Connected | Production wallet read |
| Wallet | Transactions | same | Connected | API parsing implemented |
| Earnings | Per-trip driver earnings | wallet notice | Blocked | No authoritative ledger |
| Payouts | Withdraw/transfer/settlement | disabled actions | Blocked | No endpoints |
| Notifications | List, unread count, mark read/all | `notifications_screen.dart` | Connected | Unread production read; writes not executed |
| Profile | Driver, vehicle, approval, rating | `profile_screen.dart` | Connected | Production profile read |
| Profile | Edit details/documents/vehicle | profile | Blocked | Only admin update contract |
| Performance | Ratings | profile header | Connected | DriverDto values |
| Performance | Acceptance, punctuality, hours, goals, achievements | — | Blocked | No verified metrics/scheduling/rewards endpoints |
| Settings | Arabic/English | settings screen | Local | Arabic/English widget test |
| Settings | Light/dark/system | settings screen | Local | Dark widget test |
| Support | FAQ and transparent capability notice | support screen | Local/Blocked | No fake ticket submission |
| Advanced | Multi-stop, batches, partial delivery, multi-store, returns, fleet, maintenance, referrals | — | Blocked | No verified backend workflow/DTO contracts |
| Realtime/push | SignalR and FCM/APNs | — | Blocked | Authentication/channel and device-token lifecycle incomplete |
| Logout | Secure logout | profile | Connected | Code/analyzer; production session preserved during verification |

All screens include safe areas, responsive scrolling, loading/error/empty states, and no placeholder success actions.
