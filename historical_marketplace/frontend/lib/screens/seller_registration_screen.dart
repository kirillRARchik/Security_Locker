import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

/// Экран регистрации продавца: многошаговая форма по макету.
/// После успешной отправки пользователю выдаётся статус продавца.
class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  int _step = 0;
  bool _loading = false;

  // Шаг 1
  String? _country;
  String? _companyType;

  // Шаг 2
  final _activityFieldController = TextEditingController();
  final _emailController = TextEditingController();

  static const _countries = ['Казахстан', 'Россия', 'Узбекистан', 'Другое'];
  static const _companyTypes = [
    'Всё кроме самозанятого',
    'Самозанятый',
  ];

  @override
  void dispose() {
    _activityFieldController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final country = _country?.trim();
    final companyType = _companyType?.trim();
    final activityField = _activityFieldController.text.trim();
    final email = _emailController.text.trim();

    if (country == null || country.isEmpty) {
      _showSnack('Выберите страну регистрации');
      return;
    }
    if (companyType == null || companyType.isEmpty) {
      _showSnack('Выберите форму организации');
      return;
    }
    if (activityField.isEmpty) {
      _showSnack('Укажите сферу деятельности');
      return;
    }
    if (email.isEmpty) {
      _showSnack('Укажите email для уведомлений');
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Сначала войдите в аккаунт');
        if (mounted) context.push('/login');
        return;
      }
      await ApiService.becomeSeller(
        token: token,
        country: country,
        companyType: companyType,
        activityField: activityField,
        companyEmail: email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вам выдан статус продавца'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Регистрация продавца',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    if (_step > 0) {
                      setState(() => _step--);
                    } else {
                      context.pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back, color: Colors.green, size: 22),
                        SizedBox(width: 4),
                        Text('Назад', style: TextStyle(color: Colors.green, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == 0) ..._buildStep1(),
            if (_step == 1) ..._buildStep2(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_step == 0) {
                          if (_country == null || _country!.isEmpty) {
                            _showSnack('Выберите страну регистрации');
                            return;
                          }
                          if (_companyType == null || _companyType!.isEmpty) {
                            _showSnack('Выберите форму организации');
                            return;
                          }
                          setState(() => _step = 1);
                        } else {
                          _submit();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_step == 0 ? 'Далее' : 'Далее'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Уже есть аккаунт? ', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                InkWell(
                  onTap: () => context.push('/login'),
                  child: const Text('Войти', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStep1() {
    return [
      _buildDropdownLabel('Страна регистрации'),
      const SizedBox(height: 6),
      _buildDropdown(
        value: _country,
        hint: 'Страна регистрации',
        items: _countries,
        onChanged: (v) => setState(() => _country = v),
      ),
      const SizedBox(height: 20),
      _buildDropdownLabel('Форма организации'),
      const SizedBox(height: 6),
      _buildDropdown(
        value: _companyType,
        hint: 'Форма организации',
        items: _companyTypes,
        onChanged: (v) => setState(() => _companyType = v),
      ),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      _buildDropdownLabel('Сфера деятельности'),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _activityFieldController,
        hint: 'Сфера деятельности',
      ),
      const SizedBox(height: 20),
      _buildTextField(
        controller: _emailController,
        hint: 'Ваш Email для уведомлений',
        keyboardType: TextInputType.emailAddress,
      ),
    ];
  }

  Widget _buildDropdownLabel(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.green[700], fontSize: 14),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value?.isNotEmpty == true ? value : null,
          hint: Text(hint, style: TextStyle(color: Colors.green[700])),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.green)))) .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.green[200]),
        filled: true,
        fillColor: Colors.green[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
