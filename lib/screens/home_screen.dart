import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_signup/screens/calendar.dart';
import 'package:login_signup/screens/settings.dart';
import 'package:login_signup/screens/assistant_screen.dart';
import 'package:login_signup/theme/theme.dart';
import  'daily_schedule_planner.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("My Awesome App"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.teal],
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Planner", // Changed to "Planner"
                        style: GoogleFonts.openSans(
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Home",
                        style: GoogleFonts.openSans(
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  /*IconButton(
                    alignment: Alignment.topCenter,
                    icon: Image.asset(
                      "assets/notification.png",
                      width: 24,
                    ),
                    onPressed: () {},
                  ), */
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Welcome message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Welcome back! What's happening today?",
                style: GoogleFonts.openSans(
                  textStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Grid content
            Expanded(
              child: GridView.count(
                childAspectRatio: 1.0,
                padding: const EdgeInsets.only(left: 16, right: 16),
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                children: _buildGridItems(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGridItems(BuildContext context) {
    final List<Items> items = [
      Items(
        title: "Calendar",
        subtitle: "March, Wednesday",
        event: "3 Events",
        img: "assets/calendar.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CalendarPage(),
          ),
        ),
      ),
      Items(
        title: "AI Chat",
        subtitle: "Chat with our AI assistant",
        event: "",
        img: "assets/map.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AssistantPage(),
          ),
        ),
      ),
      Items(
        title: "Locations",
        subtitle: "Lucy Mao going to Office",
        event: "",
        img: "assets/map.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DailySchedulePlanner(),
          ),
        ), 
      ),
      Items(
        title: "Activity",
        subtitle: "Rose favirited your Post",
        event: "",
        img: "assets/festival.png",
        onTap: () {
          // Add navigation logic for Activity
        },
      ),
      Items(
        title: "Settings",
        subtitle: "",
        event: "2 Items",
        img: "assets/setting.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        ),
      ),
    ];

    return items.map((data) {
      return InkWell(
        onTap: data.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xff453658),
                const Color(0xff453658).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                data.img,
                width: 42,
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                style: GoogleFonts.openSans(
                  textStyle: TextStyle(
                    color: lightColorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.subtitle,
                style: GoogleFonts.openSans(
                  textStyle: TextStyle(
                    color: lightColorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.event,
                style: GoogleFonts.openSans(
                  textStyle: TextStyle(
                    color: lightColorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class Items {
  String title;
  String subtitle;
  String event;
  String img;
  VoidCallback onTap;

  Items({
    required this.title,
    required this.subtitle,
    required this.event,
    required this.img,
    required this.onTap,
  });
}