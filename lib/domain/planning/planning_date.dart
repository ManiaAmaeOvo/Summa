import 'dart:math' as math;

DateTime planningDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

const firstPlanningYear = 1900;
const lastPlanningYear = 2199;

bool isPlanningDay(DateTime date) =>
    date == planningDay(date) &&
    date.year >= firstPlanningYear &&
    date.year <= lastPlanningYear;

DateTime monthlyPlanningDate(DateTime anchor, int offset) {
  final first = DateTime.utc(anchor.year, anchor.month + offset);
  final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
  return DateTime.utc(first.year, first.month, math.min(anchor.day, lastDay));
}

String encodePlanningDay(DateTime day) =>
    day.toIso8601String().split('T').first;

DateTime? decodePlanningDay(String value) {
  final date = DateTime.tryParse('${value}T00:00:00Z');
  return date != null && isPlanningDay(date) && encodePlanningDay(date) == value
      ? date
      : null;
}
