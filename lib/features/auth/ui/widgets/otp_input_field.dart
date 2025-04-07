import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final OtpInputFieldController? controller;
  final Color cursorColor;
  final Color activeBoxColor;
  final Color inactiveBoxColor;
  final Color textColor;

  const OtpInputField({
    required this.length,
    required this.onCompleted,
    this.controller,
    this.cursorColor = colorGrey500,
    this.activeBoxColor = colorGrey200,
    this.inactiveBoxColor = colorGrey400,
    this.textColor = colorWhite,
    super.key,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _cursorController;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // listener to show/hide cursor for focus node
    _focusNode.addListener(_onFocusChange);

    _cursorController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _cursorVisible = !_cursorVisible;
            });
            _cursorController.forward(from: 0.0);
          }
        },
      );

    widget.controller?._attach(this);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _cursorController.forward();
    } else {
      _cursorController.stop();
      setState(() {
        _cursorVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  int get _cursorPosition => _controller.text.length;

  void clear() {
    _controller.clear();
    setState(() {});
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // hidden textfield
        Opacity(
          opacity: 0,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {});
              if (value.length == widget.length) {
                widget.onCompleted(value);
              }
            },
          ),
        ),

        // visible otp boxes
        GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(_focusNode);
            SystemChannels.textInput.invokeMethod('TextInput.show');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                widget.length,
                (index) => Container(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: index < _controller.text.length
                              ? widget.activeBoxColor
                              : widget.inactiveBoxColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Stack(alignment: Alignment.center, children: [
                        Text(
                          index < _controller.text.length
                              ? _controller.text[index]
                              : '',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: widget.textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (_focusNode.hasFocus &&
                            index == _cursorPosition &&
                            _cursorVisible &&
                            _cursorPosition < widget.length)
                          Container(
                            height: 25,
                            width: 1,
                            color: widget.cursorColor,
                          )
                      ]),
                    )),
          ),
        )
      ],
    );
  }
}

class OtpInputFieldController {
  _OtpInputFieldState? _state;

  void _attach(_OtpInputFieldState state) {
    _state = state;
  }

  void clear() {
    _state?._controller.clear();
    _state?._refresh();
  }
}
