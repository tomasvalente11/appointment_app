# Architecture Guide

This document explains how the Nutrium appointment app is structured, how a request flows through the system, and the rationale behind the major design decisions.

---

## 1. High-Level Overview

The app is a classic Rails monolith with two front-end paradigms:

```
┌─────────────────────────────────────────────────────────────┐
│                       Browser                               │
│  ┌──────────────────────┐    ┌──────────────────────────┐   │
│  │ Stimulus controllers │    │ React components         │   │
│  │ (sprinkles)          │    │ (rich UIs)               │   │
│  │ • appointment-modal  │    │ • AppointmentRequests    │   │
│  │ • nutritionist-      │    │ • RequestCard            │   │
│  │   selector           │    │ • ActionButtons          │   │
│  │ • radius-toggle      │    │                          │   │
│  └──────────┬───────────┘    └────────────┬─────────────┘   │
│             │                             │                 │
│             └────── window.I18n ──────────┘                 │
│             (locale strings injected by layout)             │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP / JSON
┌─────────────────────▼───────────────────────────────────────┐
│                      Rails 8.1                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Controllers                                          │   │
│  │ • NutritionistsController     (HTML pages)           │   │
│  │ • Api::AppointmentRequests    (JSON CRUD)            │   │
│  │ • Api::Nutritionists          (slots, dates)         │   │
│  └──────────┬───────────────────────────────────────────┘   │
│             │ delegates business logic to                   │
│  ┌──────────▼─────────────────┐  ┌────────────────────┐     │
│  │ AppointmentRequestService  │  │ NutritionistSearch │     │
│  │ • create / accept / reject │  │ • Algolia client   │     │
│  └──────────┬─────────────────┘  └────────────────────┘     │
│             │ persists via                                  │
│  ┌──────────▼───────────────────────────────────────────┐   │
│  │ Models                                               │   │
│  │ • Nutritionist  • Service  • AvailabilitySlot        │   │
│  │ • AppointmentRequest                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Mailers (deliver_later → ActiveJob)                  │   │
│  │ • AppointmentRequestMailer.request_answered          │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                      │
                      ▼
              PostgreSQL + external services
              (Geocoder API, Algolia, Gmail SMTP)
```

**Why two front-end paradigms?**

- **Stimulus** is great for "sprinkles" of behavior on Rails-rendered HTML — the booking modal is mostly a sequence of show/hide DOM manipulations driven by the server's data attributes. No state tree needed.
- **React** is used only for the nutritionist's request management page (`/nutritionists/:id/requests`), where there's real state (filters, optimistic updates, toast notifications, modal dialogs). The richer interaction warrants component state.

This split is intentional: each tool is used where it's actually best, and we're not paying for SPA complexity on pages that don't need it.

---

## 2. Data Model

```
Nutritionist (1) ──── (N) Service
      │                    │
      │ (1)                │ (N)
      │                    │
      ▼                    ▼
AvailabilitySlot     AppointmentRequest ──── Service
                       (status enum)
```

| Table | Purpose |
|---|---|
| `nutritionists` | Professional profile (name, bio, license, avatar). |
| `services` | The bookable products a nutritionist offers (price, duration, address → geocoded into lat/lng). |
| `availability_slots` | One row per (nutritionist, day_of_week) describing working hours `09:00–17:00`. |
| `appointment_requests` | A guest's booking request. Status is `pending` → `accepted` / `rejected`. Optionally references a service. |

Key constraints encoded in models:
- `AppointmentRequest` validates a unique combination of (guest_email, nutritionist_id, requested_at, status: pending).
- `AvailabilitySlot` validates `day_of_week` is 0–6 and is unique per nutritionist (no two Mondays).
- `Service` triggers `geocoded_by :address` → populates lat/lng on save.

---

## 3. Key Flows

### 3.1 Customer Search Flow

**Route:** `GET /find?q=…&location=…&radius=…`
**Controller:** `NutritionistsController#index`

```
User types "ana" + "Braga" + 25 km
   │
   ▼
NutritionistSearch.search("ana")  ── Algolia returns matching IDs
   │
   ▼
Geocoder.coordinates("Braga")     ── returns [lat, lng]
   │
   ▼
Nutritionist.preload(...)
   .where(id: algolia_ids)
   .nearest_to(lat, lng, max_km: 25)
   │
   ▼
Renders the result list (HTML)
```

**Why split text search and location filtering?**
- **Text search** (name, bio, services) is delegated to **Algolia** because it gives typo-tolerance, weighted ranking, and prefix matching out of the box. Indexed via `NutritionistSearch.to_record` whenever a record is saved (or via `reindex_all` in seeds).
- **Location filtering** uses Geocoder to convert the typed city into coordinates, then filters in SQL using the **Haversine formula** (`Nutritionist.haversine_sql`). This avoids loading every record and computing distance in Ruby.

**Edge cases:**
- No `location` typed → all nutritionists ordered by name.
- Location can't be geocoded → empty list (we don't silently substitute coordinates).
- Online-only services (no address) have no coordinates and are excluded from radius searches; they appear when no location is filtered.

### 3.2 Booking Flow (Customer)

This is a 3-step modal in `appointment_modal_controller.js` (Stimulus):

```
┌─────────┐    ┌──────────┐    ┌──────────────┐    ┌─────────┐
│ Step 1  │ →  │ Step 2   │ →  │ Step 3       │ →  │ Success │
│ Choose  │    │ Date +   │    │ Name + email │    │         │
│ pro +   │    │ time     │    │              │    │         │
│ service │    │          │    │              │    │         │
└─────────┘    └──────────┘    └──────────────┘    └─────────┘
     │              │                 │
     │              │                 ▼
     │              │      POST /api/appointment_requests
     │              │      → AppointmentRequestService.create
     │              │
     │              ▼
     │   GET /api/nutritionists/:id/available_dates
     │   GET /api/nutritionists/:id/available_slots?date=…&service_id=…
     │
     ▼
GET /find?q=…&format=json   (typeahead suggestions)
```

**Step 1 — picking a nutritionist:**
- If the modal was opened from a nutritionist's card, the field is pre-filled and locked (`readOnly = true`).
- If opened from a generic CTA, the user types and we hit `/find?format=json` for suggestions.

**Step 2 — slot selection:**
- The calendar (Flatpickr) calls `available_dates` once on mount and grays out days with no availability.
- When a date is picked, we fetch `available_slots` for that date + selected service. Service duration determines slot granularity.
- The server computes:
  1. The nutritionist's `AvailabilitySlot` for that `wday` → list of candidate start times via `open_slots_on(date, duration)`.
  2. Existing accepted bookings on that date → `[start, start+duration]` ranges.
  3. Filters out any candidate that **overlaps** with a booked range (interval-overlap check, not equality).

**Step 3 — submission:**
- Goes through `AppointmentRequestService.create` (see below) which handles invalidation of prior pending requests inside a transaction.

### 3.3 Booking Lifecycle (Server-side)

`AppointmentRequestService.create(params)`:

```
BEGIN TRANSACTION
  for each pending request from the same guest_email:
    update status to :rejected
    enqueue invalidation email
  if !new_request.save:
    raise ActiveRecord::Rollback   ← rolls back the invalidations too
COMMIT
```

This guarantees that if the new request is invalid, we don't accidentally cancel the user's existing pending request.

`AppointmentRequestService.accept!(request)`:

```
BEGIN TRANSACTION
  Nutritionist.lock.find(id)            ← row-lock for serialization
  request.update!(status: :accepted)
  for each pending request that overlaps in time:
    update status to :rejected
    enqueue slot-taken email
COMMIT
enqueue confirmation email to the accepted guest
```

The `Nutritionist.lock.find` is the concurrency safeguard: two nutritionists clicking "accept" on overlapping requests at the same time can't both succeed.

### 3.4 Nutritionist's Request Management

**Route:** `GET /nutritionists/:id/requests` → renders an HTML page that mounts the React `AppointmentRequests` component.

The component:
1. On mount, fetches `/api/nutritionists/:id/appointment_requests` (server returns all requests with serialized service info).
2. Filters client-side by `pending` / `answered` / `all`.
3. Each `RequestCard` shows guest info; pending ones expose `ActionButtons` (Accept / Reject).
4. Clicking Accept → `PATCH /api/appointment_requests/:id` with `{ status: 'accepted' }`. On success, **optimistically** updates local state and shows a toast.
5. Reject opens an in-component modal with an optional rejection reason.

Why React here and not Stimulus? The optimistic update + filter + toast + nested modal is a state graph that's much cleaner with `useState` than DOM manipulation.

---

## 4. Cross-Cutting Concerns

### 4.1 Internationalization (i18n)

All strings live in `config/locales/{en,pt}.yml`. The locale is set via:
- A cookie (`cookies[:locale]`), settable via `GET /locale/:locale`.
- `ApplicationController#set_locale` wraps every action in `I18n.with_locale`.

**Bridge to JavaScript:**
The layout injects a `window.I18n` object on every page:

```erb
<script>
  window.I18n = <%= raw({ locale: I18n.locale.to_s,
                          modal: I18n.t('modal'),
                          requests: I18n.t('requests') }.to_json) %>
</script>
```

Stimulus and React read `window.I18n.modal.btn_confirm` etc. Each access has a sane fallback string so a missing key doesn't crash anything.

**Translatable database content:**
Service names like "First Appointment" are also translated by mapping the DB value to a key:

```erb
t("services.names.#{svc.name.parameterize(separator: '_')}", default: svc.name)
```

This way only the *known* names get translated, unknown ones fall back to the raw DB value.

### 4.2 Email

`AppointmentRequestMailer.request_answered(request, reason: nil)` handles four cases:
- `reason: nil` → delivers an "accepted" or "rejected" email based on the current status.
- `reason: :invalidated` → "you submitted a newer request, this one is cancelled".
- `reason: :slot_taken` → "your time was claimed by another booking".

All called via `deliver_later` (Active Job). In **production**, Solid Queue picks them up. In **development**, the queue adapter is set to `:inline` so they fire synchronously without needing the worker process running (the `pg` 1.6.3 + Ruby 3.4 worker had a segfault we worked around by avoiding that path in dev).

### 4.3 Authorization

There's no auth system — guests don't log in, nutritionists are picked from a dropdown. The only authorization is in `Api::AppointmentRequestsController#update`: it checks that the `nutritionist_id` in the request body matches the request's owner. In a real app this would be replaced by sessions + Pundit/Cancancan.

### 4.4 API Helper (front-end)

`app/javascript/lib/api.js` wraps `fetch` to:
- Inject the CSRF token and `Content-Type: application/json` on every request.
- Throw a typed `Error` with `status` and `data` properties when `!res.ok`.

Used by both the Stimulus modal and the React components, so error handling is consistent and there's no duplicated CSRF boilerplate.

---

## 5. Folder Map (where things live)

```
app/
├─ controllers/
│  ├─ application_controller.rb         # locale handling
│  ├─ nutritionists_controller.rb       # landing, /find, requests page
│  ├─ nutritionist_availability_controller.rb
│  ├─ locales_controller.rb             # cookie-based locale switch
│  └─ api/
│     ├─ appointment_requests_controller.rb  # JSON CRUD
│     └─ nutritionists_controller.rb         # available_dates, available_slots
├─ models/
│  ├─ nutritionist.rb         # scopes: search_by_term, nearest_to, available_on
│  ├─ service.rb              # geocoded_by :address
│  ├─ availability_slot.rb    # open_slots_on(date, duration)
│  └─ appointment_request.rb  # status enum + duplicate-prevention validation
├─ services/
│  ├─ appointment_request_service.rb  # create / accept! / reject!
│  └─ nutritionist_search.rb          # Algolia wrapper
├─ mailers/
│  └─ appointment_request_mailer.rb
├─ javascript/
│  ├─ controllers/                    # Stimulus
│  │  ├─ appointment_modal_controller.js
│  │  ├─ nutritionist_selector_controller.js
│  │  ├─ radius_toggle_controller.js
│  │  └─ tabs_controller.js
│  ├─ components/                     # React
│  │  ├─ AppointmentRequests.jsx      # entry point, mounted by requests_app.js
│  │  ├─ RequestCard.jsx
│  │  ├─ ActionButtons.jsx
│  │  ├─ EmptyState.jsx
│  │  └─ Toast.jsx
│  ├─ lib/
│  │  └─ api.js                       # fetch wrapper
│  └─ requests_app.js                 # React root, mounted on /requests page
└─ views/
   ├─ layouts/application.html.erb    # injects window.I18n, header, locale switch
   └─ nutritionists/
      ├─ landing.html.erb             # role selector
      ├─ index.html.erb               # search results + booking modal markup
      └─ requests.html.erb            # mounts the React app

config/
├─ locales/{en,pt}.yml
├─ initializers/algolia.rb            # stubs Algolia in test env
└─ routes.rb

spec/
├─ models/                            # AppointmentRequest, Nutritionist, AvailabilitySlot
├─ requests/                          # full controller + API specs
├─ services/                          # AppointmentRequestService
├─ mailers/
├─ system/                            # Capybara + headless Chrome (E2E)
├─ factories/                         # FactoryBot factories
└─ support/
   ├─ geocoder.rb                     # stubs city → coords
   └─ system.rb                       # Selenium config
```

---

## 6. Notable Decisions & Trade-offs

| Decision | Why | Trade-off |
|---|---|---|
| Service objects (`AppointmentRequestService`) | Keeps controllers thin, centralizes transactional logic | One more layer to navigate |
| Haversine in SQL via `Arel.sql` | Avoids loading all rows into Ruby for distance computation | SQL-injection risk if inputs aren't sanitized — they are, since `lat`/`lng` are coerced with `.to_f` |
| Algolia for text search | Typo-tolerance, ranking, prefix match — far better than `ILIKE %q%` | External dependency; mocked in test env |
| Stimulus + React side-by-side | Right tool for each job | Two patterns to learn |
| `window.I18n` JSON injection | Simple, no extra build step, works offline | Inflates page payload slightly; only the namespaces the JS needs are exported |
| `inline` adapter for ActiveJob in dev | Avoided a `pg` 1.6.3 segfault in the Solid Queue worker | Emails block the request in dev |
| Online consultations have no address | Nothing to geocode; clean separation between physical/remote | They're filtered out of radius searches by design |

---

## 7. Running and Testing

```bash
bundle install && yarn install
docker-compose up -d                   # PostgreSQL
bundle exec rails db:setup              # creates DB + seeds 6 nutritionists
bin/dev                                 # runs Rails + esbuild watch + Tailwind watch

bundle exec rspec                       # 71 unit/request/mailer specs (skips system specs)
bundle exec rspec spec/system           # E2E (needs Chrome on PATH)
```

---

## 8. Observability

**Currently in place:**

- Rails default logger writing to STDOUT (works for containerized deploys — `kubectl logs`, `docker logs`, etc.)
- `request_id` tag on every log line (`config.log_tags = [:request_id]`) for cross-line correlation
- `TaggedLogging` configured in production
- **Structured domain events** in `AppointmentRequestService` — every booking lifecycle transition emits a `Rails.logger.info({ event: "appointment_request.created", ... })` payload with `request_id`, `nutritionist_id`, and `status`. These are the lines you'd build dashboards from.

**Events currently emitted:**

| Event | When |
|---|---|
| `appointment_request.created` | New booking submitted |
| `appointment_request.create_failed` | Submission failed validation |
| `appointment_request.accepted` | Nutritionist accepted |
| `appointment_request.rejected` | Nutritionist rejected (with `has_note` flag) |
| `appointment_request.invalidated` | Replaced by a newer request from the same email |
| `appointment_request.slot_taken` | Cancelled because someone else got the slot |

**For production observability (Datadog / Grafana / Loki), I'd add:**

- **lograge** with the JSON formatter — collapses the 5–10 default Rails log lines per request into one structured line ready for log explorers.
- **DogStatsD / StatsD client** — counters and histograms in the service layer:
  - `appointments.created.count` (tagged by service, location)
  - `appointments.accepted.count` / `rejected.count`
  - `slots.fetch.duration` (p50/p95)
  - `geocoder.errors.count`, `algolia.errors.count`
- **Sentry** for error grouping/alerting — both Ruby SDK on the back-end and the JS SDK on the front-end (currently `console.error(...)` in `api.js` errors don't reach anyone).
- **APM tracing** — `datadog-trace` or `opentelemetry-ruby` for per-request distributed traces (DB query timing, external HTTP calls to Algolia/Geocoder/SMTP).

The reason these aren't in the codebase yet: each requires an account/DSN/agent process to be useful, and a half-configured APM is worse than none. The structured `Rails.logger.info` calls are the foundation — they ship straight into any log platform and give you real business metrics today.