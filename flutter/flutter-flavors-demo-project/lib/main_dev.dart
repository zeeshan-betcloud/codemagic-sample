import 'package:flutter/material.dart';
import 'constants.dart';

void main() {
  runApp(Home());
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: kThemeStyleGreen,
      title: 'Development',
      home: Scaffold(
        appBar: AppBar(title: Text('Development')),
        body: Center(
          child: Container(
            decoration: kGradientStyleAlt,
            // child: Text(AppConfig.of(context).buildFlavor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(
                  'Codemagic CI/CD',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25.0),
                ),
                Image.asset(
                  'assets/hero_a.png',
                  width: 180.0,
                  height: 180.0,
                ),
                Text(
                  'Multiple flavors',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
