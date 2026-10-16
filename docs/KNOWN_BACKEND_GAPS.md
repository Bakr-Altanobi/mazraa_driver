# Known backend gaps

These findings reflect the latest inspected `main` branches of `mazraa_driver` and `Ecommerce_Api` as of 2026-10-17. The backend was inspected read-only; no backend mutation or deployment was made.

## Verified connected contracts

The driver app currently has real read contracts for the driver profile (`GET api/Drivers/{userId}`), assigned shipments and shipment details/tracking (`api/Shipments`), the current vehicle (`GET api/Vehicles/my-current`), wallet summary and transactions (`api/wallets/me`, `api/wallets/transactions`), notifications (`api/notifications`), FAQs/tickets/complaints (`api/support/...`), chats (`api/chats`) and delivery zones (`api/DeliveryZones`).

Shipment mutations exposed to the reference journey are the real server actions: pickup, deliver and fail. The app now selects only a shipment whose current status is accepted by `ShipmentStateService` for that action; it never falls back to the first unrelated shipment in the list.

## Blocking shipment workflow gaps

1. **No PickedUp → InTransit action endpoint.** `ShipmentStateService` requires `PickedUp → InTransit → NearCustomer`, but `ShipmentsController` exposes pickup and near-customer without a route that sets InTransit. A driver can pick up a shipment and then cannot progress through the complete state machine using the mobile API alone.
2. **No available-offers feed.** `GET api/Shipments` filters non-admin users to customer/driver-owned shipments, so a driver cannot discover unassigned Pending shipments as marketplace offers.
3. **No driver self-service online/offline endpoint.** Administrative `PUT api/Drivers/{id}` requires `users.edit` and is not a safe availability toggle.
4. **No pickup verification evidence contract.** Pickup does not accept/return item checklist results, barcode/QR verification, temperature, shortage/damage evidence or pickup proof photos. The UI keeps these reference fields visible but does not mark them as confirmed.
5. **No proof-of-delivery contract.** Deliver does not accept/return customer signature, delivery photo, recipient identity or POD reference.
6. **No driver return-assignment feed.** `GET api/returns` is customer-scoped for non-admin users (`CustomerReturnRequest.UserId == current user`) and is not a list of return jobs assigned to a driver. The driver UI therefore does not consume it as a return-work source.

## Financial gaps

- Wallet data is a general user wallet, not an authoritative driver-earnings ledger.
- `DeliveryFee`, `TransportCost` and `NetProfit` are shipment/platform fields; they are not proven driver-pay components.
- No verified driver payout/withdrawal request, payout status, bank account, settlement, bonus/incentive or COD reconciliation contract exists.
- The UI shows the real wallet values and keeps unsupported financial fields/actions visible as backend gaps.

## Account, vehicle and scheduling gaps

- `POST api/Auth/register` is general account registration; there is no public/self-service driver application workflow.
- No driver-specific OTP login, password-recovery flow, self-service KYC upload or document-review workflow is exposed.
- Driver profile update remains administrative and permission-gated; there is no mobile-safe `/me` update route.
- `GET api/Vehicles/my-current` supports current vehicle display, but there is no driver self-service vehicle/document upload or maintenance history.
- There is no weekly availability/shift entity or start/end-shift endpoint.
- There is no referral or driver-incentive entity/endpoint.

## Support, chat and incidents

Support is **not** a missing backend area anymore: `SupportController` exposes FAQs, tickets, ticket messages/close, complaints and live-chat creation, and `ChatsController` exposes conversations and messages. The application uses read-only support/ticket/chat sources and can create a complaint for the incident-report reference screen.

Still missing are driver-specific SOS/geographic emergency dispatch, structured shipment-incident taxonomies and dedicated reassignment workflows.

## Maps, realtime and notifications

- Shipment tracking computes straight-line Haversine distance and ETA; it does not return road routing or an encoded polyline.
- No authenticated Routes API backend proxy is available.
- SignalR channels exist in the server, but a complete documented mobile reconnect/authentication lifecycle is not represented as an app contract yet.
- Notification list/unread/mark-read contracts exist. A complete verified FCM/APNs mobile device-token registration/revocation lifecycle was not found.

## Recommended minimal backend changes

1. Add an idempotent `POST api/Shipments/{id}/start-transit` using the existing shipment state service.
2. Add permission-scoped `GET api/Shipments/available` with assignment/expiry/concurrency semantics.
3. Add driver-safe `/api/Drivers/me/status`, profile and document contracts.
4. Extend pickup/delivery DTOs with explicit verification/POD evidence rather than inferring success in the client.
5. Add a driver-scoped return-assignment/workflow contract instead of reusing customer returns.
6. Add authoritative driver earnings, COD settlement and payout DTOs/endpoints.
7. Add device-token registration/revocation and document the SignalR JWT/reconnect contract.

The application intentionally keeps all unsupported reference fields visible and labels them as server gaps rather than deleting them or filling them with production fake data.
