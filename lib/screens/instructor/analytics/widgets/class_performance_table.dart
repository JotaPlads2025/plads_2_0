import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ClassPerformanceTable extends StatelessWidget {
  final List<Map<String, dynamic>> classData; // {name, attendanceRate, revenue}

  const ClassPerformanceTable({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text('Top Clases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          DataTable(
            headingRowHeight: 40,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Clase', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Asistencia', style: TextStyle(fontSize: 12)), numeric: true),
              DataColumn(label: Text('Ingresos', style: TextStyle(fontSize: 12)), numeric: true),
            ],
            rows: classData.map((data) {
              final rate = (data['attendanceRate'] as double);
              final isHigh = rate > 0.8;
              final isLow = rate < 0.3;
              
              return DataRow(cells: [
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(data['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                  )
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHigh ? Colors.green.withOpacity(0.2) : (isLow ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${(rate * 100).toInt()}%', style: TextStyle(
                      color: isHigh ? Colors.green : (isLow ? Colors.red : Colors.orange),
                      fontWeight: FontWeight.bold,
                      fontSize: 11
                    )),
                  )
                ),
                DataCell(Text('\$${data['revenue']}', style: const TextStyle(fontSize: 12))),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
