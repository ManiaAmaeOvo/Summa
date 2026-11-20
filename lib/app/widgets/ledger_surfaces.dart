import 'dart:math' as math;

import 'package:flutter/material.dart';

TextStyle? ledgerAmountStyle(TextStyle? style, {Color? color}) =>
    style?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class LedgerMetricGrid extends StatelessWidget {
  const LedgerMetricGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 10.0;
      final scale = math.max(
        1.0,
        MediaQuery.textScalerOf(context).scale(14) / 14,
      );
      final maxColumns = constraints.maxWidth >= 4 * 144 * scale + 3 * gap
          ? 4
          : constraints.maxWidth >= 2 * 130 * scale + gap
          ? 2
          : 1;
      return Column(
        children: [
          for (var start = 0; start < children.length; start += maxColumns) ...[
            if (start > 0) const SizedBox(height: gap),
            if (maxColumns == 1)
              SizedBox(width: double.infinity, child: children[start])
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var offset = 0; offset < maxColumns; offset++) ...[
                      if (offset > 0) const SizedBox(width: gap),
                      Expanded(
                        child: start + offset < children.length
                            ? children[start + offset]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      );
    },
  );
}

class LedgerMetricCard extends StatelessWidget {
  const LedgerMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon case final glyph?) ...[
                    Icon(glyph, size: 17, color: theme.colorScheme.primary),
                    const SizedBox(width: 7),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 7),
              Text(value, style: ledgerAmountStyle(theme.textTheme.titleLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class LedgerValueRow extends StatelessWidget {
  const LedgerValueRow({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String? detail;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ledgerAmountStyle(valueStyle ?? theme.textTheme.titleSmall);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final caption = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        if (detail case final subtitle?)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: muted),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final valueWidth = TextPainter.computeWidth(
          text: TextSpan(text: value, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        ).ceilToDouble();
        final minCaption = scaler.scale(14) * 6;
        if (valueWidth + minCaption + 12 > constraints.maxWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              caption,
              const SizedBox(height: 3),
              Text(value, style: style),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: caption),
            const SizedBox(width: 12),
            SizedBox(
              width: valueWidth,
              child: Text(value, style: style, textAlign: TextAlign.end),
            ),
          ],
        );
      },
    );
  }
}

class LedgerIconMark extends StatelessWidget {
  const LedgerIconMark({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colors.onSecondaryContainer, size: 20),
    );
  }
}

class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.caption,
    this.valueColor,
    this.trailing,
    this.details,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;
  final Color? valueColor;
  final Widget? trailing;
  final Widget? details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          14,
          8,
          trailing == null ? 14 : 6,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon case final glyph?) ...[
                  LedgerIconMark(icon: glyph),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: LedgerValueRow(
                      label: label,
                      value: value,
                      detail: caption,
                      labelStyle: theme.textTheme.titleMedium,
                      valueStyle: theme.textTheme.titleMedium?.copyWith(
                        color: valueColor,
                      ),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (details case final content?)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 2,
                  end: 8,
                  bottom: 4,
                ),
                child: content,
              ),
          ],
        ),
      ),
    );
  }
}

class LedgerChoiceBar<T> extends StatelessWidget {
  const LedgerChoiceBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 2,
    children: [
      for (final entry in options.entries)
        ChoiceChip(
          label: Text(entry.value),
          labelPadding: const EdgeInsets.symmetric(horizontal: 3),
          selected: entry.key == selected,
          showCheckmark: false,
          onSelected: onChanged == null
              ? null
              : (picked) {
                  if (picked) onChanged!(entry.key);
                },
        ),
    ],
  );
}
