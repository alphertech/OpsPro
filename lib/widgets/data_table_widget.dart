import 'dart:math';

import 'package:flutter/material.dart';

class DataTableWidget extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool showCheckbox;
  final double? rowHeight;
  final double? columnSpacing;
  final bool isStriped;
  final bool expandToWidth;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.showCheckbox = false,
    this.rowHeight,
    this.columnSpacing = 16,
    this.isStriped = true,
    this.expandToWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minHeight = rowHeight ?? 44.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = columnSpacing ?? 16;
    const horizontalMargin = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final target =
            min(available, max(available * 0.98, screenWidth * 0.9));
        final effectiveTarget =
            target.isFinite && target > 0 ? target : available;

        double? perColumn;
        final minWidth = expandToWidth ? effectiveTarget : 0.0;
        if (expandToWidth && effectiveTarget > 0 && columns.isNotEmpty) {
          final usable = effectiveTarget -
              2 * horizontalMargin -
              spacing * (columns.length - 1);
          perColumn = max(0.0, usable / columns.length);
        }

        DataColumn applyWidth(DataColumn column) {
          if (perColumn == null) return column;
          return DataColumn(
            label: SizedBox(width: perColumn, child: column.label),
            numeric: column.numeric,
            tooltip: column.tooltip,
            onSort: column.onSort,
          );
        }

        DataCell applyCellWidth(DataCell cell) {
          if (perColumn == null) return cell;
          return DataCell(
            SizedBox(
              width: perColumn,
              child: cell.child,
            ),
            placeholder: cell.placeholder,
            showEditIcon: cell.showEditIcon,
            onTap: cell.onTap,
            onLongPress: cell.onLongPress,
            onTapCancel: cell.onTapCancel,
            onDoubleTap: cell.onDoubleTap,
          );
        }

        final builtRows = rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final cells = row.cells.map(applyCellWidth).toList();
          if (isStriped && index % 2 == 0) {
            return DataRow(
              key: row.key,
              color: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
              cells: cells,
              onSelectChanged: row.onSelectChanged,
              selected: row.selected,
            );
          }
          return DataRow(
            key: row.key,
            cells: cells,
            onSelectChanged: row.onSelectChanged,
            selected: row.selected,
          );
        }).toList();

        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: minWidth,
                  maxWidth: expandToWidth ? effectiveTarget : double.infinity,
                ),
                child: DataTable(
                  columns: columns.map(applyWidth).toList(),
                  rows: builtRows,
                  showCheckboxColumn: showCheckbox,
                  headingRowHeight: 44,
                  dataRowMinHeight: minHeight,
                  dataRowMaxHeight: minHeight,
                  columnSpacing: spacing,
                  horizontalMargin: horizontalMargin,
                  headingTextStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                  ),
                  dataTextStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}