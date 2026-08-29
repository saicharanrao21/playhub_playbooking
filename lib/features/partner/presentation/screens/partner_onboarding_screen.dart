import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/security/auth_provider.dart';
import '../providers/partner_providers.dart';

class PartnerOnboardingScreen extends ConsumerStatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  ConsumerState<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends ConsumerState<PartnerOnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();

  // Controllers
  final _orgNameController = TextEditingController(text: 'Skyline Sports Hub');
  final _legalNameController = TextEditingController(text: 'Skyline Sports Ventures Pvt Ltd');
  final _displayNameController = TextEditingController(text: 'Skyline Arena');

  final _addressController = TextEditingController(text: 'Plot 42, Hitech City Main Road');
  final _cityController = TextEditingController(text: 'Hyderabad');
  final _stateController = TextEditingController(text: 'Telangana');
  final _postalCodeController = TextEditingController(text: '500081');

  final _panController = TextEditingController(text: 'ABCDE1234F');
  final _gstController = TextEditingController(text: '36ABCDE1234F1Z5');

  final _accountHolderController = TextEditingController(text: 'Skyline Sports Ventures');
  final _accountNumberController = TextEditingController(text: '98765432101234');
  final _ifscController = TextEditingController(text: 'HDFC0001234');
  final _bankNameController = TextEditingController(text: 'HDFC Bank');

  @override
  void dispose() {
    _orgNameController.dispose();
    _legalNameController.dispose();
    _displayNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey4.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = OnboardPartnerRequest(
        organizationName: _orgNameController.text.trim(),
        legalName: _legalNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        panNumber: _panController.text.trim(),
        gstNumber: _gstController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        bankName: _bankNameController.text.trim(),
      );

      final repo = ref.read(partnerRepositoryProvider);
      final org = await repo.onboardPartner(request);

      // Select active organization
      ref.read(selectedPartnerOrgIdProvider.notifier).state = org.id;
      ref.read(activeOrganizationProvider.notifier).selectOrganization(org.id);

      // Refresh memberships
      ref.invalidate(myPartnerOrganizationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Partner onboarding successful! Welcome to PlayHub Business.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/partner/workspace');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Onboarding failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Onboarding & KYC', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_formKey1.currentState!.validate()) setState(() => _currentStep += 1);
          } else if (_currentStep == 1) {
            if (_formKey2.currentState!.validate()) setState(() => _currentStep += 1);
          } else if (_currentStep == 2) {
            if (_formKey3.currentState!.validate()) setState(() => _currentStep += 1);
          } else if (_currentStep == 3) {
            _submitOnboarding();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            context.pop();
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _currentStep == 3 ? 'Complete Registration & KYC' : 'Next Step',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Business Identity
          Step(
            title: const Text('Business Identity', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Organization & brand details'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey1,
              child: Column(
                children: [
                  TextFormField(
                    controller: _orgNameController,
                    decoration: const InputDecoration(
                      labelText: 'Organization / Club Name *',
                      hintText: 'e.g. Skyline Sports Hub',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _legalNameController,
                    decoration: const InputDecoration(
                      labelText: 'Registered Legal Entity Name *',
                      hintText: 'e.g. Skyline Sports Ventures Pvt Ltd',
                      prefixIcon: Icon(Icons.gavel),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Public Display Name (Visible on App) *',
                      hintText: 'e.g. Skyline Arena',
                      prefixIcon: Icon(Icons.storefront),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),

          // Step 2: Physical Location
          Step(
            title: const Text('Location & Address', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Operating address'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey2,
              child: Column(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address *',
                      hintText: 'e.g. Plot 42, Hitech City Main Road',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            prefixIcon: Icon(Icons.map),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN / Postal Code *',
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                    validator: (v) => v == null || v.trim().length < 6 ? 'Enter 6-digit PIN' : null,
                  ),
                ],
              ),
            ),
          ),

          // Step 3: Tax & KYC
          Step(
            title: const Text('Tax & Business KYC', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('PAN & GSTIN verification'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey3,
              child: Column(
                children: [
                  TextFormField(
                    controller: _panController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Business / Proprietor PAN *',
                      hintText: 'e.g. ABCDE1234F',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-character PAN' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _gstController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (Optional if turnover < ₹20L)',
                      hintText: 'e.g. 36ABCDE1234F1Z5',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Step 4: Banking & Payouts
          Step(
            title: const Text('Bank & Payouts', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Direct settlement account'),
            isActive: _currentStep >= 3,
            state: _currentStep == 3 ? StepState.indexed : StepState.complete,
            content: Form(
              key: _formKey4,
              child: Column(
                children: [
                  TextFormField(
                    controller: _accountHolderController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bank Account Number *',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (v) => v == null || v.trim().length < 8 ? 'Enter valid account number' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'IFSC Code *',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (v) => v == null || v.trim().length < 11 ? '11-digit IFSC' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(
                            labelText: 'Bank Name *',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
