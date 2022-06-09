import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/constants.dart';
import 'package:flutter_card_swiper/data.dart';
import 'package:flutter_card_swiper/models/animated_card.dart';
import 'package:flutter_card_swiper/utils.dart';

class AnimatedCardItem extends StatefulWidget {
  final AnimatedCard card;
  final Function onAnimationTrigger;
  final Function onVerticalDragEnd;

  const AnimatedCardItem({
    Key? key,
    required this.card,
    required this.onAnimationTrigger,
    required this.onVerticalDragEnd,
  }) : super(key: key);

  @override
  State<AnimatedCardItem> createState() => _CardState();
}

class _CardState extends State<AnimatedCardItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> rotationAnimation;
  late final Animation<double> slideUpAnimation;
  late Animation<double> slideDownAnimation;
  late final Animation<double> scaleAnimation;

  double yDragOffset = 0;
  double dragStartAngle = 0;
  Alignment dragStartRotationAlignment = Alignment.centerRight;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Constants.swipeAnimationDuration,
    );

    rotationAnimation = Tween<double>(
      begin: 0,
      end: -360,
    ).animate(animationController);

    scaleAnimation = Tween<double>(
      begin: 1,
      end: 1 - ((Data.cards.length - 1) * Constants.scaleFraction),
    ).animate(animationController);

    slideUpAnimation = Tween<double>(
      begin: 0,
      end: -Constants.throwSlideYDistance,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0, 0.5, curve: Curves.linear),
    ));

    slideDownAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(
        0.5,
        1,
        curve: Curves.linear,
      ),
    ));
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // print('Rebuilt card: ${widget.card.order}');

    return GestureDetector(
      onVerticalDragStart: (DragStartDetails details) {
        final xPosition = details.globalPosition.dx;
        final yPosition = details.localPosition.dy;
        // print('drag start global x position & local y positions [$xPosition, $yPosition]');

        setState(() {
          dragStartRotationAlignment = getDragStartPositionAlignment(
            xPosition,
            yPosition,
            screenWidth,
            Constants.cardHeight,
          );
          dragStartAngle = Constants.dragStartEndAngle *
              (xPosition > screenWidth / 2 ? -1 : 1);
        });
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        setState(() {
          yDragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (DragEndDetails details) {
        if (yDragOffset.abs() > Constants.initAnimationOffset) {
          widget.onAnimationTrigger();
          slideDownAnimation = Tween<double>(
            begin: 0,
            end: Constants.throwSlideYDistance +
                yDragOffset.abs() -
                (Data.cards.length - 1) * Constants.yOffset,
          ).animate(CurvedAnimation(
            parent: animationController,
            curve: const Interval(0.5, 1, curve: Curves.linear),
          ));
          animationController.forward().then((value) {
            setState(() {
              widget.onVerticalDragEnd();
              // yDragOffset = 0;
              dragStartAngle = 0;
            });
          });
        } else {
          setState(() {
            yDragOffset = 0;
            dragStartAngle = 0;
          });
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: yDragOffset),
        duration: const Duration(milliseconds: 100),
        curve: Curves.ease,
        builder: (c, double value, child) => Transform.translate(
          offset: Offset(0, value),
          child: child,
        ),
        child: AnimatedBuilder(
          animation: animationController,
          builder: (c, child) {
            return Transform.translate(
              offset: Offset(0, slideUpAnimation.value),
              child: Transform.translate(
                offset: Offset(0, slideDownAnimation.value),
                child: Transform.rotate(
                  angle: rotationAnimation.value * (math.pi / 180),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: scaleAnimation.value,
                    child: AnimatedRotation(
                      turns: dragStartAngle,
                      alignment: dragStartRotationAlignment,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        height: Constants.cardHeight,
                        decoration: BoxDecoration(
                          color: widget.card.color,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
