import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({Key? key}) : super(key: key);

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _confirmAccountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  File? _panImage;
  bool _isSubmitting = false;

  Future<void> _pickPanCardImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _panImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    if (_panImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your PAN card image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in. Please log in again.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final result = await ApiService.uploadKyc(
        realName: _nameController.text.trim(),
        bankName: _bankController.text.trim(),
        accountNumber: _accountController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        panCardFile: _panImage!,
        authToken: token, // pass token if needed
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('KYC submitted successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Submission failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Real Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter your real name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter your bank name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter account number' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmAccountController,
                decoration: const InputDecoration(labelText: 'Confirm Account Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Re-enter account number';
                  }
                  if (value != _accountController.text.trim()) {
                    return 'Account numbers do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ifscController,
                decoration: const InputDecoration(labelText: 'IFSC Code'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter IFSC code' : null,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickPanCardImage,
                    child: const Text('Upload PAN Card'),
                  ),
                  const SizedBox(width: 12),
                  if (_panImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitKyc,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit KYC'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
