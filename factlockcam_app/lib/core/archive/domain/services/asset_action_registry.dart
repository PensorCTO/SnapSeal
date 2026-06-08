import 'package:flutter/foundation.dart';

import '../archive_content_category.dart';
import '../models/media_action_type.dart';

class AssetActionRegistry {
  const AssetActionRegistry._();

  static const _studioActions = <MediaActionType>[
    MediaActionType.view,
    MediaActionType.export,
    MediaActionType.printCertificate,
    MediaActionType.delete,
  ];

  static const _binaryActions = <MediaActionType>[
    MediaActionType.export,
    MediaActionType.printCertificate,
    MediaActionType.delete,
  ];

  /// Returns the actions available for [mediaType] on the current platform.
  static List<MediaActionType> getActionsForType(String mediaType) {
    final actions = _resolveActions(mediaType);
    if (kIsWeb) {
      return actions
          .where((a) => a != MediaActionType.export)
          .toList(growable: false);
    }
    return actions;
  }

  static List<MediaActionType> _resolveActions(String mediaType) {
    switch (categoryFromMime(mediaType)) {
      case ArchiveContentCategory.image:
      case ArchiveContentCategory.video:
      case ArchiveContentCategory.document:
      case ArchiveContentCategory.audio:
      case ArchiveContentCategory.archive:
        return _studioActions;
      case ArchiveContentCategory.binary:
        return _binaryActions;
    }
  }
}
