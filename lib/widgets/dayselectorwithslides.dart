import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySelectorWithSlides extends StatelessWidget {
  final bool isLoading;
  final DateTime dop;
  final DateTime selectedDateTime;
  final Map<String, int> dailyIntakes;
  final int defaultGoal;
  final ValueChanged<String> onDateSelected;

  const DaySelectorWithSlides({
    required this.isLoading,
    required this.dop,
    required this.selectedDateTime,
    required this.dailyIntakes,
    required this.defaultGoal,
    required this.onDateSelected,
    super.key,
  });

  bool isSelectedDate(DateTime date) {
    return selectedDateTime.year == date.year &&
        selectedDateTime.month == date.month &&
        selectedDateTime.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 9, 47, 103),
        ),
      );
    }

    DateTime today = DateTime.now();
    DateTime currentWeekStart =
        today.subtract(Duration(days: today.weekday - 1));
    List<List<DateTime>> weeks = [];

    DateTime weekStart = dop.subtract(Duration(days: dop.weekday - 1));
    while (weekStart.isBefore(currentWeekStart) ||
        weekStart.isAtSameMomentAs(currentWeekStart)) {
      List<DateTime> weekDays = List.generate(
        7,
        (index) => weekStart.add(Duration(days: index)),
      );
      weeks.add(weekDays);
      weekStart = weekStart.add(const Duration(days: 7));
    }

    if (weeks.isEmpty) {
      return const Center(
        child: Text("No weeks available to display"),
      );
    }

    return SizedBox(
      height: 150,
      child: PageView.builder(
        itemCount: weeks.length,
        controller: PageController(
          initialPage: weeks.length - 1, // Start at the last (current) week
        ),
        itemBuilder: (context, index) {
          List<DateTime> week = weeks[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  '${DateFormat('MMM d yyyy').format(week.first)} - ${DateFormat('MMM d yyyy').format(week.last)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: week.map((date) {
                  String dateStr = DateFormat('yyyy-MM-dd').format(date);
                  double progress = (dailyIntakes[dateStr] ?? 0) / defaultGoal;
                  bool isFutureDay = date.isAfter(today);
                  bool isProfileCreationDate = date.isAtSameMomentAs(dop);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: isFutureDay
                              ? null
                              : () => onDateSelected(dateStr),
                          child: CircleAvatar(
                            backgroundColor: isSelectedDate(date)
                                ? const Color.fromARGB(255, 2, 10, 104)
                                : (isFutureDay
                                    ? Colors.grey.shade700
                                    : isProfileCreationDate
                                        ? Colors.green.shade700
                                        : Colors.blueGrey.shade400),
                            child: Text(
                              DateFormat('E').format(date),
                              style: TextStyle(color: Colors.blueGrey.shade100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              width: 38,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[100],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              width: 38 * (progress > 1.0 ? 1.0 : progress),
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 2, 10, 104),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
