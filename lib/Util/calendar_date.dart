/// Formats a local calendar day as the `YYYY-MM-DD` the backend's validator
/// expects.
///
/// Both the attendance and absence services had their own identical copy of
/// this, one of them carrying a comment saying it matched the other. One
/// implementation means a change to the wire format cannot be applied to half
/// the app.
///
/// Padded by hand rather than with `DateFormat('yyyy-MM-dd')` on purpose:
/// `intl` renders digits in the active locale, so under Arabic it would emit
/// ٢٠٢٦-٠٩-١٣ and the server would reject the date. This keeps them ASCII
/// whatever locale the app is running in.
String formatCalendarDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
