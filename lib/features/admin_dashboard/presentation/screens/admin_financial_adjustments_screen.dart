import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';

class AdminFinancialAdjustmentsScreen extends ConsumerStatefulWidget {
  const AdminFinancialAdjustmentsScreen({super.key});

  @override
  ConsumerState<AdminFinancialAdjustmentsScreen> createState() => _AdminFinancialAdjustmentsScreenState();
}

class _AdminFinancialAdjustmentsScreenState extends ConsumerState<AdminFinancialAdjustmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _direction = 'CREDIT';
  bool _isLoading = false;

  @override
  void dispose() {
    _orgIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/finance/adjustments',
        data: {
          'organizationId': _orgIdController.text.trim(),
          'amount': double.parse(_amountController.text),
          'direction': _direction,
          'reason': _reasonController.text.trim(),
        },
      );

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Governed adjustment issued successfully!'), backgroundColor: Colors.green),
          );
          _orgIdController.clear();
          _amountController.clear();
          _reasonController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Adjustment failed: ${response.statusMessage ?? "Failed to issue adjustment"}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Governed Financial Adjustments')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Issue Partner Adjustment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Adjustments create an immutable double-entry transaction and update the partner payable liability with audit tracking.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _orgIdController,
                decoration: const InputDecoration(
                  labelText: 'Target Organization ID *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Amount (₹) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _direction,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Direction *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CREDIT',
                    child: Text('CREDIT (Increase Partner Payable / Goodwill)'),
                  ),
                  DropdownMenuItem(
                    value: 'DEBIT',
                    child: Text('DEBIT (Deduct Partner Payable / Penalty)'),
                  ),
                ],
                onChanged: (val) => setState(() => _direction = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Audit Reason & Notes *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().length < 5 ? 'Reason required (min 5 chars)' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.gavel),
                  label: const Text('Issue Adjustment Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
