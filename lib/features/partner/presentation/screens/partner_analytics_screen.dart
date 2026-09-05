import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';
import '../providers/partner_analytics_provider.dart';

class PartnerAnalyticsScreen extends ConsumerStatefulWidget {
  const PartnerAnalyticsScreen({super.key});

  @override
  ConsumerState<PartnerAnalyticsScreen> createState() => _PartnerAnalyticsScreenState();
}

class _PartnerAnalyticsScreenState extends ConsumerState<PartnerAnalyticsScreen> {
  String _selectedPreset = 'LAST_30_DAYS';

  Future<void> _exportCsv() async {
    final orgId = ref.read(activeOrganizationProvider);
    if (orgId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.post(
      '/organizations/$orgId/analytics/exports/csv',
      data: {'reportType': 'BOOKINGS', 'format': 'CSV', 'preset': _selectedPreset},
    );

    if (mounted) {
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 CSV Booking Report generated & exported!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export CSV report.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _requestPdfReport() async {
    final orgId = ref.read(activeOrganizationProvider);
    if (orgId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.post(
      '/organizations/$orgId/analytics/reports/pdf',
      data: {'reportType': 'VENUE_PERFORMANCE', 'format': 'PDF', 'preset': _selectedPreset},
    );

    if (mounted) {
      if (response.isSuccess) {
        final jobId = response.data?['reportJobId'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📄 PDF Performance Report job queued! (ID: #${jobId?.substring(0, 8)})'), backgroundColor: Colors.blue),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request PDF report.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(partnerAnalyticsProvider(_selectedPreset));
    final peakTimesAsync = ref.watch(partnerPeakTimesProvider(_selectedPreset));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Business Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Request PDF',
            onPressed: _requestPdfReport,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnerAnalyticsProvider(_selectedPreset));
          ref.invalidate(partnerPeakTimesProvider(_selectedPreset));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Filter Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date Preset:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  DropdownButton<String>(
                    value: _selectedPreset,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'TODAY', child: Text('Today')),
                      DropdownMenuItem(value: 'LAST_7_DAYS', child: Text('Last 7 Days')),
                      DropdownMenuItem(value: 'LAST_30_DAYS', child: Text('Last 30 Days')),
                      DropdownMenuItem(value: 'THIS_MONTH', child: Text('This Month')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPreset = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Metric Cards
              analyticsAsync.when(
                data: (data) {
                  if (data == null) return const SizedBox.shrink();
                  final rev = data['revenue'] ?? {};
                  final b = data['bookings'] ?? {};
                  final cust = data['customers'] ?? {};

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              'Net Revenue',
                              '₹${rev['netRevenue'] ?? 0}',
                              'Gross: ₹${rev['grossRevenue'] ?? 0}',
                              Colors.green,
                              Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              'Total Bookings',
                              '${b['totalBookings'] ?? 0}',
                              '${b['bookingGrowthPercent'] ?? 0}% vs prev period',
                              Colors.indigo,
                              Icons.calendar_month_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              'Cancellation Rate',
                              '${b['cancellationRate'] ?? 0}%',
                              '${b['cancelledBookings'] ?? 0} cancelled',
                              Colors.orange,
                              Icons.cancel_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              'Unique Customers',
                              '${cust['uniqueCustomers'] ?? 0}',
                              'Active players',
                              Colors.teal,
                              Icons.people_outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error loading analytics: $e'),
              ),

              const SizedBox(height: 28),
              Text('7x24 Peak-Time Court Booking Heatmap', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Darker green indicates peak court booking hours', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),

              // Peak Times Grid Heatmap
              peakTimesAsync.when(
                data: (data) {
                  final grid = (data?['heatmapGrid'] as List?) ?? [];
                  if (grid.isEmpty) return const SizedBox.shrink();

                  final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: List.generate(7, (dIdx) {
                        final hoursRow = (grid[dIdx] as List?) ?? [];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(days[dIdx], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              Expanded(
                                child: Row(
                                  children: List.generate(24, (hIdx) {
                                    final cell = hoursRow.length > hIdx ? hoursRow[hIdx] : {};
                                    final count = cell['bookingCount'] ?? 0;
                                    final color = count == 0
                                        ? Colors.grey.shade200
                                        : (count == 1 ? Colors.green.shade200 : (count == 2 ? Colors.green.shade400 : Colors.green.shade700));

                                    return Expanded(
                                      child: Container(
                                        height: 18,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error loading heatmap: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
