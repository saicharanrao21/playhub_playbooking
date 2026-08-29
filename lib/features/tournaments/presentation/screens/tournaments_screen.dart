import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/app_models.dart';
import '../../data/tournament_repository.dart';
import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/components/empty_view.dart';
import '../../../../shared/components/error_view.dart';

class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tournamentsAsync = ref.watch(tournamentsListProvider);
    final selectedSport = ref.watch(tournamentsFilterSportProvider);

    final sports = ['All', 'Cricket', 'Football', 'Badminton', 'Tennis'];

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
        title: const Text('Tournaments & Leagues', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(tournamentsListProvider.future),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: sports.map((sport) {
                final isSelected = selectedSport == sport;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(tournamentsFilterSportProvider.notifier).state = sport;
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tournaments List
          Expanded(
            child: tournamentsAsync.when(
              data: (tournaments) {
                if (tournaments.isEmpty) {
                  return const EmptyView(
                    icon: Icons.emoji_events_outlined,
                    title: 'No Tournaments Found',
                    message: 'Check back soon or explore other sport categories.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(tournamentsListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tournaments.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = tournaments[index];
                      return _TournamentCard(tournament: item);
                    },
                  ),
                );
              },
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SkeletonCard(height: 220),
                  SizedBox(height: 16),
                  SkeletonCard(height: 220),
                ],
              ),
              error: (err, _) => AppErrorView(
                message: 'Failed to load tournaments: $err',
                onRetry: () => ref.refresh(tournamentsListProvider.future),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final TournamentItem tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d');
    final progress = tournament.maxTeams > 0
        ? tournament.registeredTeams / tournament.maxTeams
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tournament/${tournament.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Sport & Prize Pool
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tournament.sport.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Prize ₹${tournament.prizePool.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                tournament.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Venue and Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${tournament.venueName}, ${tournament.location}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Date and Format
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(tournament.startDate)} - ${dateFormat.format(tournament.endDate)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.sports, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    tournament.format,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Registration Progress Bar & Actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Teams Registered',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              '${tournament.registeredTeams} / ${tournament.maxTeams}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? Colors.red : colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/tournament/${tournament.id}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('₹${tournament.entryFee.toInt()} Entry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
