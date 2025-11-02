import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;
import '../../widgets/location_picker.dart';

class ItemCard extends StatelessWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final String category;
  final String description;
  final String sellerName;
  final int? qualityRating;
  final Map<String, dynamic>? pickupLocation;

  const ItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.category,
    required this.description,
    required this.sellerName,
    this.qualityRating,
    this.pickupLocation,
  });

  @override
  Widget build(BuildContext context) {
    final rating = qualityRating ?? 5;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _FullScreenItemView(
              id: id,
              name: name,
              imageUrl: imageUrl,
              pricePerDay: pricePerDay,
              category: category,
              description: description,
              sellerName: sellerName,
              qualityRating: rating,
              pickupLocation: pickupLocation ?? {},
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 50,
                  ),
                )
                    : const Icon(Icons.inventory_2, size: 50),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sellerName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Rating Stars
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${pricePerDay.toStringAsFixed(0)}/day',
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenItemView extends StatefulWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final String category;
  final String description;
  final String sellerName;
  final int qualityRating;
  final Map<String, dynamic> pickupLocation;

  const _FullScreenItemView({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.category,
    required this.description,
    required this.sellerName,
    required this.qualityRating,
    required this.pickupLocation,
  });

  @override
  State<_FullScreenItemView> createState() => _FullScreenItemViewState();
}

class _FullScreenItemViewState extends State<_FullScreenItemView> {
  LatLng? _deliveryLocation;
  String _deliveryAddress = '';

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  double _calculateDeliveryCharges(double distanceKm) {
    // ₹10 per km
    return distanceKm * 10;
  }

  Future<void> _selectDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLocation: _deliveryLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _deliveryLocation = result['location'];
        _deliveryAddress = result['address'];
      });
    }
  }

  void _showRentalDialog(BuildContext context) {
    // Check if pickup location is available
    if (widget.pickupLocation.isEmpty ||
        widget.pickupLocation['lat'] == null ||
        widget.pickupLocation['lng'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup location not available for this item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if delivery location is selected
    if (_deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select delivery location first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    DateTimeRange? selectedRange;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final days = selectedRange != null
                ? selectedRange!.duration.inDays + 1
                : 0;

            double distance = 0;
            double deliveryCharges = 0;

            if (_deliveryLocation != null) {
              final sellerLat = widget.pickupLocation['lat'];
              final sellerLng = widget.pickupLocation['lng'];
              distance = _calculateDistance(
                sellerLat,
                sellerLng,
                _deliveryLocation!.latitude,
                _deliveryLocation!.longitude,
              );
              deliveryCharges = _calculateDeliveryCharges(distance);
            }

            final rentalPrice = days * widget.pricePerDay;
            final totalPrice = rentalPrice + deliveryCharges;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Rental Details',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 8),
                    Text(
                      'Please select your delivery location on the main screen first',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Selection
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF1A237E),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedRange = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Select Rental Dates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (selectedRange != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1A237E).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 20,
                                  color: Color(0xFF1A237E),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Rental Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              'From:',
                              DateFormat('MMM dd, yyyy').format(selectedRange!.start),
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              'To:',
                              DateFormat('MMM dd, yyyy').format(selectedRange!.end),
                            ),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              'Duration:',
                              '$days ${days == 1 ? "day" : "days"}',
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              'Rental (₹${widget.pricePerDay.toStringAsFixed(0)} × $days):',
                              '₹${rentalPrice.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              'Distance:',
                              '${distance.toStringAsFixed(2)} km',
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              'Delivery Charges:',
                              '₹${deliveryCharges.toStringAsFixed(0)}',
                            ),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              'Total Amount:',
                              '₹${totalPrice.toStringAsFixed(0)}',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedRange == null
                      ? null
                      : () async {
                    await _addToCart(
                      context,
                      selectedRange!.start,
                      selectedRange!.end,
                      days,
                      totalPrice,
                      distance,
                      deliveryCharges,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: isTotal ? const Color(0xFF1A237E) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _addToCart(
      BuildContext context,
      DateTime startDate,
      DateTime endDate,
      int days,
      double totalPrice,
      double distance,
      double deliveryCharges,
      ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to cart'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final cartItemId = '${widget.id}_${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(cartItemId)
          .set({
        'itemId': widget.id,
        'itemName': widget.name,
        'imageUrl': widget.imageUrl,
        'pricePerDay': widget.pricePerDay,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'days': days,
        'rentalPrice': days * widget.pricePerDay,
        'deliveryCharges': deliveryCharges,
        'distance': distance,
        'totalPrice': totalPrice,
        'category': widget.category,
        'sellerName': widget.sellerName,
        'pickupLocation': widget.pickupLocation,
        'deliveryLocation': {
          'lat': _deliveryLocation!.latitude,
          'lng': _deliveryLocation!.longitude,
          'address': _deliveryAddress,
        },
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Added to cart! Total: ₹${totalPrice.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPickupLocation = widget.pickupLocation.isNotEmpty &&
        widget.pickupLocation['address'] != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with close button
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.imageUrl.isNotEmpty
                  ? Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.inventory_2,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.category,
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Item Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF212121),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < widget.qualityRating ? Icons.star : Icons.star_border,
                          size: 24,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.qualityRating}/5',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Seller Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listed by',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.sellerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Price
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1A237E).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rental Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                        Text(
                          '₹${widget.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Pickup Location
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.store,
                          color: Color(0xFF1A237E),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item available at:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasPickupLocation
                                    ? widget.pickupLocation['address']
                                    : 'Address not available',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  // Delivery Location Section
                  const Text(
                    'Your Delivery Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _selectDeliveryLocation();
                      setState(() {});
                    },
                    icon: const Icon(Icons.location_on),
                    label: Text(
                      _deliveryLocation == null
                          ? 'Select Delivery Location on Map'
                          : 'Delivery Location Selected ✓',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _deliveryLocation == null
                          ? const Color(0xFF1A237E)
                          : Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  if (_deliveryLocation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery Location:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _deliveryAddress,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () => _showRentalDialog(context),
            icon: const Icon(Icons.shopping_cart_outlined, size: 24),
            label: const Text(
              'Rent This Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}