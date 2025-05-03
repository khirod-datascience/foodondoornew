import 'package:flutter/foundation.dart';

// Enum for order status (align with backend choices)
enum OrderStatus {
  pending,       // Customer placed, vendor needs to accept/reject
  accepted,      // Vendor accepted, preparing food
  preparing,     // Vendor marked as preparing (optional intermediate step?)
  ready_for_pickup, // Food is ready, awaiting delivery agent
  out_for_delivery, // Delivery agent picked up
  delivered,     // Successfully delivered
  cancelled,     // Order cancelled (by customer or vendor)
  rejected,      // Vendor rejected the order
  unknown        // Default/fallback
}

OrderStatus orderStatusFromString(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending': return OrderStatus.pending;
    case 'accepted': return OrderStatus.accepted;
    case 'preparing': return OrderStatus.preparing;
    case 'ready_for_pickup': return OrderStatus.ready_for_pickup;
    case 'out_for_delivery': return OrderStatus.out_for_delivery;
    case 'delivered': return OrderStatus.delivered;
    case 'cancelled': return OrderStatus.cancelled;
    case 'rejected': return OrderStatus.rejected;
    default: return OrderStatus.unknown;
  }
}

String orderStatusToString(OrderStatus status) {
  // Convert enum to backend string format if needed, otherwise use describeEnum
  return describeEnum(status);
}


class OrderItem {
  final String foodItemId;
  final String name;
  final int quantity;
  final double price; // Price at the time of order

  OrderItem({
    required this.foodItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final foodItemJson = json['food_item'] ?? {}; // Assuming food item details are nested
    return OrderItem(
      // Ensure ID comes from the top level or nested structure
      foodItemId: json['food_item_id']?.toString() ?? foodItemJson['id']?.toString() ?? '', 
      name: foodItemJson['name'] ?? json['name'] ?? 'Unknown Item', // Get name from nested or top level
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? (foodItemJson['price'] as num?)?.toDouble() ?? 0.0, // Price from order item or fallback to food item
    );
  }
}

class CustomerInfo {
  final String customerId;
  final String name;
  final String? phoneNumber; // Optional

  CustomerInfo({
    required this.customerId,
    required this.name,
    this.phoneNumber,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    // Adapt keys based on how backend nests/provides customer data
    // Check if 'customer' object exists, otherwise use the root json
    final customerData = json.containsKey('customer') && json['customer'] is Map ? json['customer'] : json;
    return CustomerInfo(
      customerId: customerData['id']?.toString() ?? customerData['customer_id']?.toString() ?? '',
      name: customerData['name'] ?? customerData['full_name'] ?? 'Unknown Customer',
      phoneNumber: customerData['phone_number'],
    );
  }
}

class Order {
  final String id;
  final CustomerInfo customer;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt; // Optional
  final String? deliveryAddress; // Optional, depending on what vendor needs to see
  final String? notes; // Optional customer notes

  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.deliveryAddress,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String? fullAddress;
    if (json['delivery_address'] is Map) {
        // Construct address from parts if available, otherwise use a formatted string
        final addr = json['delivery_address'];
        fullAddress = addr['full_address'] ?? '${addr['street_address'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['postal_code'] ?? ''}'.trim();
        if (fullAddress == ',  ') fullAddress = null; // Handle empty address parts
    } else if (json['delivery_address'] is String) {
        fullAddress = json['delivery_address'];
    }

    return Order(
      id: json['id']?.toString() ?? '',
      // Pass the whole json to CustomerInfo.fromJson, it will check for 'customer' key
      customer: CustomerInfo.fromJson(json), 
      items: (json['order_items'] as List<dynamic>? ?? [])
          .map((itemJson) => OrderItem.fromJson(itemJson))
          .toList(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: orderStatusFromString(json['status']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      deliveryAddress: fullAddress,
      notes: json['notes'],
    );
  }

  Order copyWith({
    String? id,
    CustomerInfo? customer,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deliveryAddress,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
    );
  }
}
