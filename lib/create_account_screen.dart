
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key, required this.title});

  final String title;

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _exception = '';

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        )
            .then((firebaseUser) {
          print('User: ${firebaseUser.user!.email} created successfully');
        });
        if (mounted) {
          context.go('/');
        }
      } on FirebaseAuthException catch (e) {
        String ex = 'Authentication Exception: ';
        if (e.code == 'email-already-in-use') {
          ex += 'The account already exists for that email.';
        } else if (e.code == 'weak-password') {
          ex += 'The password provided is too weak.';
        } else {
          ex += e.code;
        }
        setState(() {
          _exception = ex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: GoogleFonts.abrilFatface(
            fontSize: 32.0,
            color: const Color.fromARGB(255, 16, 43, 92),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_exception.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _exception,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          labelStyle: GoogleFonts.abrilFatface(),
                          icon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          labelStyle: GoogleFonts.abrilFatface(),
                          icon: const Icon(Icons.password),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password Field
                      TextFormField(
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          labelStyle: GoogleFonts.abrilFatface(),
                          icon: const Icon(Icons.password_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please re-enter your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match. Please try again';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // Create Account Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(90.0),
                          ),
                          backgroundColor: const Color.fromARGB(255, 115, 181, 110),
                          minimumSize: const Size(200, 50),
                        ),
                        onPressed: _createAccount,
                        child: Text(
                          "Create an Account",
                          style: GoogleFonts.abrilFatface(
                            fontSize: 20.0,
                            color: const Color.fromARGB(255, 16, 43, 92),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
