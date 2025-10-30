import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Music', 'icon': Icons.music_note, 'color': Colors.purple, 'desc': 'Instruments, DJ gear'},
      {'name': 'Gym & Sports', 'icon': Icons.fitness_center, 'color': Colors.orange, 'desc': 'Equipment, gear'},
      {'name': 'Hardware Tools', 'icon': Icons.construction, 'color': Colors.green, 'desc': 'Drills, saws'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: (cat['color'] as Color).withOpacity(0.2),
                child: Icon(cat['icon'] as IconData, size: 30, color: cat['color'] as Color),
              ),
              title: Text(cat['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(cat['desc'] as String),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => AppRoutes.navigateToCatalogue(context, cat['name'] as String),
            ),
          );
        },
      ),
    );
  }
}