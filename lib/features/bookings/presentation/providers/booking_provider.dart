import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/booking_models.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authStateProvider);
  final orgId = authState.identity != null ? 'default-org-id' : 'default-org-id'; 
  return BookingRepository(apiClient, orgId);
});

final myBookingsProvider = StateNotifierProvider<MyBookingsNotifier, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return MyBookingsNotifier(repository);
});

class MyBookingsNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingRepository _repository;

  MyBookingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _repository.getMyBookings();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      await _repository.cancelBooking(id);
      await loadBookings(); 
    } catch (e) {
      // Log error
    }
  }
}

final createBookingProvider = StateProvider<BookingCreationState>((ref) => const BookingCreationState());

class BookingCreationState {
  final bool isLoading;
  final String? error;
  final Booking? createdBooking;

  const BookingCreationState({
    this.isLoading = false,
    this.error,
    this.createdBooking,
  });

  BookingCreationState copyWith({
    bool? isLoading,
    String? error,
    Booking? createdBooking,
  }) {
    return BookingCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }
}
