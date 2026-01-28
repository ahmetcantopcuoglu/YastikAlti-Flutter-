import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için (pubspec.yaml'da olmalı)

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isAccepted = false;
  bool _isLoading = false;

  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // 🔹 Firebase Kayıt Fonksiyonu
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || !_isAccepted) return;

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth ile Kullanıcı Oluştur
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      // 2. Firestore'a Detaylı Bilgileri Kaydet
      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'birth_date': _birthDateController.text,
          'created_at': FieldValue.serverTimestamp(),
          'auth_type': 'email',
        });

        // Başarılı Mesajı ve Yönlendirme
       if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Başarıyla kayıt oldunuz 🎉"),
      duration: Duration(seconds: 2),
    ),
  );

  await Future.delayed(const Duration(seconds: 2));
  Navigator.pop(context);
}
      }
    } on FirebaseAuthException catch (e) {
      String message = "Bir hata oluştu";
      if (e.code == 'email-already-in-use') message = "Bu e-posta zaten kullanımda.";
      if (e.code == 'weak-password') message = "Şifre çok zayıf.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 Tarih Seçici Fonksiyonu
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _showContract(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              const Text("Kullanıcı Sözleşmesi ve Yasal Uyarı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              const Text(
                "1. Değerler yaklaşık kuyumcu verileridir...\n"
                "2. Yatırım tavsiyesi içermez...\n"
                "3. Hakları PTACRAFT'a aittir.",
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.black),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Yeni Hesap Oluştur 🚀", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // Ad Soyad
              TextFormField(
                controller: _nameController,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ ]'))],
                maxLength: 50,
                decoration: _inputDecoration("Ad Soyad", Icons.person_outline),
                validator: (value) => (value == null || value.isEmpty) ? "Ad Soyad gerekli" : null,
              ),
              const SizedBox(height: 15),

              // Doğum Tarihi (Tıklanabilir Alan)
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: _inputDecoration("Doğum Tarihi", Icons.cake_outlined),
                validator: (value) => (value == null || value.isEmpty) ? "Doğum tarihi gerekli" : null,
              ),
              const SizedBox(height: 15),

              // E-posta
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                maxLength: 50,
                decoration: _inputDecoration("E-posta", Icons.email_outlined),
                validator: (value) => (value == null || !value.contains('@')) ? "Geçerli mail giriniz" : null,
              ),
              const SizedBox(height: 15),

              // Şifre
              TextFormField(
                controller: _passController,
                obscureText: _obscureText,
                maxLength: 16,
                decoration: _inputDecoration("Şifre", Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureText = !_obscureText)),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) return "En az 8 karakter";
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z]).+$').hasMatch(value)) return "Büyük ve küçük harf zorunlu";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Şifre Tekrar
              TextFormField(
                obscureText: _obscureConfirmText,
                maxLength: 16,
                decoration: _inputDecoration("Şifre Tekrar", Icons.lock_reset).copyWith(
                  suffixIcon: IconButton(icon: Icon(_obscureConfirmText ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText)),
                ),
                validator: (value) => (value != _passController.text) ? "Şifreler eşleşmiyor" : null,
              ),
              const SizedBox(height: 10),

              // Sözleşme Onay
              Row(
                children: [
                  Checkbox(
                    value: _isAccepted,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) => setState(() => _isAccepted = val!),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(
                            text: "Kullanıcı sözleşmesini ",
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () => _showContract(context),
                          ),
                          const TextSpan(text: "okudum, anladım ve kabul ediyorum."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kayıt Ol Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAccepted ? _handleRegister : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              
              const Center(
                child: Text(
                  "© 2026 PTACRAFT - Ahmetcan Topçuoğlu\nptacraft26@gmail.com",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      counterText: "",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black12)),
    );
  }
}