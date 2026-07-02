import 'package:flutter/material.dart';

import '../../theme/ios_tokens.dart';

class IosSectionHeader extends StatelessWidget {
  const IosSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
      child: Text(text.toUpperCase(), style: IosTokens.sectionHeader),
    );
  }
}

class IosSectionFooter extends StatelessWidget {
  const IosSectionFooter(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: IosTokens.footnote.copyWith(height: 18 / 13),
      ),
    );
  }
}
