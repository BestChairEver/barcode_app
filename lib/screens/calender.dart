import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils/product_provider.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    DateTime today = DateTime.now();
    Set productsForSelectedDay = {};
    
    if (_selectedDay != null) {
      productsForSelectedDay.addAll(productProvider.products
          .where((product) => isSameDay(product.expiryDate, _selectedDay!)));
    }

    if (_selectedDay == null || isSameDay(_selectedDay!, today)) {
      productsForSelectedDay.addAll(productProvider.products
          .where((product) => isSameDay(product.expiryDate, today)));
    }

    List uniqueProductsForSelectedDay = productsForSelectedDay.toList();
    _scheduleNotificationsForProducts(uniqueProductsForSelectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('Календарь'),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8.0,
                ),
              ],
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: EdgeInsets.all(16.0),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2101),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              locale: Localizations.localeOf(context).toString(),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: TextStyle(color: Colors.blueGrey),
              ),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                selectedDecoration: BoxDecoration(
                  color: Colors.blueGrey[300],
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red),
              ),
              eventLoader: (day) {
                return productProvider.products
                    .where((product) => isSameDay(product.expiryDate, day))
                    .toList();
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: uniqueProductsForSelectedDay.isNotEmpty
                ? ListView.builder(
                    itemCount: uniqueProductsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final product = uniqueProductsForSelectedDay[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16.0),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Icon(Icons.fastfood, color: Colors.white),
                            ),
                            title: Text(
                              product.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18.0),
                            ),
                            subtitle: Text(
                              'Срок годности: ${DateFormat('dd.MM.yyyy').format(product.expiryDate)}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14.0),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied,
                            size: 60, color: Colors.grey[400]),
                        SizedBox(height: 16.0),
                        Text(
                          'Нет продуктов с истекающим сроком годности на выбранную дату.',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _scheduleNotificationsForProducts(List products) async {
    for (var product in products) {
      await product.scheduleNotification();
    }
  }
}
