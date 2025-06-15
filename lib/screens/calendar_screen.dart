import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/handball_providers.dart';
import 'results_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final datesAsync = ref.watch(datesWithGamesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('NHB Match Results'),
      ),
      body: datesAsync.when(
        data: (availableDates) {
          if (availableDates.isEmpty) {
            return const Center(
              child: Text('No game results available'),
            );
          }
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select a date with game results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  // Only allow selection of days with games
                  if (_isDayWithGames(selectedDay, availableDates)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    
                    // Update the selected date in the provider
                    ref.read(selectedDateProvider.notifier).state = selectedDay;
                    
                    // Navigate to the results screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ResultsScreen(
                          selectedDate: selectedDay,
                        ),
                      ),
                    );
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                // Only enable days with games
                enabledDayPredicate: (day) => 
                  _isDayWithGames(day, availableDates),
                // Event markers for days with games
                eventLoader: (day) {
                  return _isDayWithGames(day, availableDates) ? ['Game'] : [];
                },
                calendarStyle: const CalendarStyle(
                  // Customize the appearance of days with games
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  // Make unavailable days more visibly disabled
                  disabledTextStyle: TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough),
                  // Highlight selected day
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('Error loading calendar data: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(datesWithGamesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  bool _isDayWithGames(DateTime day, List<DateTime> availableDates) {
    return availableDates.any((date) => 
      date.year == day.year && date.month == day.month && date.day == day.day
    );
  }
}