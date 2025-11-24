import 'package:flutter/material.dart';
import '../widgets/registration_form.dart';
import '../../../utils/constants.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Constants.spacingM),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Constants.loginFormWidth,
                  maxHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      Constants.spacingM * 2,
                ),
                child: Container(
                  width: Constants.loginFormWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Constants.spacingL,
                    vertical: Constants.spacingXXL,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Constants.radiusXXL),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x3318303F),
                        blurRadius: Constants.shadowBlurRadius,
                        offset: Offset(
                            Constants.shadowOffset, Constants.shadowOffset),
                      )
                    ],
                  ),
                  child: const RegistrationForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



