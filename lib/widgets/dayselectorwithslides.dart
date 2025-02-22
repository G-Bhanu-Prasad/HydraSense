import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySelectorWithSlides extends StatelessWidget {
  final bool isLoading;
  final DateTime dop;
  final DateTime selectedDateTime;
  final Map<String, int> dailyIntakes;
  final int dailyGoal;
  final ValueChanged<String> onDateSelected;

  const DaySelectorWithSlides({
    required this.isLoading,
    required this.dop,
    required this.selectedDateTime,
    required this.dailyIntakes,
    required this.dailyGoal,
    required this.onDateSelected,
    super.key,
  });

  bool isSelectedDate(DateTime date) {
    return selectedDateTime.year == date.year &&
        selectedDateTime.month == date.month &&
        selectedDateTime.day == date.day;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onDateSelected(DateFormat('yyyy-MM-dd').format(picked));
    }
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

    return Column(
      children: [
        // Header with Month-Year on the left and Today-Date on the right
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Text(
                  DateFormat('MMMM yyyy').format(selectedDateTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Text(
                  isSelectedDate(today)
                      ? "Today, ${DateFormat('d').format(selectedDateTime)}"
                      : "Otherday, ${DateFormat('d').format(selectedDateTime)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: PageView.builder(
            itemCount: weeks.length,
            controller: PageController(
              initialPage: weeks.length - 1, // Start at the last (current) week
            ),
            itemBuilder: (context, index) {
              List<DateTime> week = weeks[index];
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: week.map((date) {
                      String dateStr = DateFormat('yyyy-MM-dd').format(date);
                      double progress =
                          (dailyIntakes[dateStr] ?? 0) / dailyGoal;
                      bool isFutureDay = date.isAfter(today);
                      bool isProfileCreationDate = date.isAtSameMomentAs(dop);

                      return Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: MaterialButton(
                              onPressed: isFutureDay
                                  ? null
                                  : () => onDateSelected(dateStr),
                              color: isSelectedDate(date)
                                  ? Colors.blue
                                  : (isFutureDay
                                      ? Colors.grey.shade700
                                      : isProfileCreationDate
                                          ? Colors.cyan.shade900
                                          : Color.fromARGB(255, 9, 47, 103)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                              child: Text(
                                DateFormat('E').format(date),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[100],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Container(
                                width: 40 * (progress > 1.0 ? 1.0 : progress),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
