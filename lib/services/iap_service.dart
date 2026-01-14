import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPState {
  final bool isAvailable;
  final bool isPurchasing;
  final String? purchaseError;
  final List<ProductDetails> products;

  const IAPState({
    this.isAvailable = false,
    this.isPurchasing = false,
    this.purchaseError,
    this.products = const [],
  });

  IAPState copyWith({
    bool? isAvailable,
    bool? isPurchasing,
    String? purchaseError,
    List<ProductDetails>? products,
    bool clearError = false,
  }) {
    return IAPState(
      isAvailable: isAvailable ?? this.isAvailable,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseError: clearError ? null : (purchaseError ?? this.purchaseError),
      products: products ?? this.products,
    );
  }

  ProductDetails? get coffeeProduct => products.firstOrNull;
}

class IAPService extends Notifier<IAPState> {
  static const String _coffeeProductId = 'donation_coffee';
  late final InAppPurchase _iap;
  StreamSubscription? _subscription;

  @override
  IAPState build() {
    _iap = InAppPurchase.instance;
    _init(); // Fire and forget implementation

    // Dispose subscription when the notifier is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const IAPState();
  }

  Future<void> _init() async {
    final available = await _iap.isAvailable();
    state = state.copyWith(isAvailable: available);

    if (available) {
      _subscription = _iap.purchaseStream.listen(
        _listenToPurchaseUpdated,
        onError: (error) {
          debugPrint('IAP Stream Error: $error');
        },
      );
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final Set<String> kIds = {_coffeeProductId};
    final response = await _iap.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    state = state.copyWith(
      products: List<ProductDetails>.from(response.productDetails),
    );
  }

  Future<void> buyCoffee() async {
    // 상품 확인
    if (state.products.isEmpty) {
      state = state.copyWith(purchaseError: 'Thank you for your support!');
      debugPrint('IAP Error: No products loaded.');
      return;
    }

    final product = state.products.firstWhere(
      (p) => p.id == _coffeeProductId,
      orElse: () => state.products.first,
    );

    if (product.id != _coffeeProductId) {
      debugPrint(
        'Warning: Requested $_coffeeProductId but found ${product.id}',
      );
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    state = state.copyWith(isPurchasing: true, clearError: true);

    try {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
      // Result handled in stream
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        purchaseError: '결제 요청 실패: $e',
      );
    }
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        state = state.copyWith(isPurchasing: true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          state = state.copyWith(
            isPurchasing: false,
            purchaseError: purchaseDetails.error?.message ?? '알 수 없는 오류',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Acknowledgement / Consuming
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }

          state = state.copyWith(isPurchasing: false, clearError: true);
        }
      }
    }
  }
}
