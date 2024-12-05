//  login.dart
//
//
//  Copyright (c) 2022-2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'FRNode.dart';
import 'register.dart';
import 'todolist.dart';
import 'package:focus_detector/focus_detector.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const platform = MethodChannel('forgerock.com/SampleBridge'); //Method channel as defined in the native Bridge code
  final List<TextField> _fields = [];
  final List<TextEditingController> _controllers = [];
  late FRNode? currentNode = null;

  // Vital for identifying our FocusDetector when a rebuild occurs.
  final Key _focusDetectorKey = UniqueKey();

@override
  Widget build(BuildContext context) => FocusDetector(
        key: _focusDetectorKey,
        onFocusGained: () {
          print('CharacterListPage gains focus');
          currentNode = null;
          _fields.clear();
          _controllers.clear();
          _login();
        },
        onFocusLost: () {
          print('CharacterListPage lost focus');
        },
        child: Scaffold(
        appBar: AppBar(
          title: Text("Sign-In", style: TextStyle(color: Colors.grey[800]),),
          backgroundColor: Colors.grey[200],
        ),
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            _listView(),
            _okButton(),
            _registerButton()
          ],
        )),
      );

  //Lifecycle Methods
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      //When the first controller that will use the SDK is created we need to call the 'frAuthStart' method to initialise the native SDKs
      _startSDK();
    });
  }
  
  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _startSDK() async {
    String response;
    try {

      //Start the SDK. Call the frAuthStart channel method to initialise the native SDKs
      final String result = await platform.invokeMethod('frAuthStart');
      response = 'SDK Started';
    } on PlatformException catch (e) {
      response = "SDK Start Failed: '${e.message}'.";
    }
  }

  Future<void> _login() async {
    try {
      //Call the default login tree.
      final String result = await platform.invokeMethod('login');
      Map<String, dynamic> frNodeMap = jsonDecode(result);
      var frNode = FRNode.fromJson(frNodeMap);
      currentNode = frNode;

      //Upon completion, a node with callbacks will be returned, handle that node and present the callbacks to UI as needed.
      _handleNode(frNode);
    } on PlatformException catch (e) {
      debugPrint('SDK Error: $e');
      Navigator.pop(context);
    }
  }

  Future<void> _next() async {
    // Capture the User Inputs from the UI, populate the currentNode callbacks and submit back to AM
    currentNode?.callbacks.asMap().forEach((index, frCallback) {
      _controllers.asMap().forEach((controllerIndex, controller) {
        if (controllerIndex == index) {
          frCallback.input[0].value = controller.text;
        }
      });
    });
    String jsonResponse = jsonEncode(currentNode);
    try {
      // Call the SDK next method, to submit the User Inputs to AM. This will return the next Node or a Success/Failure
      String result = await platform.invokeMethod('next', jsonResponse);
      Navigator.pop(context);
      Map<String, dynamic> response = jsonDecode(result);
      if (response["type"] == "LoginSuccess") {
        _navigateToNextScreen(context);
      } else  {
        //If a new node is returned, handle this in a similar way and resubmit the user inputs as needed.
        Map<String, dynamic> frNodeMap = jsonDecode(result);
        var frNode = FRNode.fromJson(frNodeMap);
        currentNode = frNode;
        _handleNode(frNode);
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('SDK Error: $e');
    }
  }

  // Handling methods
  void _handleNode(FRNode frNode) {
    // Go through the node callbacks and present the UI fields as needed. Check for the type of each callback to determine, what UI element is needed.
    frNode.callbacks.forEach((frCallback) {
      final controller = TextEditingController();
      final field = TextField(
        controller: controller,
        obscureText: frCallback.type == "PasswordCallback", // If the callback type is 'PasswordCallback', make this a 'secure' textField.
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: frCallback.output[0].value,
        ),
      );
      setState(() {
        _controllers.add(controller);
        _fields.add(field);
      });
    });
  }

  void _navigateToNextScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => TodoList()),);
  }

  void _navigateToRegisterScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()),);
  }

  void showAlertDialog(BuildContext context) {
    AlertDialog alert=AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(margin: EdgeInsets.only(left: 5),child:Text("Loading" )),
        ],),
    );
    showDialog(barrierDismissible: false,
      context:context,
      builder:(BuildContext context){
        return alert;
      },
    );
  }

  // Widgets
  Widget _listView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _fields.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(15.0),
          child: _fields[index],
        );
      },
    );
  }

  Widget _registerButton() {
    return Container(
      color: Colors.transparent,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.all(15.0),
      height: 60,
      child: TextButton(
        onPressed: () async {
          _navigateToRegisterScreen(context);
        },
        child: const Text(
          "Not registered? Create an account now.",
          style: TextStyle(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _okButton() {
    return Container(
      color: Colors.transparent,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.all(15.0),
      height: 60,
      child: TextButton(
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue)),
        onPressed: () async {
          showAlertDialog(context);
          _next();
        },
        child:
        const Text(
          "Sign in",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}