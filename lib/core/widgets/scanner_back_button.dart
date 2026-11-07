import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Returns through the application stack, including a retained order form.
class ScannerBackButton extends StatelessWidget {
  const ScannerBackButton({this.fallback = '/', super.key});

  final String fallback;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Quay lại',
    button: true,
    child: IconButton(
      tooltip: 'Quay lại',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        final router = GoRouter.of(context);
        String currentPath() {
          final configuration = router.routerDelegate.currentConfiguration;
          final last = configuration.last;
          return (last is ImperativeRouteMatch
                  ? last.matches.uri
                  : configuration.uri)
              .path;
        }

        final scannerPath = currentPath();
        if (router.canPop()) {
          router.pop();
          // A duplicate scanner entry must not strand the user on this screen.
          if (currentPath() == scannerPath) {
            router.go(fallback);
          }
        } else {
          router.go(fallback);
        }
      },
    ),
  );
}
