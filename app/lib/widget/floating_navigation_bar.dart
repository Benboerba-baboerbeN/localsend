import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/last_transfer.dart';

class LastTransferStatusBar extends StatelessWidget {
  final LastTransferRecord record;

  const LastTransferStatusBar({required this.record, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final completedAt = record.completedAt.toLocal();
    final now = DateTime.now();
    final sameDay = completedAt.year == now.year && completedAt.month == now.month && completedAt.day == now.day;
    final time = DateFormat.jm(locale).format(completedAt);
    final timestamp = sameDay ? time : '${DateFormat.Md(locale).format(completedAt)} $time';
    final direction = switch (record.direction) {
      LastTransferDirection.sent => t.lastTransfer.sent,
      LastTransferDirection.received => t.lastTransfer.received,
    };
    final type = switch (record.type) {
      LastTransferType.image => t.lastTransfer.types.image,
      LastTransferType.video => t.lastTransfer.types.video,
      LastTransferType.pdf => t.lastTransfer.types.pdf,
      LastTransferType.text => t.lastTransfer.types.text,
      LastTransferType.apk => t.lastTransfer.types.apk,
      LastTransferType.other => t.lastTransfer.types.other,
      LastTransferType.multiple => t.lastTransfer.types.multiple,
    };

    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
          shape: StadiumBorder(
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              '$direction · $type · $timestamp',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const FloatingNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          elevation: 8,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
          shape: StadiumBorder(
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: colorScheme.primaryContainer,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  color: states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.onSurfaceVariant,
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  color: states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.normal,
                );
              }),
            ),
            child: NavigationBar(
              height: 70,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }
}
