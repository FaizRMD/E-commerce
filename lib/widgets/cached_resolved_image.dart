import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/storage_utils.dart';

/// Widget yang memastikan resolved signed URL hanya diminta sekali dan
/// melakukan precache sehingga tidak ada "spinner" atau reload berulang.
class CachedResolvedImage extends StatefulWidget {
  const CachedResolvedImage(
    this.imagePath, {
    Key? key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  final String? imagePath; // bisa berupa storage path atau absolute URL
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<CachedResolvedImage> createState() => _CachedResolvedImageState();
}

class _CachedResolvedImageState extends State<CachedResolvedImage> {
  String? _resolvedUrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initResolve();
  }

  Future<void> _initResolve() async {
    final img = widget.imagePath;
    if (img == null || img.isEmpty) return;

    // If absolute URL, use directly and precache
    if (img.startsWith('http')) {
      _resolvedUrl = img;
      await _precacheIfPossible(_resolvedUrl!);
      if (mounted) setState(() {});
      return;
    }

    try {
      final url = await resolveStorageUrl(img);
      if (url != null && url.isNotEmpty) {
        _resolvedUrl = url;
        await _precacheIfPossible(_resolvedUrl!);
      } else {
        _failed = true;
      }
    } catch (e) {
      if (kDebugMode) print('CachedResolvedImage: resolve failed $e');
      _failed = true;
    }

    if (mounted) setState(() {});
  }

  Future<void> _precacheIfPossible(String url) async {
    try {
      final provider = CachedNetworkImageProvider(url);
      await precacheImage(provider, context);
    } catch (_) {
      // ignore precache failures; image will still load normally
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.imagePath;
    if (img == null || img.isEmpty) {
      return widget.errorWidget ?? const SizedBox.shrink();
    }

    final stableKey = img.split('?').first;

    if (_failed) {
      return widget.errorWidget ?? const Icon(Icons.broken_image_outlined);
    }

    if (_resolvedUrl == null) {
      // still resolving: show placeholder but keep layout size
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    return CachedNetworkImage(
      imageUrl: _resolvedUrl!,
      cacheKey: stableKey,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (_, __) => widget.placeholder ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          widget.errorWidget ?? const Icon(Icons.broken_image_outlined),
      useOldImageOnUrlChange: true,
    );
  }
}
