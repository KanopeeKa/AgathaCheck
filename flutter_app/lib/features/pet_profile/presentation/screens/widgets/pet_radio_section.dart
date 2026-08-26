import 'package:flutter/material.dart';

class PetRadioSection extends StatelessWidget {
  final bool? groupValue;
  final ValueChanged<bool?> onChanged;
  final String yesLabel;
  final String noLabel;
  final String? title;

  const PetRadioSection({
    super.key,
    required this.groupValue,
    required this.onChanged,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(title!, style: Theme.of(context).textTheme.bodyLarge),
        RadioGroup<bool>(
          groupValue: groupValue,
          onChanged: onChanged,
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(title: Text(yesLabel), value: true),
              ),
              Expanded(
                child: RadioListTile<bool>(title: Text(noLabel), value: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
