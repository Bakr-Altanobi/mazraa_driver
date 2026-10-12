# Known backend gaps

These findings come from the latest inspected `main` branch and read-only production verification on 2026-10-10.

## Blocking workflow gaps

1. **No PickedUp → InTransit action endpoint.** `ShipmentStateService` requires `PickedUp → InTransit → NearCustomer`, but `ShipmentsController` exposes pickup and near-customer without a route that sets InTransit. A driver can successfully pick up and then become unable to proceed. The app displays this gap and does not call an invalid transition.
2. **No available-offers feed.** `GET api/Shipments` filters non-admin users to `CustomerId == userId || DriverId == userId`, so a driver cannot discover unassigned Pending shipments.
3. **No driver self-service online/offline endpoint.** The administrative `PUT api/Drivers/{id}` requires `users.edit`, accepts a broad DTO, and is not appropriate for a driver availability toggle.

## Financial gaps

- Wallet fields are a general user wallet, not a proven driver earnings ledger.
- `DeliveryFee`, `TransportCost`, and `NetProfit` are shipment/platform fields and are not labelled as driver pay.
- No verified endpoints exist for driver earnings per trip, payout methods, withdrawal requests, withdrawal history, settlements, bonuses, or COD reconciliation.
- The UI shows real wallet balances/transactions and disables unsupported payout actions.

## Account and operations gaps

- `POST api/Auth/register` creates a general registration through the auth use case; no verified driver application, OTP, password recovery, vehicle self-service, document upload, or approval workflow contract is exposed.
- Driver profile update is administrative and permission-gated; there is no safe `/me` update route.
- No verified support-ticket/chat endpoint exists.
- No proof-of-delivery photo/signature/PIN, pickup QR/barcode, partial delivery, return-to-store, batched route, maintenance, referral, or emergency report contract was found in the inspected controllers.
- Shipment list has no server pagination, search, date filters, or explicit scheduled/available feeds.

## Maps, realtime, and notifications

- Tracking computes straight-line Haversine distance and ETA from recent speed; it does not return a road route or encoded polyline.
- No authenticated Routes API backend proxy is available.
- SignalR is present in source and a realtime channel name is returned, but a complete documented mobile authentication/subscription contract was not verified.
- Notification storage/read endpoints exist. A verified FCM/APNs device-token registration lifecycle was not found.

## Production contract inconsistency

Production login succeeded for the seeded driver but returned empty `role`/`roles`. The driver record itself is valid (`UserId 6`, Approved, Van), so the mobile app gates access by fetching `/api/Drivers/{userId}` after login.

## Recommended minimal backend changes

1. Add an idempotent `POST api/Shipments/{id}/start-transit` using the existing state service.
2. Add permission-scoped `GET api/Shipments/available` with offer expiry/concurrency semantics.
3. Add `/api/Drivers/me/status` and `/api/Drivers/me/location` contracts with driver authorization.
4. Add driver earnings and payout DTOs whose accounting definitions are explicit.
5. Add device-token registration/revocation and document the SignalR JWT handshake.
6. Add mobile-safe `/me` profile, vehicle, documents, recovery, and support contracts.

No backend mutation or deployment was made from this application workspace.

