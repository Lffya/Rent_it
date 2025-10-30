import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemCard extends StatelessWidget {
  final String docId;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final int quantity;
  final String sellerName;

  const CartItemCard({
    super.key,
    required this.docId,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.quantity,
    required this.sellerName,
  });

  Future<void> updateQuantity(int newQuantity) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(userId).collection('items').doc(docId);

    if (newQuantity <= 0) {
      await cartRef.delete();
    } else {
      await cartRef.update({'quantity': newQuantity});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover))
                  : const Icon(Icons.inventory_2, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('by $sellerName', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('₹$pricePerDay/day', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => updateQuantity(quantity - 1),
                        icon: const Icon(Icons.remove_circle_outline),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        onPressed: () => updateQuantity(quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => updateQuantity(0),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}