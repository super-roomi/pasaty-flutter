import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_status_page.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) => DateTime(2026, 7, 4, hour, minute);

  test('6:00–8:59 is the morning window', () {
    expect(runWindowFor(at(6)), RunWindow.morning);
    expect(runWindowFor(at(8, 59)), RunWindow.morning);
  });

  test('13:00–15:59 is the afternoon window', () {
    expect(runWindowFor(at(13)), RunWindow.afternoon);
    expect(runWindowFor(at(15, 59)), RunWindow.afternoon);
  });

  test('outside both windows no run is available', () {
    expect(runWindowFor(at(5, 59)), RunWindow.none);
    expect(runWindowFor(at(9)), RunWindow.none);
    expect(runWindowFor(at(12, 59)), RunWindow.none);
    expect(runWindowFor(at(16)), RunWindow.none);
    expect(runWindowFor(at(22)), RunWindow.none);
  });
}
