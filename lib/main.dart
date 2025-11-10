import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthScreen(),
    );
  }
}

// ---------------- AUTH SCREEN ----------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool showLogin = true;

  void toggleView() {
    setState(() => showLogin = !showLogin);
  }

  void navigateToProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Auth Demo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              showLogin
                  ? LoginForm(auth: _auth, onLoginSuccess: navigateToProfile)
                  : RegisterForm(auth: _auth),
              const SizedBox(height: 10),
              TextButton(
                onPressed: toggleView,
                child: Text(showLogin
                    ? "Don't have an account? Register"
                    : "Already have an account? Sign in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- REGISTER FORM ----------------
class RegisterForm extends StatefulWidget {
  final FirebaseAuth auth;
  const RegisterForm({super.key, required this.auth});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? message;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await widget.auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      setState(() => message = "Registered Successfully!");
    } on FirebaseAuthException catch (e) {
      setState(() => message = "${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) return "Enter an email";
              if (!value.contains('@')) return "Enter a valid email";
              return null;
            },
          ),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) return "Enter a password";
              if (value.length < 6) {
                return "Password must be at least 6 characters";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _register,
            child: const Text('Register'),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message!,
                style: TextStyle(
                  color: message!.contains("Successful") ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- LOGIN FORM ----------------
class LoginForm extends StatefulWidget {
  final FirebaseAuth auth;
  final VoidCallback onLoginSuccess;

  const LoginForm({super.key, required this.auth, required this.onLoginSuccess});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? message;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await widget.auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      widget.onLoginSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() => message = "${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) return "Enter an email";
              if (!value.contains('@')) return "Enter a valid email";
              return null;
            },
          ),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) return "Enter a password";
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _signIn,
            child: const Text('Sign In'),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- PROFILE SCREEN ----------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final TextEditingController newPassword = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: TextField(
          controller: newPassword,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Enter new password (min 6 chars)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (newPassword.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password must be 6+ characters")),
                );
                return;
              }
              try {
                await auth.currentUser?.updatePassword(newPassword.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password changed successfully")),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                "Logged in as:",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 5),
              Text(
                user?.email ?? "No email found",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _changePassword(context),
                icon: const Icon(Icons.lock),
                label: const Text("Change Password"),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
