import 'package:flutter_test/flutter_test.dart';
import 'package:taskduo/domain/duo_state.dart';
import 'package:taskduo/domain/models.dart';

import 'test_store.dart';

void main() {
  // Also run with TZ=America/New_York to exercise 23h and 25h days.
  for (final date in [DateTime(2026, 3, 8), DateTime(2026, 11, 1)]) {
    test('daily recurrence advances the calendar on $date', () async {
      var now = DateTime(date.year, date.month, date.day, 12);
      final state = DuoState(TestStore(), clock: () => now);
      await state.load();
      state.saveTask(
        title: 'Diária',
        description: '',
        memberId: 'ana',
        category: TaskCategory.kitchen,
        difficulty: Difficulty.easy,
        due: now,
        recurrence: Recurrence.daily,
      );
      state.completeTask(state.tasks.last.id);
      final next = state.tasks.last;
      expect(next.due, DateTime(date.year, date.month, date.day + 1));
      expect(state.completeTask(next.id), isNull);
      expect(state.points('ana'), 15);
      now = DateTime(date.year, date.month, date.day + 1, 12);
      expect(state.completeTask(next.id), isNotNull);
      expect(state.streak('ana'), 2);
      expect(state.weeklyBars('ana').where((v) => v > 0), hasLength(2));
      await state.flush();
    });
  }
  test('calendar arithmetic crosses month and year boundaries', () {
    expect(addCalendarDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    expect(weekStart(DateTime(2027, 1, 3)), DateTime(2026, 12, 28));
  });
}
