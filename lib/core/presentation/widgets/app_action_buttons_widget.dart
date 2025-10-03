import 'package:flutter/material.dart';

class AppActionButton {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? heroTag;

  const AppActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.heroTag,
  });
}

class AppActionButtonsWidget extends StatelessWidget {
  final List<AppActionButton> buttons;
  final EdgeInsets padding;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final bool isRounded;
  final bool expandButtons;

  const AppActionButtonsWidget({
    super.key,
    required this.buttons,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16.0,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.isRounded = false,
    this.expandButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: _buildButtons(),
      ),
    );
  }

  List<Widget> _buildButtons() {
    List<Widget> widgets = [];

    for (int i = 0; i < buttons.length; i++) {
      final button = buttons[i];

      Widget buttonWidget = Container(
        margin: EdgeInsets.only(
          right: i < buttons.length - 1 ? spacing / 2 : 0,
          left: i > 0 ? spacing / 2 : 0,
        ),
        child: ElevatedButton.icon(
          onPressed: button.onPressed,
          icon: Icon(button.icon),
          label: Text(button.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: button.backgroundColor,
            foregroundColor: button.foregroundColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: isRounded
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  )
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
          ),
        ),
      );

      // Only wrap with Expanded if expandButtons is true
      if (expandButtons) {
        buttonWidget = Expanded(child: buttonWidget);
      }

      widgets.add(buttonWidget);
    }

    return widgets;
  }
}
