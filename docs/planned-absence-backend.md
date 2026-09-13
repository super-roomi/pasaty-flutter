# Planned absence — backend design

**Feature:** let a parent flag their child as not riding, for a date range and
phase, so the driver's run never stops for them. **The route is never redrawn.**

**Status:** design draft, not yet built.

---

## 0. Why this is small

The system already has the exact primitive this feature needs — the `ABSENT`
attendance status — and everything downstream already does the right thing with
it. This feature is almost entirely "let a parent produce `ABSENT`, and produce
it earlier."

Three existing behaviours make the route-redraw constraint free:

1. **The driver already skips `ABSENT` children.** The morning flow surfaces one
   `WAITING` student at a time (`lib/Pages/Driver Pages/dv_status_page.dart`),
   and `_servedStudentIds` counts anything past `WAITING` as served. A child who
   is `ABSENT` at run start is simply never surfaced.
2. **The ETA server already omits absent children.** Per the `RouteEta` contract
   in `lib/services/socket_service.dart`: *"Students already picked up … or
   dropped off / absent are filtered out by the server."* An absent child
   produces no outstanding stop and no countdown, with no geometry or ETA
   recomputation.
3. **`attendance:updated` already broadcasts a single student's status change**,
   and both the driver screen and every parent roster already consume it.

So the design reduces to: *set a student to `ABSENT` for a date + phase,
initiated by the parent, effective whether or not the run has started* — and let
the existing machinery carry it the rest of the way.

---

## 1. Data model

One new table, `planned_absence`:

| column | type | notes |
|---|---|---|
| `id` | pk | |
| `studentid` | FK → students | ownership-checked against the requesting parent |
| `date` | date | local calendar date, `YYYY-MM-DD` (same convention as the app's `formatDate`) |
| `phase` | enum(`morning`,`afternoon`) | whole-day request = two rows |
| `createdby` | FK → users | the parent, for audit |
| `createdat` | timestamptz | |

**Unique constraint:** `(studentid, date, phase)`. This is what makes create
idempotent and lets a range be stored as individual rows without duplication.

**Why individual rows, not a stored range object:**

- the unique key dedups and keeps `POST` idempotent;
- a parent can cancel one day out of a span;
- the run-start consult and the per-day driver/ETA behaviour stay unchanged —
  each day's start endpoint only ever asks about its own date.

A row lives only until its run starts. At run start it is consumed into an
attendance row (see §3); after that the attendance table is the source of truth
and the `planned_absence` row is history/audit only.

---

## 2. Parent endpoints

All are parent-role and verify the student belongs to the caller — the same
ownership check `GET /v1/protected/attendance/:id` already performs. All follow
the app's existing conventions: idempotent, HTTP status carries the error kind
(`403` not your child, `409` wrong state, `404` unknown).

### `POST /v1/protected/absence`

Body: `{ studentid, from, to, phases }` where `phases ⊆ {morning, afternoon}`
(whole day = both).

Behaviour — the backend expands the span into one `(date, phase)` at a time and,
for each, branches on whether that run exists yet:

| state of that date+phase | action |
|---|---|
| run not started (no attendance row) | insert `planned_absence` row; idempotent — re-post returns existing with `changed:false` |
| run in progress, child still `WAITING` | skip the table; perform the **live** `ABSENT` transition (the same internal call the driver's `absentMorning`/`absentAfternoon` uses), emitting `attendance:updated` |
| child already `BOARDED` / `ARRIVED` / `DROPPED_OFF` | `409` — cannot un-ride a child on the bus |

Only *today's* already-started phase can go live; every future date in the range
is always a planned row. A range that includes today resolves today live (with
the boarding guard) and the rest as planned rows, in one response.

**Validation:** `from ≤ to`; no past dates; a capped window (recommend ≤ 30 days)
to bound row creation from one request; `phases` non-empty.

### `DELETE /v1/protected/absence`

Body: `{ studentid, date, phase }` — cancels one planned (pre-run) absence.

Cancel applies only to a *planned* row. Once a planned absence has been consumed
into a live `ABSENT` at run start, reversing it is the driver's existing undo,
not this endpoint. This boundary must be stated to parents in the UI.

A "cancel whole span" convenience is a client-side fan-out of per-day deletes;
no separate endpoint needed.

### `GET /v1/protected/absence?from=&to=`

Returns the individual upcoming `planned_absence` rows for the parent's children,
so the client can render state and offer cancel. The client groups contiguous
`(student, phase)` rows into a span for display.

---

## 3. The one integration point

The existing `POST /v1/attendance/:routeid/morning/start` and
`.../afternoon/start` endpoints build the roster and insert attendance rows.
Change: when inserting, set `status = ABSENT` instead of `WAITING` for any
student that has a matching `planned_absence(date, phase)` for today.

That is the entire integration on the run side. The start endpoint already
returns the roster, so:

- the driver receives those children as `ABSENT` and never surfaces them;
- the `morning_started` / `afternoon_started` broadcast carries `ABSENT` to
  every parent watching the room;
- history (`attendanceOn`) already shows them as `ABSENT`, so no extra history
  work.

**Route and ETA: untouched by construction.** No geometry, no waypoint reorder,
no ETA endpoint change. The absent student is simply absent from the served set
and the ETA stop list, which is already how both behave.

---

## 4. Rules and edge cases

- **Ownership:** every endpoint verifies `studentid` belongs to the caller.
- **Idempotency:** duplicate `POST` returns the existing row, `changed:false`.
- **Boarding guard:** `409` once the child is boarded or later.
- **Timezone:** `date` is a local calendar date string, consistent with the
  clock-based run windows (`runWindowFor`: 06:00–08:59 morning, 13:00–15:59
  afternoon).
- **No new push:** drivers are not a push target today
  (`lib/Pages/Driver Pages/dv_main_shell.dart`); the roster reflects the change,
  so no notification is required.
- **v1 scope:** single date range + phase set. No recurring / standing absences
  (e.g. "every Friday") — deferred.

---

## 5. Migration and rollback

- **Migration:** one additive table; one guarded line in each start endpoint
  ("if a `planned_absence` row exists, insert `ABSENT`"). No change to the
  attendance schema.
- **Rollback:** stop consulting the table and drop it. No attendance data
  migration, because a consumed planned absence is already an ordinary `ABSENT`
  attendance row.

---

## 6. Acceptance

1. Parent flags a child absent for tomorrow morning → next morning's start roster
   returns that child `ABSENT` → driver's waiting queue never surfaces them → no
   outstanding ETA stop for them.
2. Parent flags absent after the run started but before boarding → `attendance:
   updated` `ABSENT` broadcast → driver screen drops them from the waiting queue
   live; other parents see `ABSENT`.
3. Parent tries to flag after the child boarded → `409`.
4. Parent cancels a planned absence before run start → child is `WAITING` at run
   start.
5. No route geometry or ETA endpoint changes; the ETA simply omits the absent
   student.
