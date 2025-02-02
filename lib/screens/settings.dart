import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.roboto()),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Section'),
            tiles: [
              SettingsTile(
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
              ),
              SettingsTile(
                title: Text('Theme'),
                description: Text('Light'),
                leading: Icon(Icons.brightness_6),
                onPressed: (BuildContext context) {
                  /* Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemeScreen()),
                  ); */
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('Account'),
            tiles: [
              SettingsTile(
                title: Text('Sign out'),
                leading: Icon(Icons.exit_to_app),
                onPressed: (BuildContext context) {
                  /* Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignOutScreen()),
                  ); */
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
 