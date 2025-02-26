import 'package:settings_ui/settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:login_signup/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_signup/screens/user_profile_screen.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String mode = themeProvider.themeMode == ThemeMode.system ? 'System Default' : themeProvider.themeMode == ThemeMode.light ? 'Light' : 'Dark';
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.roboto()),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Section'),
            tiles: [
              /* SettingsTile(
                title: Text('Language'),
                description: Text('English'),
                leading: Icon(Icons.language),
                onPressed: (BuildContext context) {
                  /* Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LanguageScreen()),
                  ); */
                },
              ), */
              SettingsTile(
                title: Text('Theme'),
                description: Text(mode),
                leading: Icon(Icons.brightness_6),
                onPressed: (BuildContext context) {
                  if (themeProvider.themeMode == ThemeMode.light) {
                    // Theme is light, switch to dark
                    themeProvider.setThemeMode(ThemeMode.dark); 
                    mode = 'Dark';
                  } else {
                    // Theme is dark, switch to light
                    themeProvider.setThemeMode(ThemeMode.light);
                    mode = 'Light'; 
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('Account'),
            tiles: [
              SettingsTile(
                title: Text('User Profile'),
                leading: Icon(Icons.exit_to_app),
                onPressed: (BuildContext context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfile()),
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
 
 