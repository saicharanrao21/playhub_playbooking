import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FacilityMediaParams {
  final String venueId;
  final String facilityId;
  FacilityMediaParams(this.venueId, this.facilityId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacilityMediaParams &&
          runtimeType == other.runtimeType &&
          venueId == other.venueId &&
          facilityId == other.facilityId;

  @override
  int get hashCode => venueId.hashCode ^ facilityId.hashCode;
}

final facilityMediaProvider = FutureProvider.family<List<Media>, FacilityMediaParams>((ref, params) async {
  final repo = ref.watch(venueOperatorRepositoryProvider);
  final facility = await repo.getFacility(params.venueId, params.facilityId);
  return facility?.media ?? [];
});

class FacilityMediaScreen extends ConsumerWidget {
  final String venueId;
  final String facilityId;
  const FacilityMediaScreen({super.key, required this.venueId, required this.facilityId});

  Future<void> _uploadImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final repo = ref.read(mediaRepositoryProvider);
      final success = await repo.uploadFacilityImage(facilityId, File(image.path));
      if (success != null) {
        ref.invalidate(facilityMediaProvider(FacilityMediaParams(venueId, facilityId)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = FacilityMediaParams(venueId, facilityId);
    final mediaAsync = ref.watch(facilityMediaProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _uploadImage(context, ref),
          ),
        ],
      ),
      body: mediaAsync.when(
        data: (media) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: media.length,
          itemBuilder: (context, index) {
            final item = media[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(item.url, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                       await ref.read(mediaRepositoryProvider).deleteMedia(item.id);
                       ref.invalidate(facilityMediaProvider(params));
                    },
                  ),
                ),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
