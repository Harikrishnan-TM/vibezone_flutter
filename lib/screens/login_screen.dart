import 'package:flutter/material.dart';
import 'package:vibezone_flutter/services/auth_service.dart'; // ✅ Updated the import path to your package

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key); // ✅ Added key constructor

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Track loading state
  String _errorMessage = ''; // To display error message

  // ✅ Handle login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Clear any previous error message
      });

      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Call the AuthService loginUser method
      final result = await AuthService().loginUser(username, password);

      if (!mounted) return; // ✅ Avoid context usage across async gaps

      setState(() {
        _isLoading = false;
      });

      if (result == 'success') {
        // Navigate to home screen on successful login
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error message if login fails
        setState(() {
          _errorMessage = result;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key for validation
          child: Column(
            children: <Widget>[
              // Username input field with validation
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              // Password input field with validation
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Error message if any
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Login button with loading state
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator
                    : const Text('Login'),
              ),

              // Add a "Forgot Password?" link for convenience
              TextButton(
                onPressed: () {
                  // Handle "Forgot Password" logic
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),

              // Option to navigate to signup screen if the user doesn't have an account
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
