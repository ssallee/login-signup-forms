import 'package:flutter/material.dart';
import 'package:login_signup/screens/signin_screen.dart';
import 'package:login_signup/screens/signup_screen.dart';
import 'package:login_signup/theme/theme.dart';
import 'package:login_signup/widgets/custom_scaffold.dart';
import 'package:login_signup/widgets/welcome_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return CustomScaffold(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Add this
          children: [
            Flexible(
                flex: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.1,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Welcome to IntelliDay\n',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.05, // 5% of screen height
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimary
                                )),
                           /*  TextSpan(
                                text:
                                    '\nEnter personal details to your employee account',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).colorScheme.onPrimary
                                  // height: 0,
                                )) */
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
            Container( // Replace Flexible with Container
              padding: const EdgeInsets.only(bottom: 0), // Add padding at bottom
              child: Row(
                children: [
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign in',
                      onTap: const SignInScreen(),
                      color: Colors.transparent,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign up',
                      onTap: const SignUpScreen(),
                      color: Theme.of(context).colorScheme.surface,
                      textColor: lightColorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
