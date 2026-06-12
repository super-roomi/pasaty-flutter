import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';
import 'package:mockup/services/auth_service.dart';
import 'package:mockup/services/auth_session.dart';

import '../../l10n/app_localizations.dart';
import '../../test.dart';

class CmLoginPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;
  const CmLoginPage({super.key, required this.onLocaleChange});

  @override
  State<CmLoginPage> createState() => _CmLoginPageState();
}

class _CmLoginPageState extends State<CmLoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.invalidCredentials);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = await AuthService.login(phone, password);
      if (!mounted) return;

      // The backend decides the role (embedded in the JWT); the app only
      // routes to the screen matching that role.
      switch (user.role) {
        case UserRole.driver:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DvMainShell(onLocaleChange: widget.onLocaleChange),
            ),
          );
        case UserRole.parent:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PrMainShell(onLocaleChange: widget.onLocaleChange),
            ),
          );
        default:
          await AuthService.logout();
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorText = l10n.unsupportedRole;
          });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = switch (e.statusCode) {
          401 => l10n.invalidCredentials,
          400 => e.message,
          _ => l10n.loginFailed,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = l10n.connectionError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Image.asset('assets/images/logo.png'),
            //Container wrapping a Column Containing Text & Fields
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF1A2B48),
                  borderRadius: BorderRadiusGeometry.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        l10n.welcomeToPasaty,
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.phoneNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(
                          width: 350,
                          child: TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
                              prefixIcon: Icon(Icons.phone_android),
                              // border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        //Test(),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.password,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 350,
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: l10n.passwordHint,
                              prefixIcon: Icon(Icons.lock),
                              // border: OutlineInputBorder()
                            ),
                            onSubmitted: (_) =>
                                _isLoading ? null : _handleLogin(),
                          ),
                        ),
                      ],
                    ),

                    if (_errorText != null)
                      SizedBox(
                        width: 350,
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    l10n.logIn,
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
