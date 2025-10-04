import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'routes.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/teacher/teacher_classes_screen.dart';
import 'screens/student/student_classes_screen.dart';
import 'screens/teacher/add_class_screen.dart';
import 'screens/student/student_homework_list_screen.dart';
import 'screens/teacher/teacher_homework_list_screen.dart';
import 'screens/homework/add_homework_screen.dart';
import 'screens/teacher/teacher_homework_submissions_screen.dart';

void main() {
  runApp(const LMSApp());
}

class LMSApp extends StatelessWidget {
  const LMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.white,
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.teacherClasses: (context) => const TeacherClassesScreen(),
        Routes.studentClasses: (context) => const StudentClassesScreen(),
        Routes.addClasses: (context) => const AddClassScreen(),
        Routes.addHomework: (context) {
          final classId = ModalRoute.of(context)!.settings.arguments as String;
          return AddHomeworkScreen(classId: classId);
        },
        Routes.studentHomeworkList: (context) {
          final classId = ModalRoute.of(context)!.settings.arguments as String;
          return StudentHomeworkListScreen(classId: classId);
        },
        Routes.viewHomework: (context) {
          final classId = ModalRoute.of(context)!.settings.arguments as String;
          return TeacherHomeworkListScreen(classId: classId);
        },
        Routes.homeworkSubmissions: (context) {
          final homeworkId =
          ModalRoute.of(context)!.settings.arguments as String;
          return TeacherHomeworkSubmissionsScreen(homeworkId: homeworkId);
        },
      },
    );
  }
}
