import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'absences_screen.dart';
import 'auth_widgets.dart';
import 'classes_screen.dart';
import 'exam_screen.dart';
import 'formations_screen.dart';
import 'grades_screen.dart';
import 'login.dart';
import 'session.dart';
import 'students_screen.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void go(Widget page) {
      Navigator.pop(context); // ferme le drawer
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    Widget item(IconData icon, String text, VoidCallback onTap) => ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(text, style: GoogleFonts.poppins()),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard", style: GoogleFonts.poppins()),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(color: kPrimary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                    "${Session.email}\n${Session.isAdmin ? 'Administrator' : 'User'}",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              ),
            ),
            item(Icons.groups, "Manage groups", () => go(const ClassesScreen())),
            item(Icons.school, "Manage students", () => go(const StudentsScreen())),
            item(Icons.menu_book, "Manage trainings",
                    () => go(const FormationsScreen())),
            item(Icons.event_busy, "Absences", () => go(const AbsencesScreen())),
            item(Icons.grade, "Grades & average", () => go(const GradesScreen())),
            item(Icons.assignment, "Exam", () => go(const ExamScreen())),
            const Divider(),
            item(Icons.logout, "Logout", () {
              Session.clear();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                      (route) => false);
            }),
            item(Icons.cancel, "Close", () => Navigator.pop(context)),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E7CFF), kPrimary, kPrimaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_rounded, size: 90, color: Colors.white),
              const SizedBox(height: 12),
              Text("Welcome",
                  style: GoogleFonts.poppins(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text("Open the menu to manage your data",
                  style: GoogleFonts.poppins(color: const Color(0xCCFFFFFF))),
            ],
          ),
        ),
      ),
    );
  }
}