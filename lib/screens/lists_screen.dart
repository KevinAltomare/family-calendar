import 'package:flutter/material.dart';

import '../models/planner_item.dart';
import '../services/planner_service.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: AnimatedBuilder(
        animation: PlannerService.instance,
        builder: (context, _) {
          final shoppingItems = PlannerService.instance.itemsFor(
            PlannerList.shopping,
          );
          final todoItems = PlannerService.instance.itemsFor(PlannerList.todo);
          final remaining = PlannerService.instance.items
              .where((item) => !item.isCompleted)
              .length;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAMILY PLANNER',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our lists',
                        style: TextStyle(
                          color: Color(0xFF202A38),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining == 0
                            ? 'A space for anything we need to remember.'
                            : '$remaining ${remaining == 1 ? 'thing' : 'things'} left to take care of',
                        style: const TextStyle(
                          color: Color(0xFF7B8491),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _PlannerListCard(
                    title: 'Groceries',
                    icon: Icons.shopping_basket_outlined,
                    color: const Color(0xFF557B64),
                    items: shoppingItems,
                    onAdd: () => _addItem(context, PlannerList.shopping),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverToBoxAdapter(
                  child: _PlannerListCard(
                    title: 'To-do',
                    icon: Icons.checklist_rounded,
                    color: colors.primary,
                    items: todoItems,
                    onAdd: () => _addItem(context, PlannerList.todo),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addItem(BuildContext context, PlannerList list) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _AddItemDialog(list: list),
    );
    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }

    try {
      await PlannerService.instance.addItem(title, list);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save item: $error')));
    }
  }
}

class _AddItemDialog extends StatefulWidget {
  final PlannerList list;

  const _AddItemDialog({required this.list});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isShopping = widget.list == PlannerList.shopping;
    return AlertDialog(
      title: Text(isShopping ? 'Add to shopping' : 'Add a to-do'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: isShopping
              ? 'e.g. Milk'
              : 'e.g. Book a dentist appointment',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _PlannerListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<PlannerItem> items;
  final VoidCallback onAdd;

  const _PlannerListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF202A38),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add to $title',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  color: color,
                ),
              ],
            ),
            if (items.isEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nothing here yet. Add the first item.',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              for (final item in items) _PlannerItemTile(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlannerItemTile extends StatelessWidget {
  final PlannerItem item;

  const _PlannerItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: item.isCompleted,
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            try {
              await PlannerService.instance.setCompleted(item.id, value);
            } catch (error) {
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not update item: $error')),
              );
            }
          },
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        Expanded(
          child: Text(
            item.title,
            style: TextStyle(
              color: item.isCompleted
                  ? const Color(0xFF9AA1AB)
                  : const Color(0xFF303A48),
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Remove ${item.title}',
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            try {
              await PlannerService.instance.deleteItem(item.id);
            } catch (error) {
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not remove item: $error')),
              );
            }
          },
          icon: const Icon(Icons.close_rounded, size: 18),
          color: const Color(0xFF9AA1AB),
        ),
      ],
    );
  }
}
