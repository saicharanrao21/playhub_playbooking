import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/core/models/app_models.dart';
import 'package:playhub_playbooking/core/repositories/match_repository.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';


class MatchDiscoveryScreen extends ConsumerWidget {
  const MatchDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final matchesAsync = ref.watch(matchesListProvider);
    final selectedSport = ref.watch(matchesFilterSportProvider);

    final sports = ['All', 'Football', 'Cricket', 'Badminton', 'Tennis', 'Basketball'];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Find Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
            onPressed: () {
              _showFilterBottomSheet(context, ref, sports);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search match, venue, or sport...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  onChanged: (val) {
                    ref.read(matchesSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              // Sports Horizontal Filter Chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: sports.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final sport = sports[index];
                    final isSelected = selectedSport.toLowerCase() == sport.toLowerCase();
                    return FilterChip(
                      selected: isSelected,
                      label: Text(sport),
                      onSelected: (val) {
                        ref.read(matchesFilterSportProvider.notifier).state = sport;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(matchesListProvider);
        },
        child: matchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return EmptyView(
                icon: Icons.sports_soccer_outlined,
                title: 'No matches found',
                message: 'Be the first to host a match in this category!',
                actionLabel: 'Host a Match',
                onAction: () => context.push('/host-match'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchCard(match: match);
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (c, i) => const SkeletonCard(height: 190),
          ),
          error: (err, stack) => AppErrorView(
            message: 'Failed to load matches: $err',
            onRetry: () => ref.invalidate(matchesListProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final hosted = await context.push<bool>('/host-match');
          if (hosted == true) {
            ref.invalidate(matchesListProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Host Match'),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref, List<String> sports) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Sport', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sports.map((sport) {
                  return ActionChip(
                    label: Text(sport),
                    onPressed: () {
                      ref.read(matchesFilterSportProvider.notifier).state = sport;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _MatchCard extends ConsumerStatefulWidget {
  final MatchItem match;

  const _MatchCard({required this.match});

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard> {
  bool _isJoining = false;

  Future<void> _joinMatch() async {
    setState(() => _isJoining = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      final success = await repo.joinMatch(widget.match.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully joined "${widget.match.title}"!')),
          );
          ref.invalidate(matchesListProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match is already full or unavailable.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final match = widget.match;
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final progress = match.maxPlayers > 0 ? (match.currentPlayers / match.maxPlayers).clamp(0.0, 1.0) : 0.0;
    final isFull = match.currentPlayers >= match.maxPlayers;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/match/${match.id}', extra: match),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sport Chip + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(match.sport, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '₹${match.pricePerPlayer.toInt()} / player',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              match.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            // Venue
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    match.venueName,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Time
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(match.startTime),
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Players Progress & Join CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Players', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '${match.currentPlayers} / ${match.maxPlayers} Joined',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFull ? Colors.orange.shade800 : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: (isFull || _isJoining) ? null : _joinMatch,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isFull ? 'Match Full' : 'Join Match'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              color: isFull ? Colors.orange : colorScheme.primary,
            ),
          ],
        ),
      ),
    ),
  );
}
}
