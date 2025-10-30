import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/item_card.dart';
import '../../routes/app_routes.dart';

class CataloguePage extends StatelessWidget {
  final String category;
  const CataloguePage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').where('category', isEqualTo: category).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!.docs;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No items in $category yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => AppRoutes.navigateToAddItem(context),
                    icon: const Icon(Icons.add),
                    label: const Text('List an item'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              return ItemCard(
                id: items[index].id,
                name: item['name'] ?? '',
                imageUrl: item['imageUrl'] ?? '',
                pricePerDay: (item['pricePerDay'] ?? 0).toDouble(),
                category: item['category'] ?? '',
                description: item['description'] ?? '',
                sellerName: item['sellerName'] ?? 'Unknown',
              );
            },
          );
        },
      ),
    );
  }
}