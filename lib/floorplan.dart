import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

double parseNumber(dynamic number) => (number as num).toDouble();

Color? parseColor(String? color) {
  return color == null ? null : Color(int.parse(color, radix: 16));
}

abstract class BaseElement {
  Rect getExtent();
}

class ElementWithChildren<T extends BaseElement> implements BaseElement {
  final List<T> _children;

  ElementWithChildren({
    List<T>? children,
  }) : _children = children ?? [];

  get children => _children;

  @override
  Rect getExtent() {
    double left = 0, right = 0, top = 0, bottom = 0;
    for (var child in _children) {
      final extent = child.getExtent();
      if (extent.left < left) {
        left = extent.left;
      }
      if (extent.top < top) {
        top = extent.top;
      }
      if (extent.right > right) {
        right = extent.right;
      }
      if (extent.bottom > bottom) {
        bottom = extent.bottom;
      }
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class RootElement extends ElementWithChildren<LayerElement> {
  final String locationId;

  get layers => _children;

  RootElement({
    List<LayerElement>? children,
    required this.locationId,
  }) : super(children: children);

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

class RectElement implements BaseElement {
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

  @override
  Rect getExtent() => Rect.fromLTWH(x, y, width, height);

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

class DeskElement implements BaseElement {
  final String deskId;
  final double x;
  final double y;

  DeskElement({
    required this.deskId,
    required this.x,
    required this.y,
  });

  @override
  Rect getExtent() => Rect.fromLTWH(x, y, 0, 0);

  factory DeskElement.fromJson(Map<String, dynamic> data) {
    return DeskElement(
      deskId: data['deskId'],
      x: parseNumber(data['x']),
      y: parseNumber(data['y']),
    );
  }
}

class LayerElement extends ElementWithChildren<BaseElement> {
  LayerElement({List<BaseElement>? children}) : super(children: children);

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
  late TransformationController controller;

  void load(String jsonString) {
    final data = json.decode(jsonString);

    root = RootElement.fromJson(data);
  }

  @override
  void initState() {
    debugPrint(widget.jsonFloorplan);
    load(widget.jsonFloorplan);

    controller = TransformationController();

    controller.addListener(() {
      print(controller.value);
    });
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
    const radius = 10;

    return Positioned(
      top: element.y - radius,
      left: element.x - radius,
      child: Container(
        height: radius * 2,
        width: radius * 2,
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

  Widget buildLayer(BuildContext context, LayerElement layer, Rect size) {
    final elements = layer.children
        .map<Widget>((child) => buildElement(context, child))
        .toList();

    return SizedBox(
      height: size.bottom,
      width: size.right,
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[500]),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: elements,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final size = root.getExtent();

    // final layers = root.layers
    //     .map<Widget>((layer) => buildLayer(context, layer, size))
    //     .toList();

    // final boundaryMargin = max(size.bottom, size.right);
    final size = Rect.fromLTRB(0, 0, 700, 400);
    // print(controller.value);
    return InteractiveViewer(
      transformationController: controller,
      boundaryMargin: EdgeInsets.fromLTRB(0, 0, 0, 0),
      constrained: false,
      child: SizedBox(
        height: 792,
        width: 700,
        child: Container(
          height: 400,
          width: 700,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: Colors.black,
            ),
            color: Colors.yellow,
          ),
        ),
      ),
    );
  }
}
