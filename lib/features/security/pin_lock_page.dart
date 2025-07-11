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
  
  bool _biometricsEnabled = false;
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
      _initializeSecurityCheck();
    });
  }

  @override
  void dispose() {
    PinLockPage.isLockScreenOpen = false;
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _initializeSecurityCheck() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } on PlatformException {
      canCheckBiometrics = false;
    }

    final useBiometricsSetting = await _settingsRepo.getSetting('use_biometric') == 'true';
    
    if(mounted) {
      setState(() {
        _biometricsEnabled = canCheckBiometrics && useBiometricsSetting;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating || !_biometricsEnabled) return;
    
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

  String _getWelcomeMessage() {
    final userName = context.read<SettingsProvider>().userName.split(' ').first;
    if (widget.mode == PinLockMode.create) {
      return _isConfirming ? 'Confirm your PIN' : 'Create a new PIN';
    }
    return 'Welcome back, $userName!';
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: profileImageBase64 != null
                      ? MemoryImage(base64Decode(profileImageBase64))
                      : null,
                  child: profileImageBase64 == null && settingsProvider.userName.isNotEmpty
                      ? Text(
                          settingsProvider.userName[0].toUpperCase(),
                          style: theme.textTheme.displaySmall
                              ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  _getWelcomeMessage(),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                SizedBox(height: _errorText.isNotEmpty ? 16 : 40),
                if (_errorText.isNotEmpty)
                  Text(
                    _errorText,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                const Spacer(flex: 1),
                _buildNumberPad(),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinIndicators(ThemeData theme) {
    bool hasError = _errorText.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = index < _enteredPin.length;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? (hasError ? theme.colorScheme.error : theme.colorScheme.primary) : Colors.transparent,
            border: Border.all(
              color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
              width: 1.5,
            ),
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
      'biometric', '0', 'backspace'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == 'biometric') {
          return _biometricsEnabled && widget.mode == PinLockMode.enter
            ? _buildNumpadButton(
                '',
                icon: Icons.fingerprint,
                onPressed: _authenticateWithBiometrics,
              )
            : const SizedBox.shrink();
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
    final isDarkMode = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onPressed ?? () => _onNumberPress(value),
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withAlpha(isDarkMode ? 20 : 15),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 28, color: theme.colorScheme.onSurface)
              : Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
        ),
      ),
    );
  }
}
