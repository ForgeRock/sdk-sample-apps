//  FRCallback.dart
//
//
//  Copyright (c) 2022-2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

/*
The FRCallback class is native Dart class replicating the structure of the SDKs Callback objects.
This is used in order to natively parse and encode/decode the JSON objects returned from the SDKs.
*/

class FRCallback {
  final String type;
  final int id;
  final List<FRInputOutput> output;
  final List<FRInputOutput> input;


  FRCallback({required this.type, required this.id, required this.output, required this.input});

  factory FRCallback.fromJson(Map<String, dynamic> parsedJson){

    var outputList = parsedJson['output'] as List;
    List<FRInputOutput> frOutputList = outputList.map((i) => FRInputOutput.fromJson(i)).toList();

    var inputList = parsedJson['input'] as List;
    List<FRInputOutput> frInputList = inputList.map((i) => FRInputOutput.fromJson(i)).toList();


    return FRCallback(
        type: parsedJson['type'],
        id: parsedJson['_id'],
        output: frOutputList,
        input: frInputList
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    '_id': id,
    'output': output,
    'input': input
  };
}

class FRInputOutput {
  final String name;
  dynamic value;

  FRInputOutput(this.name, this.value);

  FRInputOutput.fromJson(Map<dynamic, dynamic> json)
      : name = json['name'],
        value = json['value'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value
  };
}