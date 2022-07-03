import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => {},
                  child: const Text('Home'),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: () => {},
                  child: const Text('Posts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
