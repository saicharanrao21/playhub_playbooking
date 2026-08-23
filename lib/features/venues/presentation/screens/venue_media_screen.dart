import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

final venueMediaProvider = FutureProvider.family<List<Media>, String>((ref, id) async {
  final repo = ref.watch(venueOperatorRepositoryProvider);
  final venue = await repo.getVenue(id);
  return venue?.media ?? [];
});

class VenueMediaScreen extends ConsumerWidget {
  final String venueId;
  const VenueMediaScreen({super.key, required this.venueId});

  Future<void> _uploadImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final repo = ref.read(mediaRepositoryProvider);
      final success = await repo.uploadVenueImage(venueId, File(image.path));
      if (success != null) {
        ref.invalidate(venueMediaProvider(venueId));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(venueMediaProvider(venueId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Media'),
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
                       ref.invalidate(venueMediaProvider(venueId));
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
