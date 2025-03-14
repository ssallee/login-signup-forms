import 'package:flutter/material.dart';
import 'package:login_signup/services/auth_service.dart';
import 'package:login_signup/screens/signin_screen.dart';
import 'package:login_signup/screens/home_screen.dart';
import 'package:login_signup/theme/theme.dart';
import 'package:login_signup/widgets/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool agreePersonalData = true;
  bool isLoading = false;
  String? errorMessage;

  // ✅ Function to handle sign-up
  Future<void> _signup() async {
    if (!_formSignupKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await AuthService.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      isLoading = false;
      if (response.containsKey("token")) {
        _saveToken(response["token"]); // ✅ Save token locally
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-up Successful! Logging in...")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (e) => const HomePage()), // ✅ Navigate to HomePage
        );
      } else {
        errorMessage = response["error"] ?? "Sign-up failed";
      }
    });
  }

  // ✅ Function to save token in SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("authToken", token);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(height: 10),
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // Full Name
                      TextFormField(
                        controller: _nameController, // ✅ Added controller
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter Full Name' : null,
                        decoration: InputDecoration(
                          label: const Text('Full Name'),
                          hintText: 'Enter Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Email
                      TextFormField(
                        controller: _emailController, // ✅ Added controller
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter Email' : null,
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          hintText: 'Enter Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Password
                      TextFormField(
                        controller: _passwordController, // ✅ Added controller
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter Password' : null,
                        decoration: InputDecoration(
                          label: const Text('Password'),
                          hintText: 'Enter Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Agree to Terms
                      Row(
                        children: [
                          Checkbox(
                            value: agreePersonalData,
                            onChanged: (bool? value) {
                              setState(() {
                                agreePersonalData = value!;
                              });
                            },
                            activeColor: lightColorScheme.primary,
                          ),
                          Text(
                            'I agree to the processing of ',
                          ),
                          Text(
                            'Personal data',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: lightColorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _signup, // ✅ Call sign-up function
                          child: isLoading
                              ? const CircularProgressIndicator() // ✅ Show loading indicator
                              : const Text('Sign up'),
                        ),
                      ),
                      if (errorMessage != null)
                        Text(errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 30.0),
                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (e) => const SignInScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
