import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/planner_item.dart';

class PlannerService extends ChangeNotifier {
  PlannerService._();

  static final PlannerService instance = PlannerService._();
  static const _itemsKey = 'family_planner_items';

  List<PlannerItem> _items = [];
  List<PlannerItem> get items => List.unmodifiable(_items);

  List<PlannerItem> itemsFor(PlannerList list) =>
      List.unmodifiable(_items.where((item) => item.list == list));

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedItems = preferences.getStringList(_itemsKey) ?? [];
    _items = savedItems
        .map(
          (item) =>
              PlannerItem.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
    notifyListeners();
  }

  Future<void> addItem(String title, PlannerList list) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'An item title is required.');
    }
    await _saveItems([
      ..._items,
      PlannerItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmedTitle,
        list: list,
      ),
    ]);
  }

  Future<void> setCompleted(String id, bool isCompleted) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('The list item could not be found.');
    }
    final item = _items[index];
    final updatedItems = [..._items]
      ..[index] = PlannerItem(
        id: item.id,
        title: item.title,
        list: item.list,
        isCompleted: isCompleted,
      );
    await _saveItems(updatedItems);
  }

  Future<void> deleteItem(String id) async {
    final updatedItems = _items.where((item) => item.id != id).toList();
    if (updatedItems.length == _items.length) {
      throw StateError('The list item could not be found.');
    }
    await _saveItems(updatedItems);
  }

  Future<void> _saveItems(List<PlannerItem> items) async {
    final encodedItems = items
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_itemsKey, encodedItems);
    if (!saved) {
      throw StateError('The list item could not be saved to local storage.');
    }

    _items = items;
    notifyListeners();
  }
}
