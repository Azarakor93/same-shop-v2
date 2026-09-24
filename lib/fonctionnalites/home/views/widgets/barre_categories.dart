// import 'package:flutter/material.dart';
// import '../models/categorie.dart';
// import 'carte_categorie.dart';

// class BarreCategories extends StatefulWidget {
//   final List<Categorie> categories;
//   final int indexSelectionne;
//   final ValueChanged<int> onSelection;

//   const BarreCategories({
//     super.key,
//     required this.categories,
//     required this.indexSelectionne,
//     required this.onSelection,
//   });

//   @override
//   State<BarreCategories> createState() => _BarreCategoriesState();
// }

// class _BarreCategoriesState extends State<BarreCategories> {
//   static const double hauteurIndicateur = 3;
//   static const double largeurIndicateur = 100;

//   final ScrollController _scrollController = ScrollController();
//   double _scrollOffset = 0;
//   double _maxScroll = 1;

//   @override
//   void initState() {
//     super.initState();

//     _scrollController.addListener(() {
//       setState(() {
//         _scrollOffset = _scrollController.offset;
//         _maxScroll = _scrollController.position.maxScrollExtent;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;

//     final double progression = _maxScroll == 0 ? 0 : _scrollOffset / _maxScroll;

//     return SizedBox(
//       height: 70,
//       child: Stack(
//         children: [
//           // 🔹 LISTE DES CATÉGORIES
//           ListView.builder(
//             controller: _scrollController,
//             scrollDirection: Axis.horizontal,
//             itemCount: widget.categories.length,
//             itemBuilder: (context, index) {
//               return CarteCategorie(
//                 categorie: widget.categories[index],
//                 selectionnee: index == widget.indexSelectionne,
//                 onTap: () => widget.onSelection(index),
//               );
//             },
//           ),

//           // 🟢 INDICATEUR = SCROLLBAR
//           Positioned(
//             bottom: 0,
//             left: progression *
//                 (MediaQuery.of(context).size.width - largeurIndicateur),
//             child: Container(
//               height: hauteurIndicateur,
//               width: largeurIndicateur,
//               decoration: BoxDecoration(
//                 color: cs.primary,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
