import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/item_card.dart';
import '../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Music', 'icon': Icons.music_note, 'color': Colors.purple},
      {'name': 'Gym & Sports', 'icon': Icons.fitness_center, 'color': Colors.orange},
      {'name': 'Hardware Tools', 'icon': Icons.construction, 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BML Rentals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => AppRoutes.navigateToSearch(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handshake, size: 60, color: Colors.white),
                    SizedBox(height: 16),
                    Text('Rent or List Items', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Your Marketplace for Everything', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return InkWell(
                  onTap: () => AppRoutes.navigateToCatalogue(context, cat['name'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (cat['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'] as IconData, size: 50, color: cat['color'] as Color),
                        const SizedBox(height: 12),
                        Text(cat['name'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cat['color'] as Color)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('All Items', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items').orderBy('createdAt', descending: true).limit(6).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                final items = snapshot.data!.docs;
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Text('No items listed yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => AppRoutes.navigateToAddItem(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Be the first to list!'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}