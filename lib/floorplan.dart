import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

double parseNumber(dynamic number) => (number as num).toDouble();

Color? parseColor(String? color) {
  return color == null ? null : Color(int.parse(color, radix: 16));
}

class BaseElement {}

class RootElement {
  final List<LayerElement> _children;
  final String locationId;

  get layers => _children;

  RootElement({
    List<LayerElement>? children,
    required this.locationId,
  }) : _children = children ?? [];

  factory RootElement.fromJson(Map<String, dynamic> data) {
    final children = ((data['children'] ?? []) as List).map((child) {
      switch (child['type']) {
        case 'layer':
          return LayerElement.fromJson(child);

        default:
          throw Exception('Invalid root element child: $child');
      }
    }).toList();

    return RootElement(
      children: children,
      locationId: data['locationId'],
    );
  }
}

class RectElement extends BaseElement {
  final Color? fill;
  final Color? stroke;
  final double x;
  final double y;
  final double width;
  final double height;

  RectElement({
    this.fill,
    this.stroke,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory RectElement.fromJson(Map<String, dynamic> data) {
    return RectElement(
      fill: parseColor(data['fill']),
      stroke: parseColor(data['stroke']),
      x: parseNumber(data['x']),
      y: parseNumber(data['y']),
      width: parseNumber(data['w']),
      height: parseNumber(data['h']),
    );
  }
}

class DeskElement extends BaseElement {
  final String deskId;
  final double x;
  final double y;

  DeskElement({
    required this.deskId,
    required this.x,
    required this.y,
  });

  factory DeskElement.fromJson(Map<String, dynamic> data) {
    return DeskElement(
      deskId: data['deskId'],
      x: parseNumber(data['x']),
      y: parseNumber(data['y']),
    );
  }
}

class LayerElement extends BaseElement {
  final List<BaseElement> _children;

  LayerElement({List<BaseElement>? children}) : _children = children ?? [];

  get children => _children;

  factory LayerElement.fromJson(Map<String, dynamic> data) {
    final children = ((data['children'] ?? []) as List).map((child) {
      switch (child['type']) {
        case 'desk':
          return DeskElement.fromJson(child);
        case 'rect':
          return RectElement.fromJson(child);
        default:
          throw Exception('Invalid layer child: $child');
      }
    }).toList();

    return LayerElement(children: children);
  }
}

class Floorplan extends StatefulWidget {
  final String jsonFloorplan;
  const Floorplan({required this.jsonFloorplan, Key? key}) : super(key: key);

  @override
  State<Floorplan> createState() => _FloorplanState();
}

class _FloorplanState extends State<Floorplan> {
  late RootElement root;

  void load(String jsonString) {
    final data = json.decode(jsonString);

    root = RootElement.fromJson(data);
  }

  @override
  void initState() {
    debugPrint(widget.jsonFloorplan);
    load(widget.jsonFloorplan);
    super.initState();
  }

  Widget buildRectElement(BuildContext context, RectElement element) {
    return Positioned(
      top: element.y,
      left: element.x,
      child: Container(
        height: element.height,
        width: element.width,
        color: element.fill,
      ),
    );
  }

  Widget buildDeskElement(BuildContext context, DeskElement element) {
    return Positioned(
      top: element.y,
      left: element.x,
      child: Container(
        height: 20,
        width: 20,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget buildElement(BuildContext context, BaseElement element) {
    switch (element.runtimeType) {
      case DeskElement:
        return buildDeskElement(context, element as DeskElement);

      case RectElement:
        return buildRectElement(context, element as RectElement);

      default:
        throw Exception('Invalid element type: ${element.runtimeType}');
    }
  }

  Widget buildLayer(BuildContext context, LayerElement layer) {
    final elements = layer.children
        .map<Widget>((child) => buildElement(context, child))
        .toList();

    return Stack(children: elements);
  }

  @override
  Widget build(BuildContext context) {
    final layers =
        root.layers.map<Widget>((layer) => buildLayer(context, layer)).toList();

    return InteractiveViewer(
      maxScale: 20,
      child: Stack(children: layers),
    );
  }
}
