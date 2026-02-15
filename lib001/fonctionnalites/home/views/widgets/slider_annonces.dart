import 'package:flutter/material.dart';

import '../models/annonces.dart';

class SliderAnnonces extends StatefulWidget {
  final List<Annonce> annonces;

  const SliderAnnonces({
    super.key,
    required this.annonces,
  });

  @override
  State<SliderAnnonces> createState() => _SliderAnnoncesState();
}

class _SliderAnnoncesState extends State<SliderAnnonces> {
  int indexActuel = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            itemCount: widget.annonces.length,
            onPageChanged: (i) => setState(() => indexActuel = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.annonces[index].imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.annonces.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: indexActuel == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: indexActuel == i
                    ? cs.secondary
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
