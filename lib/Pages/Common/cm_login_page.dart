import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, TextInput;
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_primary_button.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_text_field.dart';
import 'package:mockup/services/auth_service.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/push_service.dart';

import '../../l10n/app_localizations.dart';

/// Sign-in.
///
/// Deliberately one column on a light surface rather than the previous
/// logo/navy-panel split. Three reasons:
///
///  * The split used `Expanded` inside a non-scrolling `Column`, so raising
///    the keyboard squeezed the panel that held the fields — the classic
///    keyboard-occlusion failure. Everything now lives in one scroll view
///    that centres while it fits and scrolls once it does not.
///  * The fields are styled by a light-surface `inputDecorationTheme` (white
///    fill, grey borders) but were sitting on deep navy, so the theme and the
///    background were fighting each other.
///  * Error text was `redAccent` on navy: 4.44:1, below AA. On the light
///    surface `dangerRed` reaches 4.53:1.
///
/// There is no "create account" affordance because there is no self-service
/// registration — accounts are provisioned by admins in the web dashboard
/// (see [AuthService]). The footer says so, rather than leaving the user
/// hunting for a sign-up link that will never exist.
class CmLoginPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;
  const CmLoginPage({super.key, required this.onLocaleChange});

  @override
  State<CmLoginPage> createState() => _CmLoginPageState();
}

class _CmLoginPageState extends State<CmLoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  /// Per-field messages, so "you left the password blank" is not reported as
  /// "invalid phone number or password" — which blames credentials the user
  /// never submitted.
  String? _phoneError;
  String? _passwordError;

  /// Whatever the server said. Kept apart from the field errors so a failed
  /// round-trip and a local validation miss never render in the same slot.
  String? _formError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_phoneError != null || _passwordError != null || _formError != null) {
      setState(() {
        _phoneError = null;
        _passwordError = null;
        _formError = null;
      });
    }
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final phoneMissing = phone.isEmpty;
    final passwordMissing = password.isEmpty;
    if (phoneMissing || passwordMissing) {
      HapticFeedback.heavyImpact();
      setState(() {
        _phoneError = phoneMissing ? l10n.enterPhoneNumber : null;
        _passwordError = passwordMissing ? l10n.enterPassword : null;
        _formError = null;
      });
      // Send focus to the first offending field so the fix is one tap away.
      (phoneMissing ? _phoneFocus : _passwordFocus).requestFocus();
      return;
    }

    // Dismiss the keyboard: the result (spinner, then an error or a new
    // screen) is behind it otherwise.
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _phoneError = null;
      _passwordError = null;
      _formError = null;
    });

    try {
      final user = await AuthService.login(phone, password);
      if (!mounted) return;

      // Tells the platform password manager the credentials were accepted, so
      // it offers to save them. Without this the prompt never appears.
      TextInput.finishAutofillContext();

      // Registers this device for push. Deliberately after login and not
      // awaited: `/v1/devices` needs a session, and on iOS it can wait
      // several seconds for APNs — neither the navigation below nor the user
      // should be held up by it, and a failure just means no notifications.
      unawaited(
        PushService.instance.onSignedIn(
          language: Localizations.localeOf(context).languageCode == 'ar'
              ? 'ar'
              : 'en',
        ),
      );

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
            _formError = l10n.unsupportedRole;
          });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        // 400/401 from /login means the phone or password is wrong. Use
        // our own localized wording, not the backend's English
        // "Invalid Credentials".
        _formError = switch (e.statusCode) {
          400 || 401 => l10n.invalidCredentials,
          _ => errorText(context, e),
        };
      });
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _formError = l10n.connectionError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const topPad = 8.0;
            const bottomPad = 24.0;
            final keyboard = MediaQuery.viewInsetsOf(context).bottom;

            return SingleChildScrollView(
              // Always scrollable so the form can clear the keyboard on short
              // screens; ConstrainedBox + IntrinsicHeight keeps it vertically
              // centred when there is room to spare.
              padding: EdgeInsets.fromLTRB(
                24,
                topPad,
                24,
                bottomPad + keyboard,
              ),
              child: ConstrainedBox(
                // The padding sits outside this box, so it has to come out of
                // the min height — otherwise the content is always taller than
                // the viewport and the footer is scrolled off the bottom.
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - topPad - bottomPad - keyboard)
                          .clamp(0.0, double.infinity),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _LanguageToggle(
                          onLocaleChange: widget.onLocaleChange,
                        ),
                      ),
                      // Top-anchored, not centred: the form starts high enough
                      // that raising the keyboard never pushes it out of
                      // comfortable reach. The single Spacer below takes up the
                      // slack on tall screens and collapses to zero once the
                      // keyboard claims the space.
                      const SizedBox(height: 8),
                      _header(l10n),
                      const SizedBox(height: 24),
                      _form(l10n),
                      const Spacer(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.accountsManagedBySchool,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    // start, never left: in Arabic this whole block mirrors to the right edge,
    // which is what "left-aligned" means in an RTL locale.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bounded and decoded at display size rather than the asset's full
        // resolution — this is the largest image in the app. Smaller than a
        // centred hero would be: the logo is identification, and every point
        // it gives back is a point the form gains above the keyboard.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Image.asset(
            'assets/images/logo.png',
            height: 104,
            fit: BoxFit.contain,
            cacheWidth: 620,
            // Purely decorative: the headline below already names the app, so
            // announcing the logo too would just repeat it.
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.welcomeToPasaty,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.signInSubtitle,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.4,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _form(AppLocalizations l10n) {
    // AutofillGroup + hints let iOS Keychain and Android Autofill fill both
    // fields in one tap, and offer to save them after a successful login.
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CmTextField(
            label: l10n.phoneNumber,
            hint: l10n.phoneNumberHint,
            controller: _phoneController,
            focusNode: _phoneFocus,
            errorText: _phoneError,
            prefixIcon: Icons.phone_outlined,
            enabled: !_isLoading,
            // `phone`, not `number`: gives the telephone pad (with + and #)
            // rather than a plain numeric keypad.
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            onChanged: (_) => _clearErrors(),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          // Separates the two field groups so a validation message never sits
          // flush against the next field's label.
          const SizedBox(height: 14),
          CmTextField(
            label: l10n.password,
            hint: l10n.passwordHint,
            controller: _passwordController,
            focusNode: _passwordFocus,
            errorText: _passwordError,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => _clearErrors(),
            onSubmitted: (_) => _isLoading ? null : _handleLogin(),
            suffix: IconButton(
              // Reveal is essential when the password was issued by someone
              // else and is being copied off a slip of paper.
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
              color: AppColors.mutedText,
            ),
          ),
          // Server-side failures. liveRegion so it is announced when it
          // appears; the reserved slot means it never shifts the button.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _formError == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerTint,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                          border: Border.all(color: AppColors.dangerRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: AppColors.dangerRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formError!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: AppColors.dangerRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          CmPrimaryButton(
            label: l10n.logIn,
            loadingLabel: l10n.signingIn,
            loading: _isLoading,
            icon: Icons.arrow_forward,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }
}

/// Compact EN | AR switch, extracted so toggling locale does not rebuild the
/// form (and so the login page's `State` is not responsible for it).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.onLocaleChange});

  final void Function(Locale) onLocaleChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;

    Widget option(String code, String label) {
      final selected = current == code;
      return Semantics(
        button: true,
        selected: selected,
        child: TextButton(
          onPressed: selected
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onLocaleChange(Locale(code));
                },
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            foregroundColor: AppColors.deepNavy,
            disabledForegroundColor: AppColors.deepNavy,
            backgroundColor: selected
                ? AppColors.neutralTint
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          // The language's own endonym, no flag: a flag names a country, not
          // a language, and the app previously disagreed with itself about
          // which one stood for Arabic.
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        option('en', l10n.englishLanguage),
        const SizedBox(width: 4),
        option('ar', l10n.arabicLanguage),
      ],
    );
  }
}
