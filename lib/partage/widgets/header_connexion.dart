import 'package:flutter/material.dart';

class HeaderConnexion extends StatelessWidget {
  const HeaderConnexion({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 10),

        // 🟢 LOGO
        Align(
            alignment: Alignment.centerRight,
            child: Image.asset(
              isDark
                  ? 'assets/icons/Same shop fond noir.png'
                  : 'assets/icons/Same shop fond blanc.png',
              width: 180,
              fit: BoxFit.contain,
              // alignment: Alignment.centerRight,
            )),

        const SizedBox(height: 24),
      ],
    );
  }
}
