import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/item_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search items...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text('Start typing to search...'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allItems = snapshot.data!.docs;
          final filteredItems = allItems.where((doc) {
            final item = doc.data() as Map<String, dynamic>;
            final name = (item['name'] ?? '').toString().toLowerCase();
            final category = (item['category'] ?? '').toString().toLowerCase();
            final description = (item['description'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                category.contains(_searchQuery) ||
                description.contains(_searchQuery);
          }).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index].data() as Map<String, dynamic>;
              return ItemCard(
                id: filteredItems[index].id,
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