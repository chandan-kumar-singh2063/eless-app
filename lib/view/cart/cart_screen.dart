import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/controller/cart_controller.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/cart/components/cart_card.dart';
import 'package:eless/view/cart/components/cart_loading_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh cart when screen opens (with error handling)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    try {
      await CartController.instance.refreshCart();
    } catch (e) {
      // Show error snackbar if cart fails to load
      Get.snackbar(
        'Error',
        'Failed to load your requests. Pull down to retry.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'My Requests',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Summary badge
                  Obx(() {
                    final total = CartController.instance.totalRequests.value;
                    if (total > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightPrimaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox(width: 48);
                  }),
                ],
              ),
            ),

            // Cart List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCart,
                color: AppTheme.lightPrimaryColor,
                child: Obx(() {
                  final controller = CartController.instance;

                  // ⚡ Optimistic UI: Show shimmer ONLY when truly empty
                  // During refresh, keep showing existing data (Instagram pattern)
                  if (controller.cartList.isEmpty) {
                    // Show shimmer only during initial load, not refresh
                    if (controller.isCartLoading.value) {
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            const CartLoadingCard(),
                      );
                    }
                    return _buildEmptyState();
                  }

                  // ⚡ Optimized: Use CustomScrollView with SliverList
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    cacheExtent: 500, // Preload 500px for smooth scrolling
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return CartCard(
                              cartItem: controller.cartList[index],
                            );
                          },
                          childCount: controller.cartList.length,
                          addAutomaticKeepAlives: false, // Save memory
                          addRepaintBoundaries: true,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No device requests yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your requested devices will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _loadCart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightPrimaryColor,
                    side: BorderSide(color: AppTheme.lightPrimaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
