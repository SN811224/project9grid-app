import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool registerMode = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入 Email，密碼至少 6 碼。')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      if (registerMode) {
        await SupabaseService.instance.signUp(
          email: email.text.trim(),
          password: password.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('註冊完成；若有啟用 Email 驗證，請先查看信箱。')),
          );
        }
      } else {
        await SupabaseService.instance.signIn(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗：$error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text('9', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  Text('Project 9Grid CRM', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('保險顧問的轉介紹與客戶追蹤工具'),
                  const SizedBox(height: 28),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: '密碼')),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text(loading ? '處理中…' : (registerMode ? '建立帳號' : '登入')),
                    ),
                  ),
                  TextButton(
                    onPressed: loading ? null : () => setState(() => registerMode = !registerMode),
                    child: Text(registerMode ? '已有帳號，回到登入' : '第一次使用，建立帳號'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
