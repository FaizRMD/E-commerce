import 'dart:async';

import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

// Simple in-memory cache for resolved storage URLs during app session.
class _StorageCacheEntry {
  final String url;
  final DateTime expiresAt;
  _StorageCacheEntry(this.url, this.expiresAt);
}

final Map<String, _StorageCacheEntry> _storageUrlCache = {};
// Cache completed Futures so repeated calls return the same Future instance.
final Map<String, Future<String?>> _storageUrlFutureCache = {};

/// Mengembalikan URL yang bisa dipakai langsung pada Image.network.
/// Jika input sudah URL (http atau public storage), kembalikan langsung.
/// Jika input adalah storage path (mis. 'products/123.jpg'), buat signed URL.
Future<String?> resolveStorageUrl(
  String? input, {
  int expirySeconds = 3600,
}) async {
  if (input == null || input.isEmpty) return null;

  // If already an absolute URL or public storage URL, return as-is
  if (input.startsWith('http') ||
      input.contains('/storage/v1/object/public/')) {
    if (kDebugMode) {
      print('resolveStorageUrl: input appears absolute URL, returning as-is');
    }
    return input;
  }

  final base = input.split('?').first;
  final prefixes = <String>['', 'products/', 'images/', 'assets/images/'];
  final now = DateTime.now();

  // Check existing cache for original input
  final origCached = _storageUrlCache[input];
  if (origCached != null && origCached.expiresAt.isAfter(now)) {
    if (kDebugMode) {
      print('resolveStorageUrl: cache hit for original input');
    }
    return origCached.url;
  }

  // Check cache for possible prefixed paths
  for (final p in prefixes) {
    final key = p + base;
    final cached = _storageUrlCache[key];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      if (kDebugMode) {
        print('resolveStorageUrl: cache hit for $key');
      }
      return cached.url;
    }
  }

  // Try each prefix and request signed URL (reuse in-flight Futures)
  for (final p in prefixes) {
    final path = p + base;
    try {
      if (_storageUrlFutureCache.containsKey(path)) {
        if (kDebugMode) {
          print(
            'resolveStorageUrl: reusing in-flight/completed future for $path',
          );
        }
        return await _storageUrlFutureCache[path]!;
      }

      // Create a completer and store its future so concurrent callers reuse it.
      final completer = Completer<String?>();
      _storageUrlFutureCache[path] = completer.future;

      if (kDebugMode) {
        print('resolveStorageUrl: creating signed-url request for $path');
      }

      final res = await supabase.storage
          .from('product-images')
          .createSignedUrl(path, expirySeconds);
      final url = res.toString();
      if (url.isEmpty) {
        completer.complete(null);
        _storageUrlFutureCache.remove(path);
        continue;
      }

      final expiresAt = DateTime.now().add(
        Duration(
          seconds: expirySeconds > 60 ? expirySeconds - 30 : expirySeconds,
        ),
      );
      final entry = _StorageCacheEntry(url, expiresAt);
      _storageUrlCache[path] = entry;
      _storageUrlCache[input] = entry;

      // complete the in-flight completer and replace with completed future
      completer.complete(url);
      _storageUrlFutureCache[path] = Future.value(url);
      _storageUrlFutureCache[input] = _storageUrlFutureCache[path]!;

      if (kDebugMode) {
        print('resolveStorageUrl: resolved $input -> $path (cached)');
      }
      return await _storageUrlFutureCache[input]!;
    } catch (e) {
      // try next prefix
      if (kDebugMode) {
        print('resolveStorageUrl: error for $path -> $e');
      }
      _storageUrlFutureCache.remove(path);
      continue;
    }
  }

  return null;
}
