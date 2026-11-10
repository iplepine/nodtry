import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/analytics.dart';

String _iapString(String key, [Object? arg]) {
  final locale =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final isKo = locale.startsWith('ko');
  switch (key) {
    case 'purchaseRequestFailed':
      return isKo ? '결제 요청 실패: $arg' : 'Purchase request failed: $arg';
    case 'unknownError':
      return isKo ? '알 수 없는 오류' : 'Unknown error';
    case 'productUnavailable':
      return isKo
          ? '지금은 후원 상품을 불러올 수 없어요. 잠시 후 다시 시도해 주세요.'
          : "The tip isn't available right now. Please try again later.";
    default:
      return key;
  }
}

class IAPState {
  final bool isAvailable;
  final bool isPurchasing;
  final String? purchaseError;
  final List<ProductDetails> products;

  /// Bumped once per completed tip, so the UI can thank the user exactly once.
  final int completedCount;

  const IAPState({
    this.isAvailable = false,
    this.isPurchasing = false,
    this.purchaseError,
    this.products = const [],
    this.completedCount = 0,
  });

  IAPState copyWith({
    bool? isAvailable,
    bool? isPurchasing,
    String? purchaseError,
    List<ProductDetails>? products,
    int? completedCount,
    bool clearError = false,
  }) {
    return IAPState(
      isAvailable: isAvailable ?? this.isAvailable,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseError: clearError ? null : (purchaseError ?? this.purchaseError),
      products: products ?? this.products,
      completedCount: completedCount ?? this.completedCount,
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
    final ProductDetailsResponse response;
    try {
      response = await _iap.queryProductDetails(kIds);
    } catch (e) {
      debugPrint('IAP queryProductDetails failed: $e');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    state = state.copyWith(
      products: List<ProductDetails>.from(response.productDetails),
    );
  }

  Future<void> buyCoffee() async {
    // 상품이 아직 안 불러와졌으면(네트워크 지연·첫 실행) 한 번 더 시도한다.
    if (state.products.isEmpty) await _loadProducts();
    if (state.products.isEmpty) {
      state = state.copyWith(purchaseError: _iapString('productUnavailable'));
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

    AnalyticsService.log(AnalyticsEvent.donationInitiated, {
      'product_id': product.id,
    });

    try {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
      // Result handled in stream
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        purchaseError: _iapString('purchaseRequestFailed', e),
      );
    }
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(isPurchasing: true, clearError: true);
          continue; // not finished yet — never complete a pending purchase
        case PurchaseStatus.canceled:
          state = state.copyWith(isPurchasing: false, clearError: true);
        case PurchaseStatus.error:
          AnalyticsService.log(AnalyticsEvent.purchaseFailed, {
            'reason': purchaseDetails.error?.code ?? 'unknown',
          });
          state = state.copyWith(
            isPurchasing: false,
            purchaseError:
                purchaseDetails.error?.message ?? _iapString('unknownError'),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final product = state.coffeeProduct;
          AnalyticsService.logPurchase(
            value: product?.rawPrice ?? 0,
            currency: product?.currencyCode ?? 'KRW',
            itemId: purchaseDetails.productID,
          );
          state = state.copyWith(
            isPurchasing: false,
            clearError: true,
            completedCount: state.completedCount + 1,
          );
      }
      // Finish every non-pending transaction (including canceled/error on
      // iOS), or StoreKit keeps redelivering it and Play refunds it.
      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchaseDetails);
        } catch (e) {
          debugPrint('IAP completePurchase failed: $e');
        }
      }
    }
  }
}
