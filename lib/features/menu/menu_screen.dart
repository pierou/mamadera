import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations_extension.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l.menuTitle)),
      body: Center(child: Text(context.l.settingsBodyText)),
    );
  }
}
