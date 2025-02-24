import 'package:login_signup/theme/theme.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_signup/screens/signin_screen.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColorScheme.surface,
      appBar: AppBar(
        title: Text('Account', style: GoogleFonts.roboto()),
      ),
      body: SettingsList(
        sections: [
          
          SettingsSection(
            title: Text('Account'),
            tiles: [
              SettingsTile(
                title: Text('Sign out'),
                leading: Icon(Icons.exit_to_app),
                onPressed: (BuildContext context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignInScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
 