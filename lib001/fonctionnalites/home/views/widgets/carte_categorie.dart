// import 'package:flutter/material.dart';
// import '../../../../coeur/languages/gestion_langage.dart';
// import '../models/categorie.dart';

// class CarteCategorie extends StatelessWidget {
//   final Categorie categorie;
//   final bool selectionnee;
//   final VoidCallback onTap;

//   const CarteCategorie({
//     super.key,
//     required this.categorie,
//     required this.selectionnee,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;

//     return InkWell(
//       onTap: onTap,
//       child: SizedBox(
//         width: 80,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               categorie.iconeData,
//               size: 24,
//               color: selectionnee ? cs.primary : cs.onSurfaceVariant,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               Langage.t(context, categorie.libelleCle),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: selectionnee ? FontWeight.w700 : FontWeight.w500,
//                 color: selectionnee ? cs.primary : cs.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
