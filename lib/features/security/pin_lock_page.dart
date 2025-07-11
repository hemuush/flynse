import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

// Defines the operation mode for the PIN lock screen.
enum PinLockMode { create, enter }

// Arguments for navigating to the PinLockPage.
class PinLockPageArgs {
  final PinLockMode mode;
  final VoidCallback? onPinCreated;
  final VoidCallback? onPinCorrect;
  final String? title;

  PinLockPageArgs({
    required this.mode,
    this.onPinCreated,
    this.onPinCorrect,
    this.title,
  });
}

class PinLockPage extends StatefulWidget {
  static bool isLockScreenOpen = false;

  final PinLockMode mode;
  final VoidCallback? onPinCreated;
  final VoidCallback? onPinCorrect;
  final String? title;

  const PinLockPage({
    super.key,
    required this.mode,
    this.onPinCreated,
    this.onPinCorrect,
    this.title,
  });

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage>
    with SingleTickerProviderStateMixin {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _enteredPin = '';
  bool _isConfirming = false;
  String _firstPin = '';
  String _errorText = '';
  bool _isBiometricAvailable = false;
  bool _isAuthenticating = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    PinLockPage.isLockScreenOpen = true;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  @override
  void dispose() {
    PinLockPage.isLockScreenOpen = false;
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } on PlatformException {
      canCheckBiometrics = false;
    }
    if (!mounted) return;

    setState(() {
      _isBiometricAvailable = canCheckBiometrics;
    });

    final useBiometrics = await _settingsRepo.getSetting('use_biometric') == 'true';
    
    if (_isBiometricAvailable && widget.mode == PinLockMode.enter && useBiometrics) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    if (mounted) {
      setState(() {
        _isAuthenticating = true;
      });
    }

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint or face to unlock Flynse',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if(mounted) {
        setState(() {
          _errorText = "Biometrics error: ${e.message}";
        });
      }
    }

    if (!mounted) return;

    if (authenticated) {
      _onSuccessfulAuthentication();
    } else {
       if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _onSuccessfulAuthentication() {
    HapticFeedback.heavyImpact();
    // --- MODIFICATION: Call onPinCorrect before popping ---
    // This ensures any state changes in the parent happen before this screen is gone.
    widget.onPinCorrect?.call();
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onNumberPress(String value) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _errorText = '';
      });
      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _handlePinSubmit(_enteredPin);
        });
      }
    }
  }

  void _onBackspacePress() {
    HapticFeedback.lightImpact();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorText = '';
      });
    }
  }

  Future<void> _triggerError() async {
    _shakeController.forward(from: 0);
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _enteredPin = '';
      });
    }
  }

  Future<void> _handlePinSubmit(String pin) async {
    setState(() {
      _errorText = '';
    });

    if (widget.mode == PinLockMode.create) {
      await _handleCreatePin(pin);
    } else {
      await _handleEnterPin(pin);
    }
  }
  
  Future<void> _handleCreatePin(String pin) async {
      if (!_isConfirming) {
        HapticFeedback.mediumImpact();
        setState(() {
          _firstPin = pin;
          _isConfirming = true;
          _enteredPin = '';
        });
      } else {
        if (pin == _firstPin) {
          await _settingsRepo.savePin(pin);
          // --- MODIFICATION: Call onPinCreated before any navigation ---
          widget.onPinCreated?.call();
        } else {
          setState(() {
            _errorText = 'PINs do not match. Please try again.';
            _isConfirming = false;
            _firstPin = '';
          });
          _triggerError();
        }
      }
  }

  Future<void> _handleEnterPin(String pin) async {
      final savedPin = await _settingsRepo.getPin();
      if (savedPin == pin) {
        _onSuccessfulAuthentication();
      } else {
        setState(() {
          _errorText = 'Incorrect PIN. Please try again.';
        });
        _triggerError();
      }
  }

  String _getSubtitle() {
    if (widget.title != null) return widget.title!;

    if (widget.mode == PinLockMode.create) {
      return _isConfirming ? 'Confirm your new Flynse PIN' : 'Create your Flynse PIN';
    }
    return 'Enter your Flynse PIN';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final profileImageBase64 = settingsProvider.profileImageBase64;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/icon/flynse.png',
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.wallet_outlined,
                  color: theme.colorScheme.primary,
                );
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: profileImageBase64 != null
                    ? MemoryImage(base64Decode(profileImageBase64))
                    : null,
                child: profileImageBase64 == null && settingsProvider.userName.isNotEmpty
                    ? Text(
                        settingsProvider.userName[0].toUpperCase(),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi, ${settingsProvider.userName.split(' ').first}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getSubtitle(),
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          final sineValue = math.sin(_shakeAnimation.value * math.pi * 4);
                          return Transform.translate(
                            offset: Offset(sineValue * 12, 0),
                            child: child,
                          );
                        },
                        child: _buildPinIndicators(theme),
                      ),
                      const SizedBox(height: 24),
                      if (_errorText.isNotEmpty)
                        Text(
                          _errorText,
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                          textAlign: TextAlign.center,
                        )
                      else if (_isBiometricAvailable && widget.mode == PinLockMode.enter)
                        TextButton.icon(
                          icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                          label: Text(
                            'Use fingerprint',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _authenticateWithBiometrics,
                        ),
                    ],
                  ),
                ),
                _buildNumberPad(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinIndicators(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = index < _enteredPin.length;
        bool hasError = _errorText.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary.withAlpha(26) : theme.colorScheme.surfaceContainer,
            border: Border.all(
              color: hasError ? theme.colorScheme.error : (isActive ? theme.colorScheme.primary : theme.dividerColor),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isActive
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    final List<String> keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', 'backspace'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == '.') {
          return const SizedBox.shrink(); // Placeholder for the dot
        }
        if (key == 'backspace') {
          return _buildNumpadButton(
            '',
            icon: Icons.backspace_outlined,
            onPressed: _onBackspacePress,
          );
        }
        return _buildNumpadButton(key);
      },
    );
  }

  Widget _buildNumpadButton(String value, {IconData? icon, VoidCallback? onPressed}) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed ?? () => _onNumberPress(value),
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        foregroundColor: theme.colorScheme.onSurface,
      ),
      child: icon != null
          ? Icon(icon, size: 24)
          : Text(
              value,
              style: theme.textTheme.headlineMedium,
            ),
    );
  }
}
