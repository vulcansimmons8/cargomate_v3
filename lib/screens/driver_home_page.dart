import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Driver Home',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.directions_car, size: 64, color: Colors.blueGrey),
            SizedBox(height: 12),
            Text(
              'Welcome, Driver!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('This is where your jobs will appear.'),
          ],
        ),
      ),
    );
  }
}
