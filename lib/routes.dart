import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/template_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/template':
        // Ensure the arguments are passed via settings.arguments
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments != null) {
          final email = arguments['email'] as String;
          final clubData = arguments['clubData'] as Map<String, dynamic>;

            return MaterialPageRoute(
              builder: (_) => TemplateScreen(email: email, clubData: clubData),
            );
          
        } else {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Arguments are missing for ${settings.name}')),
            ),
          );
        }
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
