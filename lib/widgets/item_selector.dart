import 'package:flutter/material.dart';

import '../models/item.dart';

Future<Item?> showItemSelector(
  BuildContext context, {
  required List<Item> items,
  Item? selectedItem,
}) async {
  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _ItemSelectionSheet(items: items, selectedItem: selectedItem),
  );
}

class ItemSelectField extends StatelessWidget {
  const ItemSelectField({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
  });

  final List<Item> items;
  final Item? selectedItem;
  final ValueChanged<Item> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final selected = await showItemSelector(
          context,
          items: items,
          selectedItem: selectedItem,
        );
        if (selected != null) onSelected(selected);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Item Type *',
          prefixIcon: Icon(Icons.category_outlined),
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          selectedItem?.name ?? 'Choose an item',
          style: selectedItem == null
              ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        ),
      ),
    );
  }
}

class _ItemSelectionSheet extends StatefulWidget {
  const _ItemSelectionSheet({required this.items, this.selectedItem});

  final List<Item> items;
  final Item? selectedItem;

  @override
  State<_ItemSelectionSheet> createState() => _ItemSelectionSheetState();
}

class _ItemSelectionSheetState extends State<_ItemSelectionSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final categories = visibleItems.map((item) => item.category).toSet();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search item name',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final category in categories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final item in visibleItems.where(
                      (entry) => entry.category == category,
                    ))
                      ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.unit),
                        trailing: widget.selectedItem?.id == item.id
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.secondary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
