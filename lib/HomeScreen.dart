import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Verifica se o usuário já está logado ao abrir a tela
    _currentUser = _auth.currentUser;
  }

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Usuário cancelou o login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      setState(() {
        _currentUser = userCredential.user;
      });

      return userCredential.user;
    } catch (e) {
      print("Erro no login com Google: $e");
      return null;
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();

    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login com Google"),
      ),
      body: Center(
        child:
            _currentUser == null ? _buildSignInButton() : _buildUserDetails(),
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: () async {
        User? user = await _signInWithGoogle();
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bem-vindo, ${user.displayName}!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Falha no login")),
          );
        }
      },
      child: const Text("Login com Google"),
    );
  }

  Widget _buildUserDetails() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_currentUser?.photoURL != null)
          CircleAvatar(
            backgroundImage: NetworkImage(_currentUser!.photoURL!),
            radius: 40,
          ),
        const SizedBox(height: 16),
        Text("Nome: ${_currentUser!.displayName}"),
        Text("Email: ${_currentUser!.email}"),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _signOut,
          child: const Text("Sair"),
        ),
      ],
    );
  }
}
