//  FRNode.dart
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.

/*
The FRNode class is native Dart class replicating the structure of the SDKs Node objects.
This is used in order to natively parse and encode/decode the JSON objects returned from the SDKs.
*/

import 'FRCallback.dart';

class FRNode {
  String? header;
  String? authServiceId;
  String? stage;
  String? authId;
  String? description;
  List<FRCallback> callbacks;

  FRNode({required this.header, required this.authServiceId, required this.stage, required this.authId, required this.description, required this.callbacks});

  factory FRNode.fromJson(Map<String, dynamic> parsedJson){

    var list = parsedJson['callbacks'] as List;
    print(list.runtimeType);
    List<FRCallback> frCallbackList = list.map((i) => FRCallback.fromJson(i)).toList();


    return FRNode(
        header: parsedJson['header'],
        authServiceId: parsedJson['authServiceId'],
        stage: parsedJson['stage'],
        authId: parsedJson['authId'],
        description: parsedJson['description'],
        callbacks: frCallbackList
    );
  }

  Map<String, dynamic> toJson() => {
    'header': header,
    'authServiceId': authServiceId,
    'stage': stage,
    'authId': authId,
    'description': description,
    'callbacks': callbacks,
  };
}