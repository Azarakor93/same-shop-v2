import 'package:flutter/material.dart';

class HeaderRechercheSticky extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double hauteur;

  HeaderRechercheSticky({
    required this.child,
    this.hauteur = 62,
  });

  @override
  double get minExtent => hauteur;

  @override
  double get maxExtent => hauteur;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant HeaderRechercheSticky oldDelegate) {
    return false;
  }
}
