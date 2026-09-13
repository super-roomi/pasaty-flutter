# Planned absence — frontend (Flutter) design

**Feature:** a parent flags their child as not riding, for a date range and
phase, so the driver never stops for them. Companion to
`planned-absence-backend.md`.

**Status:** design draft, not yet built.

---

## 0. Where the work is

Almost all of it is on the **parent** side. The **driver** side needs
essentially nothing, because an absent child arrives `ABSENT` in the run-start
roster and is skipped by the existing `WAITING` surfacing in
`lib/Pages/Driver Pages/dv_status_page.dart`.

The parent UI reuses status plumbing that already exists: `AttendanceStatus.
absent`, the `childLocationFor` mapping, and the live `attendance:updated`
stream that `PrBoardingWidget` already consumes.

---

## 1. New service — `AbsenceService`

New file `lib/services/absence_service.dart`, mirroring the style of
`AttendanceService`. Wraps the three backend endpoints and reuses `ApiClient`
(so 401 refresh, error decoding, and `ApiException` all come for free).

```dart
class PlannedAbsence {
  final int studentId;
  final DateTime date;      // local calendar day
  final String phase;       // 'morning' | 'afternoon'
}

class AbsenceService {
  // POST /v1/protected/absence — {studentid, from, to, phases}
  // Returns the resulting planned rows plus any live transitions applied today.
  static Future<List<PlannedAbsence>> flag({
    required int studentId,
    required DateTime from,
    required DateTime to,
    required Set<String> phases,
  });

  // DELETE /v1/protected/absence — {studentid, date, phase}
  static Future<void> cancel({
    required int studentId,
    required DateTime date,
    required String phase,
  });

  // GET /v1/protected/absence?from=&to=
  static Future<List<PlannedAbsence>> upcoming({
    required DateTime from,
    required DateTime to,
  });
}
```

Dates serialize with the existing `AttendanceService.formatDate` convention
(`YYYY-MM-DD`), so the client and backend agree on calendar days.

---

## 2. Parent UI

### Entry point

The per-child roster row, `_studentRow` in
`lib/Widgets/Parent Widgets/pr_boarding_widget.dart`. That row is shown
**between runs**, which is exactly when a parent plans ahead — the natural home
for the affordance.

Add a trailing control (icon button / overflow) on the row that opens a bottom
sheet.

### The sheet

- A **date-range picker** (`from` … `to`), defaulting to today, capped to the
  same window the backend enforces (recommend ≤ 30 days).
- A **phase toggle**: morning / afternoon / whole day (both). Constrain against
  `runWindowFor` so "this morning" is not offered once the morning window has
  closed.
- Confirm → `AbsenceService.flag(...)`.

### State and rendering

- **Optimistic:** on confirm, show an "Absent (planned)" chip on the row
  immediately, then reconcile against the `flag` response and a subsequent
  `AbsenceService.upcoming(...)` load.
- **During the run:** once the run starts, the child's live status becomes
  `ABSENT` via the roster broadcast, and the existing `childLocationFor` mapping
  already renders it — no new location state to add. The chip on the between-runs
  roster and the live `ABSENT` state are two views of the same fact.
- **Span display:** `upcoming` returns individual `(date, phase)` rows; group
  contiguous `(student, phase)` rows into a span for the label (e.g.
  "Absent Mon–Fri"). Cancel offers per-day removal plus a "cancel whole span"
  convenience that fans out `AbsenceService.cancel` calls.

### Errors

- `409` (child already boarded) → reuse the existing `errorText` conflict copy;
  message the parent that the child is already on the bus.
- Network / other failures → existing `errorText` handling, same as the rest of
  the parent screens.

### Localization

New ARB keys in `lib/l10n/app_en.arb` and `app_ar.arb` (then `flutter gen-l10n`):
the sheet title, phase labels, the span/absent chip, the confirm action, and the
"already boarded" and success messages. Follow the existing key naming.

---

## 3. Driver UI

**No change required for acceptance.** Absent children arrive `ABSENT` in the
start roster and are skipped by the existing `WAITING` surfacing.

**Optional polish (separate, additive change):** a muted "Not riding today" strip
listing pre-absent children, so the driver's head-count reads correctly and the
roster is not silently short. Worth it for driver trust; not needed for the
feature to work.

---

## 4. Acceptance (frontend view)

1. Parent opens a child's row between runs, picks a range + phase, confirms →
   chip appears, and `GET /absence` on reload shows the planned span.
2. When that run starts, the child shows `ABSENT` in the live roster with no
   extra client work (roster broadcast + `childLocationFor`).
3. Flagging a child during an in-progress run, before boarding, reflects `ABSENT`
   live via `attendance:updated`.
4. Flagging after boarding surfaces the `409` "already on the bus" message.
5. Cancelling a planned span before run start removes the chip and the child is
   `WAITING` at run start.
