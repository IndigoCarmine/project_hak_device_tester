import 'package:flutter/material.dart';

class Work {
  Work({this.isHighlighted = false});
  bool isHighlighted;
}

class PauseWork extends Work {
  PauseWork(
      {this.duration = const Duration(seconds: 1), bool isHighlighted = false})
      : super(isHighlighted: isHighlighted);
  final Duration duration;
}

class MoveWork extends Work {
  MoveWork(this.angle,
      {this.duration = const Duration(seconds: 1), bool isHighlighted = false})
      : super(isHighlighted: isHighlighted);
  final int angle;
  final Duration duration;
}

class AjustWork extends Work {
  AjustWork(this.targetAngle, {isHighlighted = false})
      : super(isHighlighted: isHighlighted);
  final double targetAngle;
}

class WorkWidget extends StatefulWidget {
  const WorkWidget(
      {super.key,
      required this.work,
      required this.onFinished,
      required this.sendAngle});

  final Work work;
  final void Function() onFinished;
  final void Function(double) sendAngle;

  @override
  State<WorkWidget> createState() => _WorkWidgetState();
}

class _WorkWidgetState extends State<WorkWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: InnerWorkWidget(
        work: widget.work,
        onFinished: widget.onFinished,
        sendAngle: widget.sendAngle,
      ),
    );
  }
}

class InnerWorkWidget extends StatefulWidget {
  const InnerWorkWidget(
      {super.key,
      required this.work,
      required this.onFinished,
      required this.sendAngle});

  final Work work;
  final void Function() onFinished;
  final void Function(double) sendAngle;

  @override
  State<InnerWorkWidget> createState() => _InnerWorkWidgetState();
}

class _InnerWorkWidgetState extends State<InnerWorkWidget> {
  double silderValue = 0;
  @override
  Widget build(BuildContext context) {
    if (!widget.work.isHighlighted) {
      return Text(widget.work.runtimeType.toString());
    }
    switch (widget.work.runtimeType) {
      case PauseWork:
        return TextButton(
            onPressed: widget.onFinished, child: const Text('Run'));
      case MoveWork:
        widget.sendAngle((widget.work as MoveWork).angle.toDouble());
        Future<void>.delayed((widget.work as MoveWork).duration, () {
          widget.onFinished();
        });
        return Text('Move ${(widget.work as MoveWork).angle}°');
      case AjustWork:
        return Row(
          children: [
            Expanded(child: StatefulBuilder(builder: (context, setState) {
              return Slider(
                value: silderValue,
                secondaryTrackValue: (widget.work as AjustWork).targetAngle,
                onChanged: (newValue) {
                  widget.sendAngle(newValue);
                  setState(() {
                    silderValue = newValue;
                  });
                },
                min: 0,
                max: 255,
              );
            })),
            TextButton(
              onPressed: () {
                widget.sendAngle(widget.work is AjustWork
                    ? (widget.work as AjustWork).targetAngle
                    : 0);
                widget.onFinished();
              },
              child: const Text('Next'),
            ),
          ],
        );
      default:
        return const Text('Unknown');
    }
  }
}
