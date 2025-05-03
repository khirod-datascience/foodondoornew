import 'package:flutter/foundation.dart';
import 'package:foodondoor_vendor_app/src/features/order_model.dart';
import 'package:foodondoor_vendor_app/src/features/order_service.dart';

enum OrderStatusFilter { all, pending, accepted, preparing, ready_for_pickup }

enum OrderListState { initial, loading, loaded, error }

class OrderProvider with ChangeNotifier {
  final OrderService _orderService;

  OrderProvider(this._orderService) {
    // Optionally fetch initial orders here or wait for UI trigger
    // fetchOrders(); 
  }

  List<Order> _orders = [];
  OrderListState _state = OrderListState.initial;
  String? _errorMessage;
  OrderStatusFilter _currentFilter = OrderStatusFilter.pending; // Default to pending
  bool _isUpdatingOrder = false; // Track state for individual order updates

  List<Order> get orders => _orders;
  OrderListState get state => _state;
  String? get errorMessage => _errorMessage;
  OrderStatusFilter get currentFilter => _currentFilter;
  bool get isUpdatingOrder => _isUpdatingOrder;

  void _setState(OrderListState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setUpdatingOrder(bool updating) {
    _isUpdatingOrder = updating;
    notifyListeners(); // Notify to show/hide loading indicator for order actions
  }

  Future<void> fetchOrders({OrderStatusFilter? filter}) async {
    _currentFilter = filter ?? _currentFilter;
    _setState(OrderListState.loading);
    _errorMessage = null;

    String? statusQueryParam;
    switch (_currentFilter) {
      case OrderStatusFilter.pending: statusQueryParam = 'pending'; break;
      case OrderStatusFilter.accepted: statusQueryParam = 'accepted'; break;
      case OrderStatusFilter.preparing: statusQueryParam = 'preparing'; break;
      case OrderStatusFilter.ready_for_pickup: statusQueryParam = 'ready_for_pickup'; break;
      case OrderStatusFilter.all: // No query param needed for all
      default: statusQueryParam = null;
    }

    try {
      _orders = await _orderService.fetchOrders(status: statusQueryParam);
      _setState(OrderListState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(OrderListState.error);
      print('Error in OrderProvider fetchOrders: $e');
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    _setUpdatingOrder(true);
    bool success = false;
    try {
      success = await _orderService.acceptOrder(orderId);
      if (success) {
        // Update the local order state or refetch
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          // Create a new order object with updated status
           final updatedOrder = Order(
             id: _orders[index].id,
             customer: _orders[index].customer,
             items: _orders[index].items,
             totalAmount: _orders[index].totalAmount,
             status: OrderStatus.accepted, // Set new status
             createdAt: _orders[index].createdAt,
             updatedAt: DateTime.now(), // Update timestamp
             deliveryAddress: _orders[index].deliveryAddress,
             notes: _orders[index].notes,
           );
           _orders[index] = updatedOrder;
        }
         // If using filters, the accepted order might disappear from 'pending'
         // Decide whether to refetch or just update the list locally
         if (_currentFilter == OrderStatusFilter.pending) {
           _orders.removeWhere((o) => o.id == orderId);
         }
      } else {
         _errorMessage = 'Failed to accept order $orderId';
      }
    } catch (e) {
      _errorMessage = 'Error accepting order: $e';
      print('Error in OrderProvider acceptOrder: $e');
      success = false;
    } finally {
      _setUpdatingOrder(false);
      notifyListeners(); // Notify state changed (order update or error)
    }
     return success;
  }

  Future<bool> _updateOrder(String orderId, Future<void> Function(String) serviceCall) async {
    _setUpdatingOrder(true);
    String? previousError = _errorMessage;
    _errorMessage = null;
    // Optionally notify listeners here if you want the general state to change during individual updates
    // _setState(OrderListState.loading); 

    try {
      await serviceCall(orderId);

      // Find the updated order and change its status locally
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        // Determine the new status based on the action
        // This is a simplification; ideally, the API response confirms the new status
        OrderStatus newStatus;
        if (serviceCall == _orderService.acceptOrder) {
            newStatus = OrderStatus.accepted;
        } else if (serviceCall == _orderService.rejectOrder) {
            newStatus = OrderStatus.rejected;
        } else if (serviceCall == _orderService.markOrderReady) {
            newStatus = OrderStatus.ready_for_pickup;
        } else {
           newStatus = _orders[index].status; // Should not happen
        }

        // Create a new Order object with the updated status
        _orders[index] = _orders[index].copyWith(status: newStatus);

        // If the current filter doesn't match the new status, remove it from the list
        // (except for the 'All' filter)
        bool matchesFilter = false;
        switch (_currentFilter) {
           case OrderStatusFilter.pending: matchesFilter = newStatus == OrderStatus.pending; break;
           case OrderStatusFilter.accepted: // Treat accepted and preparing similarly for filtering
           case OrderStatusFilter.preparing: matchesFilter = newStatus == OrderStatus.accepted || newStatus == OrderStatus.preparing; break;
           case OrderStatusFilter.ready_for_pickup: matchesFilter = newStatus == OrderStatus.ready_for_pickup; break;
           case OrderStatusFilter.all: matchesFilter = true; break; // Always show in 'All'
        }

        if (!matchesFilter) {
             _orders.removeAt(index);
        }

      } else {
          // If the order wasn't found (shouldn't happen often), refetch
          fetchOrders(filter: _currentFilter); 
      }

      _errorMessage = null;
      _setUpdatingOrder(false);
      notifyListeners(); // Notify state changed (order update or error)
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setUpdatingOrder(false);
      // Optionally restore previous general state if needed
      // _setState(OrderListState.error); // Or keep previous loaded state?
       notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId) async {
    return await _updateOrder(orderId, _orderService.rejectOrder);
  }

  Future<bool> markOrderReady(String orderId) async {
    return await _updateOrder(orderId, _orderService.markOrderReady);
  }
}
