import 'package:get/get.dart';
import '../model/cart_item.dart';
import '../service/remote_service/cart_service.dart';
import 'auth_controller.dart';

class CartController extends GetxController {
  static CartController instance = Get.find();

  final CartService _cartService = CartService();

  // Observable variables
  RxList<CartItem> cartList = <CartItem>[].obs;
  RxBool isCartLoading = false.obs;
  RxBool isRefreshing = false.obs; // Silent background refresh flag
  RxBool isInitialized = false.obs;

  // ⚡ Performance: In-memory cache to avoid repeated API calls
  List<CartItem>? _cachedCartItems;
  DateTime? _lastFetch;

  // Cart summary counts
  RxInt totalRequests = 0.obs;
  RxInt pendingCount = 0.obs;
  RxInt approvedCount = 0.obs;
  RxInt rejectedCount = 0.obs;
  RxInt returnedCount = 0.obs;
  RxInt overdueCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
    _listenToAuthChanges();
  }

  Future<void> _initialize() async {
    try {
      // Only load cart for logged-in users
      if (AuthController.instance.isLoggedIn) {
        await loadCart();
      } else {}
      isInitialized(true);
    } catch (e) {
      isInitialized(true); // Still mark as initialized to prevent loops
    }
  }

  /// Listen to auth state changes
  void _listenToAuthChanges() {
    // Watch for login/logout events
    ever(AuthController.instance.user, (user) {
      if (user != null) {
        // User just logged in - load cart
        loadCart();
      } else {
        // User just logged out - clear cart
        clearCart();
      }
    });
  }

  Future<void> loadCart({bool showError = false}) async {
    // Only logged-in users can have cart items
    if (!AuthController.instance.isLoggedIn) {
      clearCart();
      return;
    }

    final userUniqueId = AuthController.instance.user.value?.id;
    if (userUniqueId == null || userUniqueId.isEmpty) {
      clearCart();
      return;
    }

    // ⚡ Load from memory cache first (instant)
    if (_cachedCartItems != null && _lastFetch != null) {
      final cacheAge = DateTime.now().difference(_lastFetch!);
      if (cacheAge.inMinutes < 5) {
        cartList.assignAll(_cachedCartItems!);
        _updateCounts();
        return; // Use cache if < 5 minutes old
      }
    }

    try {
      isCartLoading(true);

      final items = await _cartService.getUserDeviceRequests(
        userUniqueId: userUniqueId,
      );

      // ⚡ Update memory cache
      _cachedCartItems = List.from(items);
      _lastFetch = DateTime.now();

      cartList.assignAll(items);

      // Update counts
      _updateCounts();
    } catch (e) {
      // Show error to user if requested
      if (showError) {
        Get.snackbar(
          'Cart Error',
          'Failed to load your requests. Pull to refresh.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      isCartLoading(false);
    }
  }

  Future<void> refreshCart() async {
    if (!AuthController.instance.isLoggedIn) {
      return;
    }

    // ⚡ Optimistic silent refresh (Instagram pattern)
    final userUniqueId = AuthController.instance.user.value?.id;
    if (userUniqueId == null || userUniqueId.isEmpty) {
      return;
    }

    try {
      isRefreshing(true);

      // Keep showing cached data while fetching
      final items = await _cartService.getUserDeviceRequests(
        userUniqueId: userUniqueId,
      );

      // ⚡ Update memory cache
      _cachedCartItems = List.from(items);
      _lastFetch = DateTime.now();

      cartList.assignAll(items);
      _updateCounts();
    } catch (e) {
      // Silent fail - old data stays visible
    } finally {
      isRefreshing(false);
    }
  }

  void _updateCounts() {
    totalRequests.value = cartList.length;
    pendingCount.value = cartList.where((item) => item.isPending).length;
    approvedCount.value = cartList.where((item) => item.isApproved).length;
    rejectedCount.value = cartList.where((item) => item.isRejected).length;
    returnedCount.value = cartList.where((item) => item.isReturned).length;
    overdueCount.value = cartList.where((item) => item.isOverdueStatus).length;
  }

  // Get cart items by status
  List<CartItem> get pendingItems =>
      cartList.where((item) => item.isPending).toList();

  List<CartItem> get approvedItems =>
      cartList.where((item) => item.isApproved).toList();

  List<CartItem> get rejectedItems =>
      cartList.where((item) => item.isRejected).toList();

  List<CartItem> get returnedItems =>
      cartList.where((item) => item.isReturned).toList();

  List<CartItem> get overdueItems =>
      cartList.where((item) => item.isOverdueStatus).toList();

  // Badge count (show pending + approved on-service items, exclude returned/overdue)
  int get badgeCount {
    final pending = pendingCount.value;
    final onService = cartList
        .where((item) => item.isApproved && item.isOnService)
        .length;
    return pending + onService;
  }

  void clearCart() {
    cartList.clear();
    totalRequests.value = 0;
    pendingCount.value = 0;
    approvedCount.value = 0;
    rejectedCount.value = 0;
    returnedCount.value = 0;
    overdueCount.value = 0;

    // ⚡ Clear memory cache
    _cachedCartItems = null;
    _lastFetch = null;
  }
}
