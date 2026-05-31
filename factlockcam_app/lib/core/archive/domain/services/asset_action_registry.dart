import 'package:flutter/foundation.dart';

import '../models/media_action_type.dart';

class AssetActionRegistry {
  const AssetActionRegistry._();

  static const _baseActions = <MediaActionType>[
    MediaActionType.verify,
    MediaActionType.delete,
  ];

  static const _viewableActions = <MediaActionType>[
    MediaActionType.view,
    MediaActionType.verify,
    MediaActionType.export,
    MediaActionType.share,
    MediaActionType.delete,
  ];

  static const _documentActions = <MediaActionType>[
    MediaActionType.view,
    MediaActionType.verify,
    MediaActionType.export,
    MediaActionType.share,
    MediaActionType.delete,
  ];

  /// Returns the actions available for [mediaType] on the current platform.
  ///
  /// On the web [MediaActionType.verify] is excluded because
  /// `VaultService.extractForCourier` requires the local filesystem
  /// (`dart:io`) and is mobile-only.
  static List<MediaActionType> getActionsForType(String mediaType) {
    final actions = _resolveActions(mediaType);
    if (kIsWeb) {
      return actions
          .where(
            (a) =>
                a != MediaActionType.verify && a != MediaActionType.export,
          )
          .toList(growable: false);
    }
    return actions;
  }

  static List<MediaActionType> _resolveActions(String mediaType) {
    switch (_normalizeMediaType(mediaType)) {
      case _AssetMediaKind.picture:
      case _AssetMediaKind.video:
        return _viewableActions;
      case _AssetMediaKind.document:
        return _documentActions;
      case _AssetMediaKind.unknown:
        return _baseActions;
    }
  }

  static _AssetMediaKind _normalizeMediaType(String mediaType) {
    final normalized = mediaType.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _AssetMediaKind.unknown;
    }

    if (normalized == 'picture' ||
        normalized == 'photo' ||
        normalized == 'image' ||
        normalized.startsWith('image/')) {
      return _AssetMediaKind.picture;
    }

    if (normalized == 'video' || normalized.startsWith('video/')) {
      return _AssetMediaKind.video;
    }

    if (normalized == 'document' ||
        normalized == 'pdf' ||
        normalized == 'application/pdf' ||
        normalized.startsWith('text/') ||
        normalized.startsWith('application/')) {
      return _AssetMediaKind.document;
    }

    return _AssetMediaKind.unknown;
  }
}

enum _AssetMediaKind { picture, video, document, unknown }
