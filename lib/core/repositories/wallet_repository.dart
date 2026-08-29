import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/networking/api_client_interface.dart';
import '../models/app_models.dart';

abstract class WalletRepository {
  Future<WalletInfo> getWallet();
  Future<List<WalletTransactionItem>> getTransactions();
  Future<bool> addMoney(double amount);
}

class WalletRepositoryImpl implements WalletRepository {
  final IApiClient apiClient;

  WalletRepositoryImpl({required this.apiClient});

  double _balance = 2450.0;
  final List<WalletTransactionItem> _transactions = [
    WalletTransactionItem(
      id: 'tx_001',
      title: 'Added Money to Wallet',
      subtitle: 'UPI Transfer',
      amount: 1000.0,
      isCredit: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    WalletTransactionItem(
      id: 'tx_002',
      title: 'Booking Payment: Test Football Pitch',
      subtitle: 'Venue Booking',
      amount: 500.0,
      isCredit: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    WalletTransactionItem(
      id: 'tx_003',
      title: 'Cashback Reward',
      subtitle: 'Weekend Promotion',
      amount: 150.0,
      isCredit: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WalletTransactionItem(
      id: 'tx_004',
      title: 'Match Joining Fee',
      subtitle: 'Friendly T20 Match',
      amount: 200.0,
      isCredit: false,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  Future<WalletInfo> getWallet() async {
    try {
      final response = await apiClient.get('/wallet');
      if (response.isSuccess && response.data != null) {
        return WalletInfo(
          id: response.data['id'] ?? 'wallet_default',
          userId: response.data['userId'] ?? 'usr_current',
          balance: (response.data['balance'] as num?)?.toDouble() ?? _balance,
          currency: response.data['currency'] ?? 'INR',
        );
      }
    } catch (_) {}

    return WalletInfo(
      id: 'wallet_001',
      userId: 'usr_current',
      balance: _balance,
      currency: 'INR',
    );
  }

  @override
  Future<List<WalletTransactionItem>> getTransactions() async {
    try {
      final response = await apiClient.get('/wallet/transactions');
      if (response.isSuccess && response.data != null) {
        final list = (response.data as List).map((e) => WalletTransactionItem(
          id: e['id'],
          title: e['title'] ?? 'Transaction',
          subtitle: e['subtitle'] ?? '',
          amount: (e['amount'] as num).toDouble(),
          isCredit: e['type'] == 'credit',
          createdAt: DateTime.parse(e['createdAt']),
        )).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    return _transactions;
  }

  @override
  Future<bool> addMoney(double amount) async {
    try {
      final response = await apiClient.post('/wallet/topup', data: {'amount': amount});
      if (response.isSuccess) {
        _balance += amount;
        return true;
      }
    } catch (_) {}

    _balance += amount;
    _transactions.insert(0, WalletTransactionItem(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Added Money to Wallet',
      subtitle: 'Instant Top-Up',
      amount: amount,
      isCredit: true,
      createdAt: DateTime.now(),
    ));
    return true;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepositoryImpl(apiClient: apiClient);
});
