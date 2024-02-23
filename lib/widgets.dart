library usbcan_plugins;

import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CanWidgetMode {
  hexMode,
  stringMode,
  floatMode,
  doubleMode,
  int16Mode,
  int32Mode,
  int64Mode,
  uint16Mode,
  uint32Mode,
  uint64Mode,
}

//it is a widget that can be used to input hex data.
class HexSwitchField extends StatefulWidget {
  const HexSwitchField(
      {super.key, required this.onChanged, required this.mode});

  final void Function(Uint8List) onChanged;
  final CanWidgetMode mode;

  @override
  State<HexSwitchField> createState() => _HexSwitchFieldState();
}

class _HexSwitchFieldState extends State<HexSwitchField> {
  Uint8List _data = Uint8List(0);

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case CanWidgetMode.hexMode:
        return TextField(
          onChanged: (value) {
            _data = Uint8List.fromList(value
                .replaceAll(RegExp(r'[^0-9a-fA-F]'), '')
                .split("")
                .toList()
                .asMap()
                .map((key, value) {
                  if (key % 2 == 1) {
                    return MapEntry(key, "$value ");
                  } else {
                    return MapEntry(key, value);
                  }
                })
                .values
                .join()
                .split(" ")
                .map((e) => int.tryParse(e, radix: 16))
                .whereType<int>()
                .toList());
            widget.onChanged(_data);
          },
          controller: TextEditingController(
              text: _data
                  .map((e) => e.toRadixString(16).padLeft(2, "0"))
                  .map(
                    (e) => " $e",
                  )
                  .join()
                  .toUpperCase()),
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.length > oldValue.text.length) {
                var sharpedData = newValue.text
                    .replaceAll(RegExp(r'[^0-9a-fA-F]'), '')
                    .toUpperCase()
                    .split("")
                    .asMap()
                    .map((key, value) {
                  if (key % 2 == 1) {
                    return MapEntry(key, "$value ");
                  } else {
                    return MapEntry(key, value);
                  }
                });
                return TextEditingValue(
                    text: sharpedData.values.join(),
                    selection: TextSelection.collapsed(
                        offset: sharpedData.values.join().length));
              } else {
                return newValue;
              }
            })
          ],
        );
      case CanWidgetMode.stringMode:
        return TextField(
            keyboardType: TextInputType.visiblePassword,
            onChanged: (value) {
              _data = const AsciiEncoder().convert(value);
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: const AsciiDecoder(allowInvalid: true).convert(_data)));
      case CanWidgetMode.floatMode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Float32List.fromList([double.parse(value)])
                      .buffer
                      .asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asFloat32List().isEmpty
                    ? ""
                    : _data.buffer.asFloat32List().first.toString()));
      case CanWidgetMode.doubleMode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Float64List.fromList([double.parse(value)])
                      .buffer
                      .asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asFloat64List().isEmpty
                    ? ""
                    : _data.buffer.asFloat64List().first.toString()));
      case CanWidgetMode.int16Mode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Int16List.fromList([int.parse(value)]).buffer.asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asInt16List().isEmpty
                    ? ""
                    : _data.buffer.asInt16List().first.toString()));
      case CanWidgetMode.int32Mode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Int32List.fromList([int.parse(value)]).buffer.asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asInt32List().isEmpty
                    ? ""
                    : _data.buffer.asInt32List().first.toString()));
      case CanWidgetMode.int64Mode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Int64List.fromList([int.parse(value)]).buffer.asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asInt64List().isEmpty
                    ? ""
                    : _data.buffer.asInt64List().first.toString()));
      case CanWidgetMode.uint16Mode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Uint16List.fromList([int.parse(value)])
                      .buffer
                      .asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asUint16List().isEmpty
                    ? ""
                    : _data.buffer.asUint16List().first.toString()));
      case CanWidgetMode.uint32Mode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty || value == "-"
                  ? Uint8List(0)
                  : Uint32List.fromList([int.parse(value)])
                      .buffer
                      .asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asUint32List().isEmpty
                    ? ""
                    : _data.buffer.asUint32List().first.toString()));
      case CanWidgetMode.uint64Mode:
        return TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
            ],
            onChanged: (value) {
              _data = value.isEmpty
                  ? Uint8List(0)
                  : Uint64List.fromList([int.parse(value)])
                      .buffer
                      .asUint8List();
              widget.onChanged(_data);
            },
            controller: TextEditingController(
                text: _data.buffer.asUint64List().isEmpty
                    ? ""
                    : _data.buffer.asUint64List().first.toString()));
      default:
        return Text("Not implemented: ${widget.mode}");
    }
  }
}
