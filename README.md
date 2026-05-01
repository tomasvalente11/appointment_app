# Appointment App

A nutritionist appointment booking platform built with Ruby on Rails 8 and React.

Patients can search for nutritionists, browse their services, and book appointments through a multi-step flow. Nutritionists manage their availability and respond to booking requests through a dedicated dashboard.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8.1, PostgreSQL 16 |
| Frontend | React 19, Stimulus, Tailwind CSS, esbuild |
| Background jobs | Solid Queue |
| Search | Algolia |
| Geocoding | Geocoder (Haversine distance in SQL) |
| Email | Action Mailer via Gmail SMTP |
| Tests | RSpec, FactoryBot, Capybara |

---

## Prerequisites

- Ruby 3.4.9
- Node.js + Yarn
- PostgreSQL 16 (or Docker)

---

## Setup

**1. Install dependencies**

```bash
bundle install
yarn install
```

**2. Start the database**

Using Docker:

```bash
docker-compose up -d
```

Or point `config/database.yml` at an existing PostgreSQL instance (default credentials: user `appointment`, password `password`).

**3. Set environment variables**

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

| Variable | Purpose |
|---|---|
| `ALGOLIA_APP_ID` | Algolia application ID |
| `ALGOLIA_ADMIN_KEY` | Algolia admin API key (used server-side) |
| `ALGOLIA_SEARCH_KEY` | Algolia search-only key |
| `GMAIL_USER` | Gmail address used for outbound mail |
| `GMAIL_PASSWORD` | Gmail app password |

> **Algolia:** Create a free account at [algolia.com](https://www.algolia.com), create an index named `nutritionists`, and copy the App ID and API keys. The seed script automatically syncs nutritionist data to Algolia.
>
> **Gmail:** Enable 2-factor authentication on your Google account and generate an [App Password](https://support.google.com/accounts/answer/185833) to use as `GMAIL_PASSWORD`.

**4. Create and seed the database**

```bash
bin/rails db:create db:migrate db:seed
```

The seed script creates 6 nutritionists with services, availability slots, and sample appointment requests.

> **Note:** `db:seed` geocodes service addresses via the Geocoder gem (one request per service with a 1-second delay). It takes about 30–60 seconds to complete.

---

## Running the app

Use `bin/dev` to start all processes (Rails server, JS bundler, CSS watcher):

```bash
bin/dev
```

Then visit [http://localhost:3000](http://localhost:3000).

---

## Running the tests

```bash
bundle exec rspec
```

System tests require Chrome. To skip them:

```bash
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"
```

---

## Architecture notes

**Booking flow**

The customer-facing booking is handled by a Stimulus controller (`appointment_modal_controller.js`) that drives a 3-step modal: select nutritionist + service → pick date/time → enter contact details. Available dates and time slots are fetched dynamically from the API based on the nutritionist's availability and already-accepted appointments.

**Conflict detection**

When a nutritionist accepts a request, `AppointmentRequestService.accept!` runs inside a transaction with a row-level lock on the nutritionist record. Any pending requests that overlap the accepted slot's duration are automatically rejected. This prevents double-bookings even under concurrent accepts.

**Slot invalidation**

When a patient submits a new booking request, any previous pending requests from the same email address are automatically rejected. This keeps the nutritionist's queue clean and avoids stale requests accumulating.

**Search**

Full-text search (name, service) uses Algolia. Location-based ordering uses a Haversine formula executed directly in PostgreSQL — no external maps API is needed to calculate distances. In the test environment, Algolia is stubbed and the search falls back to a local `ILIKE` query so tests run without network calls.

**Background jobs**

Emails are sent via `deliver_later` through Solid Queue (Rails' built-in job backend). `ApplicationJob` is configured to retry on deadlocks and discard on deserialization errors (e.g. if a request is deleted before its notification job runs).

**Internationalisation**

The app supports English and Portuguese. Language can be switched via the locale selector in the header.
