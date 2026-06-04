import 'package:flutter/foundation.dart';

import '../archive_content_category.dart';
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
    switch (categoryFromMime(mediaType)) {
      case ArchiveContentCategory.image:
      case ArchiveContentCategory.video:
        return _viewableActions;
      case ArchiveContentCategory.document:
      case ArchiveContentCategory.audio:
      case ArchiveContentCategory.archive:
        return _documentActions;
      case ArchiveContentCategory.binary:
        return _baseActions;
    }
  }
}
