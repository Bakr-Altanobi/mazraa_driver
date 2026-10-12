# Architecture

## Approach

The app uses a feature-first structure with explicit boundaries:

```text
UI → Riverpod controller/provider → DriverApi → ApiClient → ASP.NET Core API
                                      ↓
                              SecureSessionStore
```

- UI code never constructs HTTP requests.
- `DriverApi` owns endpoint payloads and converts DTO JSON into typed app models.
- `ApiClient` owns timeouts, authorization, one-at-a-time token refresh, retrying the original request once, and normalized API errors.
- `SecureSessionStore` is the only token persistence implementation.
- Riverpod providers expose remote state and support invalidation after mutations.
- `go_router` guards all authenticated routes and uses an indexed shell so tab state is retained.

## Authentication lifecycle

1. Splash reads the encrypted session.
2. The stored access token is validated by loading `/api/Drivers/{userId}`.
3. A 401 triggers a single shared refresh future, preventing refresh-token stampedes.
4. The original request is replayed once with the new token.
5. A failed refresh clears secure storage.
6. Login also verifies the driver record. This compensates for production auth responses where `role` and `roles` are currently empty.
7. Logout calls the server when possible and always clears local secrets.

## Shipment state

The app models the server enum exactly: Pending, InTransit, Delivered, Cancelled, Assigned, Accepted, PickedUp, NearCustomer, Failed. UI actions are rendered from current server state, protected from double taps, confirmed before sensitive mutations, and followed by a server reload.

The known `PickedUp → InTransit` endpoint gap is intentionally surfaced in the UI instead of calling `near-customer` and pretending success. See `KNOWN_BACKEND_GAPS.md`.

## Offline and failure behavior

- Read screens expose loading, empty, retry, and error states.
- Mutations are never queued or automatically replayed because accept/deliver/payment operations are not safe to duplicate without idempotency keys.
- Connection and GPS failures are visible on the home screen.
- Long disconnections require a REST reload; no stale local state is declared authoritative.

## Security

- No passwords, API keys, tokens, or production secrets are committed.
- Tokens are stored using platform secure storage.
- Logs do not print request authorization headers or credentials.
- Maps keys are native build settings, not public Dart constants.
- Production mutations were not exercised during development except authentication/session creation; shipment and wallet writes were deliberately avoided.

## Realtime

The backend exposes shipment group names in tracking responses and includes a SignalR hub in source, but realtime authentication/subscription contracts and push-token registration are not complete enough for a safe client implementation. The current version uses explicit REST refresh and documents this as a gap.

