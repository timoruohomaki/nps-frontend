# Architecture

System-level reference for the `ruohomaki.fi` civic feedback stack.
Repo-specific concerns live in each project's own `README.md` and
`CLAUDE.md`; this document captures the cross-cutting design decisions
that no single repo owns.

## System Topology

```
                ┌──────────────────────────────────────────────┐
                │                  Flutter                     │
                │                nps-frontend                  │
                │   (iOS, Android, macOS — single client)      │
                └────────┬─────────────────────┬───────────────┘
                         │                     │
              lookup ◄───┘                     └───► submit
            (read-only)                            (system of record)
                 │                          ┌────────┴────────┐
                 ▼                          ▼                 ▼
        ┌────────────────┐         ┌────────────────┐ ┌────────────────┐
        │   pygeoapi     │         │    nps-api     │ │ open311-to-Go  │
        │  (OGC Features)│         │ (NPS feedback) │ │ (service reqs) │
        │  api/geo/      │         │  api/nps/      │ │  api/open311/  │
        └────────────────┘         └────────┬───────┘ └────────┬───────┘
                                            │                  │
                                            ▼                  ▼
                                   ┌──────────────────────────────┐
                                   │       MongoDB Atlas          │
                                   │   (geocluster01, X.509 auth) │
                                   │   feedback + service_requests│
                                   └──────────────────────────────┘
```

Hosting: all three Go APIs and pygeoapi sit behind Nginx at
`api.ruohomaki.fi/<path>`. Each backend is a separate Docker container.

## Components

### nps-frontend
Single Flutter codebase. Identifies the user's context (via GPS or a
demo override), looks up nearby features in pygeoapi, lets the user pick
one, then branches to either an NPS form or an Open311 issue form based
on the feature's collection. See [`/CLAUDE.md`](../CLAUDE.md).

### pygeoapi (read-only picker)
OGC API Features service. Hosts curated geographic feature collections
(streetlights, transport networks, facilities, etc.). The frontend
queries it directly at submission time to resolve "what am I rating /
reporting against?" pygeoapi **never** receives writes from this stack;
the data is curated upstream as part of the urban-digital-twin work.

### nps-api (NPS write path)
Go REST API that accepts NPS feedback submissions and stores them in
MongoDB. Currently deployed at `api.ruohomaki.fi/nps`. See
[`nps-api/CLAUDE.md`](https://github.com/timoruohomaki/nps-api/blob/main/CLAUDE.md).

### open311-to-Go (Open311 write path)
Go REST API that implements the Open311 GeoReport v2 spec for service
requests. Phase 2b scope. Will deploy at `api.ruohomaki.fi/open311`. See
[`open311-to-Go/README.md`](https://github.com/timoruohomaki/open311-to-Go/blob/main/README.md).

### MongoDB Atlas
Single cluster (`geocluster01`) hosts both backends' data. Auth is
X.509 client-cert (`authMechanism=MONGODB-X509`). Each backend has its
own database / collection.

## Data Flow

### Lookup (read)

```
1. Flutter resolves a source coordinate (GPS or DEMO_LAT/DEMO_LON)
2. Flutter computes a bbox around that coordinate (radius typically 100m)
3. Flutter issues parallel GETs to each pygeoapi collection:
     GET /geo/collections/<coll>/items?bbox=minLon,minLat,maxLon,maxLat
4. Flutter merges results, Haversine-sorts by distance, takes top-N (~5)
5. User picks one from the candidate list
```

### Submit (write)

```
1. User taps "Rate this service" or "Report an issue" on screen 1
2. App navigates to NPS form or Issue form on screen 2
3. On submit, app POSTs to nps-api or open311-to-Go with:
   - The chosen feature embedded as a `feature` subdocument (see below)
   - Form-specific fields (rating + comment, or category + description + photos)
4. Backend validates, persists to MongoDB, returns 201 + a submission id
```

## Shared `feature` Subdocument

Both NPS feedback records and Open311 service requests embed the same
feature reference. This keeps each submission self-describing even if
pygeoapi changes or goes offline later.

### Schema

```json
{
  "feature": {
    "collection": "streetlights",
    "feature_id": "55746",
    "display_name": "Streetlight 55746",
    "lat": 42.29817,
    "lon": -71.08692,
    "snapshot_at": "2026-06-06T15:42:00Z"
  }
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `collection` | string | yes | pygeoapi collection ID, e.g. `streetlights`, `transport_networks`, `facilities`, `service_request_locations` |
| `feature_id` | string | yes | pygeoapi feature ID, stringified (pygeoapi returns integers, we coerce for stable Mongo storage) |
| `display_name` | string | yes | Human-readable name shown to the user at pick time (cached so reports don't need a pygeoapi join) |
| `lat` / `lon` | number | yes | Centroid of the feature's geometry (for points: the point; for lines/polygons: server-computed centroid) |
| `snapshot_at` | ISO 8601 string | yes | When the feature was resolved at submit time. Lets historical records survive feature-set re-imports. |

### Submission record shape (combined)

NPS feedback (`nps-api`):

```json
{
  "schema_version": "1.0",
  "app": "nps-frontend-demo",
  "app_version": "0.1.0",
  "platform": "iOS",
  "timestamp": "2026-06-06T15:42:00Z",
  "nps_rating": 9,
  "nps_category": "promoter",
  "timezone": "Europe/Helsinki",
  "comment": "...",
  "feature": { /* shared subdocument */ }
}
```

Open311 service request (`open311-to-Go`, JSON variant):

```json
{
  "service_code": "broken_streetlight",
  "description": "...",
  "lat": 42.29817,
  "lon": -71.08692,
  "media_url": "https://...",
  "feature": { /* shared subdocument */ }
}
```

Note: Open311 itself carries `lat`/`lon` separately because the spec
mandates it. The `feature` subdocument is our extension, encoding
*which curated asset* was selected, not just *where on the map*.

## Two-Page UX Flow

```
┌─ Screen 1: About this place ─────────────────┐
│ [logo]                                       │
│                                              │
│ About this place                             │
│ ‹  <display_name>  ›   ▾                     │
│        1 of N nearby                         │
│                                              │
│ What would you like to do?                   │
│ [Rate this service →] [Report an issue →]    │
│  (NPS-eligible only)  (Issue-eligible only)  │
└──────────────────────────────────────────────┘
        ↓                       ↓
┌─ Screen 2a: NPS ──────────┐ ┌─ Screen 2b: Issue ────────────┐
│ 10 rating tiles           │ │ Service category (list)       │
│ Optional comment          │ │ Description (free text)       │
│ Submit → nps-api          │ │ Photo (deferred)              │
└───────────────────────────┘ │ Submit → open311-to-Go        │
                              └───────────────────────────────┘
```

The candidate picker (Pattern C — see chat-history rationale): arrows for
cycling 2–5 candidates inline, chevron opens a full bottom-sheet list for
N>5 or for users who prefer scanning.

## Collection → Action Branching

Action buttons surface based on which collection(s) the candidate set
contains. Categorization is **per collection, not per feature** — there is
no `category` property on individual features.

| Collection | NPS button | Issue button |
|---|---|---|
| `facilities` (planned) | ✅ | ✅ |
| `streetlights` | ❌ | ✅ |
| `transport_networks` | ❌ | ✅ |
| `service_request_locations` (historical) | ❌ | ❌ — reference data, not picker source |
| `administrative_units` | ❌ | ❌ — context only |
| `statistical_units` | ❌ | ❌ — context only |

When the selected feature's collection allows multiple actions, both
buttons render; the user picks. When it allows only one, only that
button renders.

## LocationSource Abstraction

Frontend treats GPS and demo seeds polymorphically:

```dart
abstract class LocationSource {
  Future<List<FeatureReference>> nearby({double radiusM = 100});
}

class PygeoapiLocationSource implements LocationSource {
  // Uses geolocator to get device GPS, then queries pygeoapi
  // collections in parallel and merges + sorts.
}

class DemoLocationSource implements LocationSource {
  // Reads --dart-define=DEMO_LAT/DEMO_LON as the source coordinate,
  // then calls the real pygeoapi (same code path as production).
  // Yields real query latency, deterministic location.
}
```

The screen depends only on `LocationSource`; the implementation is
selected at startup based on whether `DEMO_LAT` and `DEMO_LON` are both
defined.

## Demo Override

For thesis demos and simulator runs where real GPS is unavailable or
returns Apple HQ:

```bash
flutter run -d macos \
  --dart-define=DEMO_LAT=42.30425 \
  --dart-define=DEMO_LON=-71.06425 \
  ...
```

This **fakes the source coordinate** but still runs the real pygeoapi
query. The demo shows the actual query performance against the real
dataset, with a stable "you are here" point so the candidate list is
reproducible across runs.

## Phase Roadmap

### Phase 1 — Shipped
- nps-api: configurable platform allowlist + optional `X-API-Key`
- nps-frontend: scaffold, Fleet-inspired theme, end-to-end NPS submission
- Verified against the production MongoDB cluster via cert auth

### Phase 2a — Frontend two-page UX + NPS-with-location
- `LocationSource` abstraction + GPS implementation + demo override
- Screen 1 ("About this place") with the candidate picker
- Screen 2a (NPS form) updated to embed the `feature` subdocument
- Screen 2b (Issue form) as a "coming soon" stub
- nps-api: add optional `feature` subdocument to the Feedback model
- **Blocked on**: pygeoapi `facilities` collection (5–20 seed features)
  to make the NPS path data-driven rather than coarse

### Phase 2b — open311-to-Go endpoints (backend-heavy)
Implement the four core Open311 endpoints:

- `GET /open311/api/v2/services` — service categories
- `GET /open311/api/v2/services/{id}` — service definition (form fields)
- `POST /open311/api/v2/requests` — submit a service request
- `GET /open311/api/v2/requests/{id}` — request status lookup

Plus the X-API-Key middleware pattern (copy from `nps-api/internal/middleware/apikey.go`).
JSON-only first; XML deferred.

### Phase 2c — Issue form wired to live open311 backend
- Replace Screen 2b stub with a real form driven by GET /services
- POST on submit, show returned ticket number
- Photo upload deferred (camera permission, image picker, multipart
  upload, media storage backend — its own decision)

### Beyond phase 2
- Open311 XML support + Helsinki locale extensions + PSK 5970 properties
- Photo upload (camera + media storage)
- Ticket status push notifications
- Aggregation dashboards on top of the MongoDB collections
- Map view as an alternative to the list-style candidate picker

## Conventions That Cross Repos

- **Go version:** 1.24+ on both nps-api and open311-to-Go
- **Router:** standard library `net/http` with Go 1.22+ patterns; no
  framework (Echo / Gin / Fiber) in either backend
- **Auth:** `X-API-Key` header against a CSV env var (`API_KEYS`).
  Constant-time compare. Health endpoints stay open. Empty `API_KEYS` =
  no auth (back-compat).
- **CORS:** handled at Nginx, not in the Go apps
- **MongoDB:** Atlas cluster `geocluster01`, X.509 cert auth via
  `tlsCertificateKeyFile=<path>`. Each backend has its own database.
- **Observability:** Sentry on both backends (optional via `SENTRY_DSN`)
- **Time:** ISO 8601 / RFC 3339 in JSON; UTC server-side; local zone
  preserved in the `timezone` field for analytics
- **Deployment:** GitHub Actions → ghcr.io image → SSH deploy → docker
  compose restart on the server (same shape on both backends)

## Open Questions

These are decided in chat but not in code yet — capture them here so
phase 2 doesn't restart from scratch:

- **NPS picker fallback when `facilities` is empty:** drop the picker
  entirely and submit without `feature`, or coarsen to neighborhood
  (`admin_unit_id`)? Current plan: drop the picker and submit without
  `feature`.
- **Photo upload backend:** S3-compatible (MinIO/Backblaze) vs Mongo
  GridFS vs filesystem on the deploy host. Decide at phase 2c+ planning.
- **Anonymous vs identified issue reports:** Open311 spec allows both.
  Default to anonymous; add an opt-in email/phone callback field later.
- **Ticket status push:** out-of-scope for phase 2, but worth a sketch
  before phase 2b commits to a ticket-id format.
