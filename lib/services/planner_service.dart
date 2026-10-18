import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/planner_item.dart';

class PlannerService extends ChangeNotifier {
  PlannerService._();

  static final PlannerService instance = PlannerService._();
  static const _itemsKey = 'family_planner_items';

  List<PlannerItem> _items = [];
  String? _familyId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemsSubscription;
  Object? _syncError;
  List<PlannerItem> get items => List.unmodifiable(_items);
  Object? get syncError => _syncError;

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

  Future<void> connectToFamily(
    String familyId, {
    bool uploadLocalData = false,
  }) async {
    final localItems = List<PlannerItem>.of(_items);
    await _itemsSubscription?.cancel();
    _familyId = familyId;
    _syncError = null;
    final collection = FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('items');
    final firstSnapshot = Completer<QuerySnapshot<Map<String, dynamic>>>();
    _itemsSubscription = collection.snapshots().listen(
      (snapshot) {
        try {
          _items = snapshot.docs
              .map((doc) => PlannerItem.fromJson(doc.data()))
              .toList();
          _syncError = null;
          notifyListeners();
          if (!firstSnapshot.isCompleted) {
            firstSnapshot.complete(snapshot);
          }
        } catch (error, stackTrace) {
          _syncError = error;
          notifyListeners();
          if (!firstSnapshot.isCompleted) {
            firstSnapshot.completeError(error, stackTrace);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _syncError = error;
        notifyListeners();
        if (!firstSnapshot.isCompleted) {
          firstSnapshot.completeError(error, stackTrace);
        }
      },
    );
    final snapshot = await firstSnapshot.future;
    if (uploadLocalData && snapshot.docs.isEmpty && localItems.isNotEmpty) {
      for (var start = 0; start < localItems.length; start += 500) {
        final batch = FirebaseFirestore.instance.batch();
        for (final item in localItems.sublist(
          start,
          min(start + 500, localItems.length),
        )) {
          batch.set(
            collection.doc(item.id),
            Map<String, dynamic>.from(item.toJson()),
          );
        }
        await batch.commit();
      }
    }
  }

  Future<void> disconnectFromFamily() async {
    await _itemsSubscription?.cancel();
    _itemsSubscription = null;
    _familyId = null;
    _syncError = null;
    await load();
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
    if (_familyId == null) {
      final encodedItems = items
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setStringList(_itemsKey, encodedItems);
      if (!saved) {
        throw StateError('The list item could not be saved to local storage.');
      }
    } else {
      final collection = FirebaseFirestore.instance
          .collection('families')
          .doc(_familyId)
          .collection('items');
      final oldItemsById = {for (final item in _items) item.id: item};
      final newItemsById = {for (final item in items) item.id: item};
      final batch = FirebaseFirestore.instance.batch();
      var writeCount = 0;

      for (final item in items) {
        final oldItem = oldItemsById[item.id];
        if (oldItem != null &&
            jsonEncode(oldItem.toJson()) == jsonEncode(item.toJson())) {
          continue;
        }
        batch.set(
          collection.doc(item.id),
          Map<String, dynamic>.from(item.toJson()),
        );
        writeCount++;
      }
      for (final id in oldItemsById.keys) {
        if (!newItemsById.containsKey(id)) {
          batch.delete(collection.doc(id));
          writeCount++;
        }
      }
      if (writeCount > 500) {
        throw StateError('Too many list changes to save in one operation.');
      }
      if (writeCount > 0) {
        await batch.commit();
      }
    }

    _items = items;
    notifyListeners();
  }
}
