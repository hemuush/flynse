import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

enum PinLockMode { create, enter }

class PinLockPageArgs {
  final PinLockMode mode;
  final VoidCallback? onPinCreated;
  final VoidCallback? onPinCorrect;
  final String? title;

  PinLockPageArgs({required this.mode, this.onPinCreated, this.onPinCorrect, this.title});
}

class PinLockPage extends StatefulWidget {
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

class _PinLockPageState extends State<PinLockPage> with SingleTickerProviderStateMixin {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _enteredPin = '';
  bool _isConfirming = false;
  String _firstPin = '';
  String _errorText = '';
  bool _canUseBiometrics = false;
  bool _isAuthenticating = false; // Flag to prevent multiple auth attempts

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    // Defer the biometric check until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  @override
  void dispose() {
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
      _canUseBiometrics = canCheckBiometrics;
    });

    final pinExists = await _settingsRepo.getPin() != null;
    
    // Automatically trigger biometrics if the device supports it, is in enter mode, and a PIN exists.
    if (_canUseBiometrics && widget.mode == PinLockMode.enter && pinExists) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    // Prevent multiple concurrent authentication attempts
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
          stickyAuth: true, // Keep the dialog open on app switch
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if(mounted) {
        setState(() {
          _errorText = "Biometrics error: ${e.message}";
        });
      }
      authenticated = false;
    }

    if (!mounted) return;

    if (authenticated) {
      _onSuccessfulAuthentication();
    } else {
      // Reset the flag if authentication is not successful (e.g., user cancelled)
       if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _onSuccessfulAuthentication() {
    HapticFeedback.heavyImpact();
    if (widget.onPinCorrect != null) {
      widget.onPinCorrect!();
    } else {
      // Use pushReplacementNamed to prevent going back to the lock screen
      Navigator.of(context).pushReplacementNamed(AppRouter.homePage);
    }
  }

  void _onNumberPress(String value) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _errorText = ''; // Clear error on new input
      });
      if (_enteredPin.length == 4) {
        // Short delay for user to see the last digit filled
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
    // Wait for the animation to complete before clearing the PIN
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
          // If a callback is provided, call it.
          if (widget.onPinCreated != null) {
            widget.onPinCreated!();
          } else {
            // Otherwise, provide a default navigation action.
            _onSuccessfulAuthentication();
          }
        } else {
          setState(() {
            _errorText = 'PINs do not match. Please try again.';
            _isConfirming = false; // Reset to start over
            _firstPin = ''; // FIX: Clear the first PIN on mismatch
          });
          _triggerError();
        }
      }
    } else { // PinLockMode.enter
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return Text(
                          'Hi, ${settingsProvider.userName.split(' ').first}',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSubtitle(),
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 48),
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final sineValue = math.sin(_shakeAnimation.value * math.pi * 6);
                        return Transform.translate(
                          offset: Offset(sineValue * 8, 0),
                          child: child,
                        );
                      },
                      child: _buildPinIndicators(theme),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 20,
                      child: Center(
                        child: _errorText.isNotEmpty
                            ? Text(
                                _errorText,
                                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                                textAlign: TextAlign.center,
                              )
                            : null,
                      ),
                    ),
                     if (_canUseBiometrics && widget.mode == PinLockMode.enter) ...[
                      const SizedBox(height: 24),
                      _isAuthenticating 
                        ? const CircularProgressIndicator()
                        : TextButton.icon(
                          onPressed: _authenticateWithBiometrics,
                          icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                          label: Text(
                            'Use Biometrics',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildNumberPad(),
                ),
              ),
            ],
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
        Color borderColor = hasError 
            ? theme.colorScheme.error 
            : isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(77);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: isActive 
                ? (hasError ? theme.colorScheme.error.withAlpha(26) : theme.colorScheme.primary.withAlpha(26)) 
                : Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isActive ? Text(
              '●',
              style: TextStyle(color: borderColor, fontSize: 16),
            ) : null,
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
      '', '0', 'backspace'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == '') return const SizedBox.shrink();
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
    return InkWell(
      onTap: onPressed ?? () => _onNumberPress(value),
      customBorder: const CircleBorder(),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 28, color: theme.colorScheme.onSurface)
            : Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}