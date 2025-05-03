import 'package:flutter/material.dart';
import 'package:foodondoor_vendor_app/src/features/order_model.dart';
import 'package:foodondoor_vendor_app/src/features/order_provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';

class OrderListScreen extends StatefulWidget {
  static const routeName = '/orders';
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const <Tab>[
    Tab(text: 'Pending'),
    Tab(text: 'Accepted'), // Combine Accepted & Preparing?
    Tab(text: 'Ready'),
    Tab(text: 'All'),      // Optional: Show all others
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(_handleTabSelection);
    // Fetch initial orders based on the default tab (Pending)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrders(filter: OrderStatusFilter.pending);
    });
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      switch (_tabController.index) {
        case 0: provider.fetchOrders(filter: OrderStatusFilter.pending); break;
        case 1: provider.fetchOrders(filter: OrderStatusFilter.accepted); break;
        case 2: provider.fetchOrders(filter: OrderStatusFilter.ready_for_pickup); break;
        case 3: provider.fetchOrders(filter: OrderStatusFilter.all); break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Colors.white,
        ),
         actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () {
               Provider.of<OrderProvider>(context, listen: false).fetchOrders();
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.state == OrderListState.loading && !provider.isUpdatingOrder) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == OrderListState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage ?? 'Failed to load orders.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => provider.fetchOrders(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.orders.isEmpty && provider.state == OrderListState.loaded) {
            return const Center(child: Text('No orders found in this category.'));
          }

          return Stack(
             children: [
                ListView.builder(
                  itemCount: provider.orders.length,
                  itemBuilder: (context, index) {
                    final order = provider.orders[index];
                    return _buildOrderCard(context, order, provider);
                  },
                ),
                // Show loading indicator for individual order updates
                if (provider.isUpdatingOrder)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
             ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, OrderProvider provider) {
     final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹'); // Or your local currency
     final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 6)}...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                 Text(
                  currencyFormat.format(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
              ],
            ),
             const SizedBox(height: 6),
             Text('Status: ${orderStatusToString(order.status).toUpperCase()}'),
             Text('Placed: ${dateFormat.format(order.createdAt.toLocal())}'),
             Text('Customer: ${order.customer.name}'),
             if (order.customer.phoneNumber != null && order.customer.phoneNumber!.isNotEmpty)
              Text('Phone: ${order.customer.phoneNumber}'), // Use \$ for interpolation
             if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
               Text('Address: ${order.deliveryAddress}'), // Use \$ for interpolation
             if (order.notes != null && order.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Notes: ${order.notes}', style: const TextStyle(fontStyle: FontStyle.italic)), // Use \$
                ),
            const Divider(height: 20),
            Text('Items (${order.items.length}):', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
              child: Text('- ${item.quantity} x ${item.name} (${currencyFormat.format(item.price)})'), // Use \$
            )),
            const SizedBox(height: 12),
            _buildActionButtons(context, order, provider),
          ],
        ),
      ),
    );
  }

 Widget _buildActionButtons(BuildContext context, Order order, OrderProvider provider) {
  List<Widget> buttons = [];

  switch (order.status) {
    case OrderStatus.pending:
      buttons.addAll([
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(100, 36)),
          onPressed: provider.isUpdatingOrder ? null : () async {
             final success = await provider.acceptOrder(order.id);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage ?? 'Failed to accept order.'), backgroundColor: Colors.red),
                );
              }
          },
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Reject'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(100, 36)),
          onPressed: provider.isUpdatingOrder ? null : () async {
              final success = await provider.rejectOrder(order.id);
               if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage ?? 'Failed to reject order.'), backgroundColor: Colors.red),
                );
              }
          },
        ),
      ]);
      break;
    case OrderStatus.accepted:
    case OrderStatus.preparing:
      buttons.add(
        ElevatedButton.icon(
           icon: const Icon(Icons.restaurant_menu, size: 18),
          label: const Text('Mark Ready'),
           style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(140, 36)),
           onPressed: provider.isUpdatingOrder ? null : () async {
              final success = await provider.markOrderReady(order.id);
               if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage ?? 'Failed to mark order ready.'), backgroundColor: Colors.red),
                );
              }
           },
        ),
      );
      break;
    // Add cases for other statuses if actions are needed (e.g., view details)
    default:
      // No actions for ready_for_pickup, delivered, cancelled, rejected etc. by default
      break;
  }

  // Return a row or wrap based on available space/number of buttons
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: buttons,
  );
}


}
