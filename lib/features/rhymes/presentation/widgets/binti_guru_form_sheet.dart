import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/waitlist_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class BintiGuruFormSheet extends ConsumerStatefulWidget {
  const BintiGuruFormSheet({super.key});

  @override
  ConsumerState<BintiGuruFormSheet> createState() => _BintiGuruFormSheetState();
}

class _BintiGuruFormSheetState extends ConsumerState<BintiGuruFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCeremony = 'wedding';
  String _selectedState = 'Jharkhand';
  DateTime? _eventDate;
  bool _isSubmitting = false;

  final List<Map<String, String>> _ceremonyTypes = [
    {'value': 'wedding', 'label': 'Wedding (Bapla)'},
    {'value': 'karam', 'label': 'Karam'},
    {'value': 'sohrai', 'label': 'Sohrai'},
    {'value': 'baha', 'label': 'Baha'},
    {'value': 'naming', 'label': 'Naming Ceremony (Chacho Chatiar)'},
    {'value': 'funeral', 'label': 'Funeral (Bhandan)'},
    {'value': 'other', 'label': 'Other Ceremony'},
  ];

  final List<String> _states = [
    'Jharkhand',
    'West Bengal',
    'Odisha',
    'Bihar',
    'Assam',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final user = ref.read(currentUserProvider).value;
    final entryId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final entry = WaitlistModel(
      id: entryId,
      userId: user?.id,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      ceremonyType: _selectedCeremony,
      eventDate: _eventDate?.toIso8601String(),
      city: _cityController.text.trim(),
      state: _selectedState,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      submittedAt: now,
      status: 'new',
    );

    try {
      final submitWaitlist = ref.read(submitWaitlistEntryProvider);
      await submitWaitlist(entry);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss form bottom sheet
        _showSuccessDialog();
      }
    } catch (e) {
      AppLogger.debug('Waitlist submission failed: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join waitlist: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Waitlist Joined! 🎉'),
        content: const Text(
          'Thank you for submitting your details. Our cultural coordination team will contact you shortly via phone/WhatsApp to match you with a certified Binti Guru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Great',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1017) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text(
                'Join Binti Guru Waitlist',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us about your ceremony. We will search for available certified reciters.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildLabel('FULL NAME'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration('Enter your full name'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Phone Number
              _buildLabel('PHONE NUMBER'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  'Enter 10-digit mobile number',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final reg = RegExp(r'^[6-9]\d{9}$');
                  if (!reg.hasMatch(val.trim())) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Ceremony Dropdown & Date Picker Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CEREMONY TYPE'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCeremony,
                          items: _ceremonyTypes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['value'],
                                  child: Text(
                                    c['label']!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCeremony = val;
                              });
                            }
                          },
                          decoration: _buildInputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('EVENT DATE'),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: _buildInputDecoration('Select Date'),
                            child: Text(
                              _eventDate == null
                                  ? 'Choose Date'
                                  : DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_eventDate!),
                              style: TextStyle(
                                fontSize: 13,
                                color: _eventDate == null
                                    ? Colors.grey
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // City & State Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CITY / VILLAGE'),
                        TextFormField(
                          controller: _cityController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _buildInputDecoration(
                            'Enter city/village',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'City is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('STATE'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          items: _states
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedState = val;
                              });
                            }
                          },
                          decoration: _buildInputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Special Notes
              _buildLabel('ADDITIONAL NOTES (OPTIONAL)'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  'Any specific dialect, sub-tribe or requests?',
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Waitlist Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
