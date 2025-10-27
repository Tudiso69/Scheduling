import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _fonctionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _numeroController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _fonctionController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isLogin) {
      result = await ApiService.login(
        numero: _numeroController.text.trim(),
        motDePasse: _passwordController.text,
      );
    } else {
      result = await ApiService.register(
        numero: _numeroController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim().isEmpty ? null : _prenomController.text.trim(),
        fonction: _fonctionController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        motDePasse: _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.cyan.shade400, Colors.cyan.shade600],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 80,
                          color: Colors.cyan.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLogin ? 'Connexion' : 'Inscription',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Champ Numéro
                        TextFormField(
                           controller: _numeroController,
                           keyboardType: TextInputType.text, // ✅ Changé de phone à text
                           decoration: InputDecoration(
                             labelText: 'Numéro *',
                             hintText: '001, 002, Admin, etc.',
                             prefixIcon: const Icon(Icons.badge),
                             border: OutlineInputBorder(
                               borderRadius: BorderRadius.circular(12),
                             ),
                           ),
                           validator: (value) {
                             if (value == null || value.isEmpty) {
                               return 'Entrez votre numéro';
                             }
                             // ✅ Plus de contrainte de longueur !
                             return null;
                           },
                         ),
                        const SizedBox(height: 16),

                        // Champs supplémentaires pour l'inscription
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nomController,
                            decoration: InputDecoration(
                              labelText: 'Nom *',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Entrez votre nom';
                              }
                              if (value.length < 2) {
                                return 'Nom trop court';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _prenomController,
                            decoration: InputDecoration(
                              labelText: 'Prénom',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _fonctionController,
                            decoration: InputDecoration(
                              labelText: 'Fonction *',
                              hintText: 'Ex: Secrétaire, Médecin, etc.',
                              prefixIcon: const Icon(Icons.work),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Entrez votre fonction';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Email invalide';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _telephoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Champ mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe *',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez votre mot de passe';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Au moins 6 caractères requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bouton de soumission
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : Text(
                              _isLogin ? 'Se connecter' : 'S\'inscrire',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bouton de changement de mode
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Pas de compte ? S\'inscrire'
                                : 'Déjà un compte ? Se connecter',
                            style: TextStyle(
                              color: Colors.cyan.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
