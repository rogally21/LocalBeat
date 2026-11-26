// fatto da Vuoler21
import 'package:flutter/material.dart';

/// Switch pagine stile feed ↔ profilo (swipe + tab): parallax, scala e fade.
/// APPROSSIMAZIONE dell'animazione uiverse (sostituibile con l'originale)
class PageSwitcher extends StatelessWidget {
  final PageController controller;
  final List<Widget> pages;
  final ValueChanged<int> onChanged;
  const PageSwitcher({super.key, required this.controller, required this.pages, required this.onChanged});

  @override
  Widget build(BuildContext context) => PageView.builder(
        controller: controller,
        itemCount: pages.length,
        onPageChanged: onChanged,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) => AnimatedBuilder(
          animation: controller,
          child: pages[i],
          builder: (_, child) {
            double d = 0;
            if (controller.hasClients && controller.position.haveDimensions) {
              d = ((controller.page ?? i.toDouble()) - i).clamp(-1.0, 1.0);
            }
            return Opacity(
                opacity: 1 - d.abs() * .7,
                child: Transform.translate(
                    offset: Offset(-d * 40, 0),
                    child: Transform.scale(scale: 1 - d.abs() * .08, child: child)));
          },
        ),
      );
}

void goPage(PageController c, int i) =>
    c.animateToPage(i, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
