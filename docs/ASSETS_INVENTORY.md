# Assets inventory

All visual assets below were created for this project as lightweight SVG files and are referenced through `pubspec.yaml`.

| Path | Type | Purpose | Used by |
|---|---|---|---|
| `assets/branding/mazraa_mark.svg` | SVG brand mark | Leaf, field, and warm accent identity derived from the supplied client-app reference | Splash, onboarding, login, home |
| `assets/illustrations/empty_shipments.svg` | SVG illustration | Empty shipment/notification/transaction states | Shared `EmptyState` |
| `assets/maps/driver_marker.svg` | SVG marker | Driver/vehicle location visual | Asset library; custom native bitmap conversion can use it later |
| `assets/maps/store_marker.svg` | SVG marker | Store/pickup location | Asset library |
| `assets/maps/customer_marker.svg` | SVG marker | Customer/drop-off location | Asset library |
| `assets/decorations/leaf_pattern.svg` | SVG decoration | Subtle agricultural card/banner pattern | Design asset library |

The embedded map currently uses native marker hues for reliable Google Maps rendering and a code-drawn branded fallback when no key is configured. No remote bitmap is required for core navigation UI.

`assets/icons`, `assets/animations`, and `assets/fonts` are reserved directories; no unused files or secret/licensed fonts are bundled there.

