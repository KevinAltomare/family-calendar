import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_service.dart';
import 'planner_service.dart';

class FamilyService {
  FamilyService._();

  static final FamilyService instance = FamilyService._();

  Future<void>? _googleSignInInitialization;
  String? familyId;
  String? familyName;
  String? inviteCode;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      return;
    }

    await (_googleSignInInitialization ??= GoogleSignIn.instance.initialize());
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google sign-in did not return an ID token. Check the Android OAuth '
        'configuration and SHA-1 fingerprints.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<String?> savedFamilyId(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_familyKey(userId));
  }

  Future<void> clearFamily(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_familyKey(userId));
    if (!removed) {
      throw StateError('The saved family could not be cleared.');
    }
    await Future.wait([
      CalendarService.instance.disconnectFromFamily(),
      PlannerService.instance.disconnectFromFamily(),
    ]);
    familyId = null;
    familyName = null;
    inviteCode = null;
  }

  Future<String> createFamily(String name, String userId) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'A family name is required.');
    }

    final firestore = FirebaseFirestore.instance;
    final family = firestore.collection('families').doc();
    final code = _newInviteCode();
    final batch = firestore.batch();
    batch.set(family, {
      'name': trimmedName,
      'memberIds': [userId],
      'createdBy': userId,
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(firestore.collection('familyInvites').doc(code), {
      'familyId': family.id,
    });
    await batch.commit();
    await _saveFamilyId(userId, family.id);
    return family.id;
  }

  Future<String> joinFamily(String code, String userId) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw ArgumentError.value(code, 'code', 'An invite code is required.');
    }

    final firestore = FirebaseFirestore.instance;
    final invite = await firestore
        .collection('familyInvites')
        .doc(normalizedCode)
        .get()
        .catchError((Object error) {
          throw StateError('Could not look up the family invite: $error');
        });
    final invitedFamilyId = invite.data()?['familyId'] as String?;
    if (!invite.exists || invitedFamilyId == null) {
      throw StateError('That family invite code was not found.');
    }
    await firestore
        .collection('families')
        .doc(invitedFamilyId)
        .update({
          'memberIds': FieldValue.arrayUnion([userId]),
        })
        .catchError((Object error) {
          throw StateError(
            'The invite was found, but Firebase denied adding this Google account '
            'to the family: $error',
          );
        });
    await _saveFamilyId(userId, invitedFamilyId);
    return invitedFamilyId;
  }

  Future<void> connectToFamily(
    String id, {
    bool uploadLocalData = false,
  }) async {
    final family = await FirebaseFirestore.instance
        .collection('families')
        .doc(id)
        .get();
    final data = family.data();
    if (!family.exists || data == null) {
      throw StateError('The family could not be found.');
    }

    try {
      await Future.wait([
        CalendarService.instance.connectToFamily(
          id,
          uploadLocalData: uploadLocalData,
        ),
        PlannerService.instance.connectToFamily(
          id,
          uploadLocalData: uploadLocalData,
        ),
      ]);
    } catch (_) {
      await Future.wait([
        CalendarService.instance.disconnectFromFamily(),
        PlannerService.instance.disconnectFromFamily(),
      ]);
      rethrow;
    }

    familyId = id;
    familyName = data['name'] as String?;
    inviteCode = data['inviteCode'] as String?;
  }

  Future<void> _saveFamilyId(String userId, String id) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_familyKey(userId), id);
    if (!saved) {
      throw StateError('The family could not be saved on this device.');
    }
  }

  String _familyKey(String userId) => 'family_id_$userId';

  String _newInviteCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      12,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }
}
