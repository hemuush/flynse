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
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Defines a shake animation for incorrect PIN feedback.
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
    _shakeController.dispose();
    super.dispose();
  }

  /// Checks for biometric capabilities and triggers authentication if applicable.
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
    
    // Automatically trigger biometrics if enabled and in enter mode.
    if (_isBiometricAvailable && widget.mode == PinLockMode.enter && useBiometrics) {
      _authenticateWithBiometrics();
    }
  }

  /// Initiates biometric authentication.
  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return; // Prevent multiple concurrent attempts.
    
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

  /// Handles successful authentication by calling the callback and popping the screen.
  void _onSuccessfulAuthentication() {
    HapticFeedback.heavyImpact();
    // Prioritize the callback to unlock the underlying page state.
    widget.onPinCorrect?.call();
    
    // Navigate back to the previous screen (e.g., home page or onboarding).
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Handles number presses from the numpad.
  void _onNumberPress(String value) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _errorText = ''; // Clear error on new input.
      });
      if (_enteredPin.length == 4) {
        // Short delay for user to see the last digit filled.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _handlePinSubmit(_enteredPin);
        });
      }
    }
  }

  /// Handles backspace presses.
  void _onBackspacePress() {
    HapticFeedback.lightImpact();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorText = '';
      });
    }
  }

  /// Triggers a shake animation and haptic feedback for incorrect PINs.
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

  /// Processes the submitted PIN for both create and enter modes.
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
  
  /// Handles the logic for creating a new PIN.
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
          // After saving, call the onPinCreated callback which should handle navigation.
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

  /// Handles the logic for verifying an existing PIN.
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

  /// Gets the appropriate title for the screen based on the mode.
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

    return PopScope(
      canPop: false, // Prevents user from accidentally backing out.
      child: Scaffold(
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
                      Text(
                        'Hi, ${settingsProvider.userName.split(' ').first}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                          final sineValue = math.sin(_shakeAnimation.value * math.pi * 4);
                          return Transform.translate(
                            offset: Offset(sineValue * 12, 0),
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
      ),
    );
  }

  /// Builds the styled PIN indicators.
  Widget _buildPinIndicators(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = index < _enteredPin.length;
        bool hasError = _errorText.isNotEmpty;
        Color color = hasError 
            ? theme.colorScheme.error 
            : isActive ? theme.colorScheme.primary : theme.dividerColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        );
      }),
    );
  }

  /// Builds the modern, well-styled numpad.
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
        crossAxisSpacing: 24,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == 'biometric') {
          // Show biometric button only if available and in enter mode.
          return _isBiometricAvailable && widget.mode == PinLockMode.enter
              ? _buildNumpadButton(
                  '',
                  icon: Icons.fingerprint,
                  onPressed: _authenticateWithBiometrics,
                )
              : const SizedBox.shrink(); // Placeholder
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

  /// Builds a single, styled button for the numpad.
  Widget _buildNumpadButton(String value, {IconData? icon, VoidCallback? onPressed}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed ?? () => _onNumberPress(value),
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
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
      ),
    );
  }
}
