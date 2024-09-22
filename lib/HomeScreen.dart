import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    // Certifique-se de que o Firebase foi inicializado
    await Firebase.initializeApp();
    _currentUser = _auth.currentUser;
    print("Usuário logado atualmente: $_currentUser");
    setState(() {});
  }

  Future<User?> _signInWithGoogle() async {
    try {
      print("Tentando login com Google...");

      // Faz login com o Google

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Login cancelado pelo usuário");
        return null; // Usuário cancelou o login
      }

      print(
          "Login com Google bem-sucedido, usuário: ${googleUser.displayName}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Erro: accessToken ou idToken está nulo.");
        return null;
      }

      print("Access Token: ${googleAuth.accessToken}");
      print("ID Token: ${googleAuth.idToken}");

      print(
          "Autenticação do Google obtida. Access Token: ${googleAuth.accessToken}");

      // Usa o token do Google para autenticar no Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Faz o login no Firebase usando o token do Google
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      print("Login com Firebase bem-sucedido, usuário: ${user?.displayName}");

      return user;
    } catch (error) {
      print("Erro no login com Google: $error");
      return null;
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();

    setState(() {
      _currentUser = null;
    });
    print("Usuário deslogado");
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
        print("Tentando login...");
        final user = await _signInWithGoogle();
        if (user != null) {
          print("Login bem-sucedido: ${user.displayName}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bem-vindo, ${user.displayName}!")),
          );
          setState(() {
            _currentUser = user;
          });
        } else {
          print("Falha no login");
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
