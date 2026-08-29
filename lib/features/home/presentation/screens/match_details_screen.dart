import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/match_repository.dart';
import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/components/error_view.dart';

class MatchDetailsScreen extends ConsumerStatefulWidget {
  final String matchId;
  final MatchItem? match;

  const MatchDetailsScreen({
    super.key,
    required this.matchId,
    this.match,
  });

  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  bool _isJoining = false;

  Future<void> _joinMatch(MatchItem match) async {
    setState(() => _isJoining = true);
    final repo = ref.read(matchRepositoryProvider);
    try {
      final success = await repo.joinMatch(match.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully joined "${match.title}"!')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // If match passed in memory, use it; otherwise fetch from provider
    final matchesAsync = ref.watch(matchesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Match invite link copied!')),
              );
            },
          ),
        ],
      ),
      body: widget.match != null
          ? _buildContent(context, widget.match!, dateFormat, timeFormat)
          : matchesAsync.when(
              data: (list) {
                final match = list.firstWhere(
                  (m) => m.id == widget.matchId,
                  orElse: () => list.isNotEmpty ? list.first : widget.match!,
                );
                return _buildContent(context, match, dateFormat, timeFormat);
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (err, _) => AppErrorView(
                message: 'Failed to load match details: $err',
                onRetry: () => ref.refresh(matchesListProvider.future),
              ),
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MatchItem match,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = match.maxPlayers > 0
        ? match.currentPlayers / match.maxPlayers
        : 0.0;
    final isFull = match.currentPlayers >= match.maxPlayers;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Match Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primaryContainer, colorScheme.surfaceContainerHighest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            match.sport.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${match.pricePerPlayer.toInt()} / player',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      match.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${match.venueName}, ${match.location}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Match Logistics Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSpecRow(
                        context,
                        icon: Icons.calendar_month_outlined,
                        title: 'Date & Time',
                        value: '${dateFormat.format(match.startTime)} • ${timeFormat.format(match.startTime)}',
                      ),
                      const Divider(height: 20),
                      _buildSpecRow(
                        context,
                        icon: Icons.star_outline,
                        title: 'Skill Level',
                        value: match.skillLevel,
                      ),
                      const Divider(height: 20),
                      _buildSpecRow(
                        context,
                        icon: Icons.person_outline,
                        title: 'Host',
                        value: match.hostName,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Capacity & Players
              Text(
                'Players & Lineup',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Joined Players',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                          Text(
                            '${match.currentPlayers} of ${match.maxPlayers} Spots Filled',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFull ? Colors.red : colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Host item
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(match.hostName.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(match.hostName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Host & Organizer'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'HOST',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Match Guidelines
              Text(
                'Match Rules',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _RuleBullet(text: 'Please arrive 15 minutes before the scheduled kickoff.'),
                      SizedBox(height: 8),
                      _RuleBullet(text: 'Bring your own appropriate sports gear and footwear.'),
                      SizedBox(height: 8),
                      _RuleBullet(text: 'Maintain fair play, respect fellow players and venue staff.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),

        // Sticky Bottom Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isFull || match.isJoined || _isJoining)
                  ? null
                  : () => _joinMatch(match),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      match.isJoined
                          ? 'Already Joined'
                          : isFull
                              ? 'Match Full'
                              : 'Join Match (₹${match.pricePerPlayer.toInt()})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuleBullet extends StatelessWidget {
  final String text;

  const _RuleBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
