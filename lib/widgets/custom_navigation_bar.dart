import 'package:flutter/material.dart';
import '../theme/responsive.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération dynamique de la taille
    final iconSize = Responsive.navIconSize(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(Icons.home, size: iconSize), // Taille adaptative
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.collections, size: iconSize), // Taille adaptative
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.shopping_cart, size: iconSize), // Taille adaptative
          onPressed: () {},
        ),
      ],
    );
  }
}