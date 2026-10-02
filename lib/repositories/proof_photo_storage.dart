import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/proof_photo.dart';

/// Thrown when an upload did not finish within its timeout. The upload task is
/// cancelled first; if the bytes had already landed (cancel came too late),
/// the upload counts as done instead. A cancel that fails leaves the caller to
/// delete the object best-effort, since nothing will point at it.
class ProofUploadTimeoutException implements Exception {
  const ProofUploadTimeoutException();

  @override
  String toString() => 'ProofUploadTimeoutException';
}

/// Blob storage for proof photos (인증샷), addressed by Storage path.
///
/// Only paths are ever stored in Firestore; reads go through the Storage
/// security rules (owner, or the plan's current partner).
abstract class ProofPhotoStorage {
  /// Uploads [jpegBytes] to [path] as `image/jpeg`. Throws
  /// [ProofUploadTimeoutException] after [timeout], having cancelled the task
  /// — unless the upload finished anyway, which returns normally so the
  /// caller records the photo.
  Future<void> upload(
    String path,
    Uint8List jpegBytes, {
    Duration timeout = kProofUploadTimeout,
  });

  /// The bytes at [path] (null if the object is gone). Throws when the read is
  /// denied, e.g. after the couple disconnected.
  Future<Uint8List?> download(String path);

  /// Deletes the object at [path]; a missing object is not an error.
  Future<void> delete(String path);
}

/// [ProofPhotoStorage] on Firebase Storage.
class FirebaseProofPhotoStorage implements ProofPhotoStorage {
  FirebaseProofPhotoStorage({FirebaseStorage? storage}) : _storage = storage;

  FirebaseStorage? _storage;

  /// Resolved lazily so constructing a repository never touches Firebase
  /// (tests build repositories without a Firebase app).
  FirebaseStorage get _instance => _storage ??= FirebaseStorage.instance;

  @override
  Future<void> upload(
    String path,
    Uint8List jpegBytes, {
    Duration timeout = kProofUploadTimeout,
  }) async {
    final task = _instance
        .ref(path)
        .putData(jpegBytes, SettableMetadata(contentType: 'image/jpeg'));
    try {
      await task.timeout(timeout);
    } on TimeoutException {
      var cancelled = false;
      try {
        cancelled = await task.cancel();
      } catch (e) {
        debugPrint('[ProofPhotoStorage] cancel after timeout failed: $e');
      }
      // cancel() is a no-op on a task that already completed: the photo is
      // there, so report it as uploaded rather than leaving an object that
      // nothing points at (and telling the user it wasn't sent).
      if (!cancelled && task.snapshot.state == TaskState.success) return;
      throw const ProofUploadTimeoutException();
    }
  }

  @override
  Future<Uint8List?> download(String path) {
    return _instance.ref(path).getData(kProofMaxBytes + 512 * 1024);
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _instance.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }
}
