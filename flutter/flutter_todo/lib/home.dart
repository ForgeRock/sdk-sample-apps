import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Widgets
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title:  Text(
          'Home',
          style: TextStyle(
            color: Colors.grey[900],
          )
        ),
        backgroundColor: Colors.grey[200] ,
      ),
      backgroundColor: Colors.grey[100],
      body:
    ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(15.0),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 15),
              Text("Protect with ForgeRock; Develop with Flutter",
              style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w100,
                  fontSize: 30),
              ),
              SizedBox(height: 15),
              Text("Learn how to develop Ping protected, hybrid apps with the React Native library and our Native SDKs.",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 26),
              ),
              SizedBox(height: 30),
              Text("About this project",
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
              SizedBox(height: 15),
              Text("The purpose of this sample app is to demonstrate how the Ping SDKs can be leveraged within a fully-functional Flutter application. Included in this sample app is a sample bridging layer for connecting the native Ping modules (Android and iOS) within Flutter.",
                style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.normal,
                    fontSize: 20),
              ),
          ],
        )]
    )
    );
  }
}