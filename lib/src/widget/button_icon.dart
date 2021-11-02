import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';

import '../theme/neumorphic_theme.dart';
import 'app_bar.dart';
//import 'animation/animated_scale.dart';
//https://github.com/Idean/Flutter-Neumorphic/issues/241
import 'container.dart';


class NeumorphicButtonIcon extends StatefulWidget {
  static const double PRESSED_SCALE = 0.98;
  static const double UNPRESSED_SCALE = 1.0;

  final Widget? child;
  final NeumorphicStyle? style;
  final double minDistance;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool? pressed; //null, true, false
  final Duration duration;
  final Curve curve;
  final NeumorphicButtonClickListener? onPressed;
  final bool drawSurfaceAboveChild;
  final bool provideHapticFeedback;
  final String? tooltip;

  NeumorphicButtonIcon({
    Key? key,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.child,
    this.tooltip,
    this.drawSurfaceAboveChild = true,
    this.pressed, //true/false if you want to change the state of the button
    this.duration = Neumorphic.DEFAULT_DURATION,
    this.curve = Neumorphic.DEFAULT_CURVE,
    //this.accent,
    this.onPressed,
    this.minDistance = 0,
    this.style,
    this.provideHapticFeedback = true,
  }) : super(key: key);

  bool get isEnabled => onPressed != null;

  @override
  _NeumorphicButtonIconState createState() => _NeumorphicButtonIconState();
}

class _NeumorphicButtonIconState extends State<NeumorphicButton> {
  late NeumorphicStyle initialStyle;

  late double depth;
  bool pressed = false; //overwrite widget.pressed when click for animation

  void updateInitialStyle() {
    final appBarPresent = NeumorphicAppBarTheme.of(context) != null;

    final theme = NeumorphicTheme.currentTheme(context);
    this.initialStyle = widget.style ??
        (appBarPresent
            ? theme.appBarTheme.buttonStyle
            : (theme.buttonStyle ?? const NeumorphicStyle()));
    depth = widget.style?.depth ??
        (appBarPresent ? theme.appBarTheme.buttonStyle.depth : theme.depth) ??
        0.0;

    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateInitialStyle();
  }

  @override
  void didUpdateWidget(NeumorphicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateInitialStyle();
  }

  Future<void> _handlePress() async {
    hasFinishedAnimationDown = false;
    setState(() {
      pressed = true;
      depth = widget.minDistance;
    });

    await Future.delayed(widget.duration); //wait until animation finished
    hasFinishedAnimationDown = true;

    //haptic vibration
    if (widget.provideHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _resetIfTapUp();
  }

  bool hasDisposed = false;

  @override
  void dispose() {
    super.dispose();
    hasDisposed = true;
  }

  //used to stay pressed if no tap up
  void _resetIfTapUp() {
    if (hasFinishedAnimationDown == true && hasTapUp == true && !hasDisposed) {
      setState(() {
        pressed = false;
        depth = initialStyle.depth ?? neumorphicDefaultTheme.depth;

        hasFinishedAnimationDown = false;
        hasTapUp = false;
      });
    }
  }

  bool get clickable {
    return widget.isEnabled && widget.onPressed != null;
  }

  bool hasFinishedAnimationDown = false;
  bool hasTapUp = false;

  @override
  Widget build(BuildContext context) {
    final result = _build(context);
    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: result,
      );
    } else {
      return result;
    }
  }

  Widget _build(BuildContext context) {
    final appBarPresent = NeumorphicAppBarTheme.of(context) != null;
    final appBarTheme = NeumorphicTheme.currentTheme(context).appBarTheme;
    return Material(
      color: NeumorphicTheme.currentTheme(context).baseColor,
      child: InkWell(
        hoverColor: Colors.white.withOpacity(0.5),
        splashColor: NeumorphicTheme.currentTheme(context).baseColor,
        focusColor: NeumorphicTheme.currentTheme(context).baseColor,
        highlightColor: NeumorphicTheme.currentTheme(context).baseColor,
        child: AnimatedScale(
          duration: Duration(milliseconds: 150), //https://github.com/Idean/Flutter-Neumorphic/issues/241
          scale: _getScale(),
          child: Neumorphic(
            margin: widget.margin ?? const EdgeInsets.all(0),
            drawSurfaceAboveChild: widget.drawSurfaceAboveChild,
            duration: widget.duration,
            curve: widget.curve,
            style: initialStyle.copyWith(
              depth: _getDepth(),
              boxShape: NeumorphicBoxShape.path(NeumorphicFlutterLogoPathProvider()),
            ),
            child: widget.child,),
        ),
        onTapDown: (detail) {
          hasTapUp = false;
          if (clickable && !pressed) {
            _handlePress();
          }
        },
        onTap: () {
          if (clickable) {
            widget.onPressed!();
          }
          hasTapUp = true;
          _resetIfTapUp();
        },
        onTapCancel: () {
          hasTapUp = true;
          _resetIfTapUp();
        },
      ),
    );
  }

  double _getDepth() {
    if (widget.isEnabled) {
      return this.depth;
    } else {
      return 0;
    }
  }

  double _getScale() {
    if (widget.pressed != null) {
      //defined by the widget that use it
      return widget.pressed!
          ? NeumorphicButton.PRESSED_SCALE
          : NeumorphicButton.UNPRESSED_SCALE;
    } else {
      return this.pressed
          ? NeumorphicButton.PRESSED_SCALE
          : NeumorphicButton.UNPRESSED_SCALE;
    }
  }
}
