import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/app_models.dart';
import '../../data/tournament_repository.dart';
import '../../../../shared/components/loading_indicator.dart';
import '../../../../shared/components/error_view.dart';

class TournamentDetailsScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailsScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends ConsumerState<TournamentDetailsScreen> {
  void _openRegisterModal(TournamentItem tournament) {
    final formKey = GlobalKey<FormState>();
    final teamNameController = TextEditingController();
    final captainNameController = TextEditingController();
    final phoneController = TextEditingController();
    int playerCount = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Team',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  tournament.title,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: teamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name *',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter team name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: captainNameController,
                  decoration: const InputDecoration(
                    labelText: 'Captain Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter captain name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid phone number' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Players', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: playerCount > 2
                              ? () => setModalState(() => playerCount--)
                              : null,
                        ),
                        Text('$playerCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: playerCount < 15
                              ? () => setModalState(() => playerCount++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx);

                      final repo = ref.read(tournamentRepositoryProvider);
                      final success = await repo.registerTeam(
                        tournamentId: tournament.id,
                        teamName: teamNameController.text.trim(),
                        captainName: captainNameController.text.trim(),
                        contactNumber: phoneController.text.trim(),
                        playerCount: playerCount,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Team "${teamNameController.text.trim()}" successfully registered!'
                                  : 'Registration failed. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('Confirm & Pay ₹${tournament.entryFee.toInt()} Entry Fee'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.watch(tournamentRepositoryProvider);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return FutureBuilder<TournamentItem?>(
      future: repo.getTournamentById(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tournament Details')),
            body: const Center(child: AppLoadingIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tournament Details')),
            body: AppErrorView(
              message: 'Tournament not found or failed to load.',
              onRetry: () => setState(() {}),
            ),
          );
        }

        final tournament = snapshot.data!;
        final progress = tournament.maxTeams > 0
            ? tournament.registeredTeams / tournament.maxTeams
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(tournament.sport, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tournament invitation link copied!')),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tournament.format.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Prize: ₹${tournament.prizePool.toInt()}',
                            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tournament.title,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${tournament.venueName}, ${tournament.location}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overview Key Specs
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSpecRow(
                        context,
                        icon: Icons.calendar_month,
                        title: 'Dates',
                        value: '${dateFormat.format(tournament.startDate)} to ${dateFormat.format(tournament.endDate)}',
                      ),
                      const Divider(height: 20),
                      _buildSpecRow(
                        context,
                        icon: Icons.payments_outlined,
                        title: 'Team Entry Fee',
                        value: '₹${tournament.entryFee.toInt()}',
                      ),
                      const Divider(height: 20),
                      _buildSpecRow(
                        context,
                        icon: Icons.groups,
                        title: 'Team Capacity',
                        value: '${tournament.registeredTeams} of ${tournament.maxTeams} Teams Registered',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text('About this Tournament', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                tournament.description,
                style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
              ),

              const SizedBox(height: 20),

              // Rules
              Text('Tournament Rules & Guidelines', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tournament.rules.map((rule) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(rule, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
          bottomNavigationBar: Container(
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
              child: ElevatedButton(
                onPressed: progress >= 1.0 ? null : () => _openRegisterModal(tournament),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  progress >= 1.0
                      ? 'Registration Full'
                      : 'Register Team (₹${tournament.entryFee.toInt()})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      },
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
