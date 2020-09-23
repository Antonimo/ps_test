import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ps_test/base_network_response.dart';
import 'package:ps_test/network_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'PS Test Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0.0,
                bottom: 50.0,
                left: 0.0,
                right: 0.0,
                child: Column(
                  children: [
                    Text('handshakeExceptionCount: ${NetworkService.instance.handshakeExceptionCount}'),
                  ],
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                height: 50.0,
                child: Container(
                  child: Center(
                    child: RaisedButton(
                      onPressed: () async {

                        NetworkService.refreshInstance();

                        for (var i = 0; i < 10; i++) {
                          try {
                            NetworkService.instance.get('https://app.arrow23.net/api/v1/auth/version').then((BaseNetworkResponse response) {
                              print('response.response.version: ${response.response}');
                            });

                            NetworkService.instance.put('https://app.arrow23.net/api/user/set-push-token', withToken: true).then((BaseNetworkResponse response) {
                              print('response.response.version: ${response.response}');
                            });

                            NetworkService.instance.get('https://app.arrow23.net/api/user/auth/data').then((BaseNetworkResponse response) {
                              print('response.response.version: ${response.response}');
                            });

                            NetworkService.instance.get('https://app.arrow23.net/api/v1/auth/version').then((BaseNetworkResponse response) {
                              print('response.response.version: ${response.response}');
                            });

                            NetworkService.instance.get('https://app.arrow23.net/api/user/auth/data').then((BaseNetworkResponse response) {
                              print('response.response.version: ${response.response}');
                            });

                            BaseNetworkResponse response = await NetworkService.instance.get('https://app.arrow23.net/api/v1/auth/version');

                            print('response.response.version: ${response.response}');
                          } catch (e) {
                            print('error: $e');
                          }
                        }
                      },
                      child: Text('Run Test'),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
