import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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

  // Method to pick the PAN card image from the gallery
  Future<void> _pickPanCardImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _panImage = File(pickedFile.path);
      });
    }
  }

  // Method to submit KYC details
  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if PAN card image is selected
    if (_panImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your PAN card image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // API call to upload KYC details
      final result = await ApiService.uploadKyc(
        realName: _nameController.text.trim(),
        bankName: _bankController.text.trim(),
        accountNumber: _accountController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        panCardFile: _panImage!,
      );

      // Handle success or failure based on the result
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('KYC submitted successfully')),
          );
          Navigator.pop(context); // Go back to previous screen
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Submission failed')),
          );
        }
      }
    } catch (e) {
      // Handle errors during submission
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Real Name TextField
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Real Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your real name' : null,
              ),
              const SizedBox(height: 16),
              
              // Bank Name TextField
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter bank name' : null,
              ),
              const SizedBox(height: 16),

              // Account Number TextField
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter account number' : null,
              ),
              const SizedBox(height: 16),

              // Confirm Account Number TextField
              TextFormField(
                controller: _confirmAccountController,
                decoration: const InputDecoration(labelText: 'Confirm Account Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Re-enter account number';
                  if (value != _accountController.text) return 'Account numbers do not match';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // IFSC Code TextField
              TextFormField(
                controller: _ifscController,
                decoration: const InputDecoration(labelText: 'IFSC Code'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter IFSC code' : null,
              ),
              const SizedBox(height: 24),

              // PAN Card Image Upload Section
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickPanCardImage,
                    child: const Text('Upload PAN Card'),
                  ),
                  const SizedBox(width: 10),
                  if (_panImage != null) const Text('✅ Selected', style: TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitKyc,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit KYC'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
