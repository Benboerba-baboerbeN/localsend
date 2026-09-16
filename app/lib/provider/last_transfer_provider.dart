import 'package:localsend_app/model/persistence/last_transfer.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:refena_flutter/refena_flutter.dart';

final lastTransferProvider = NotifierProvider<LastTransferService, LastTransferRecord?>((ref) {
  return LastTransferService(ref.read(persistenceProvider));
});

class LastTransferService extends PureNotifier<LastTransferRecord?> {
  final PersistenceService _persistence;

  LastTransferService(this._persistence);

  @override
  LastTransferRecord? init() {
    final persisted = _persistence.getLastTransfer();
    if (persisted != null) {
      return persisted;
    }

    final receiveHistory = _persistence.getReceiveHistory();
    if (receiveHistory.isEmpty) {
      return null;
    }

    final latest = receiveHistory.first;
    return LastTransferRecord(
      direction: LastTransferDirection.received,
      type: _mapType(latest.fileType),
      completedAt: latest.timestamp,
    );
  }

  Future<void> record({required LastTransferDirection direction, required Iterable<FileType> fileTypes}) async {
    final types = fileTypes.toSet();
    if (types.isEmpty) {
      return;
    }

    final record = LastTransferRecord(
      direction: direction,
      type: types.length == 1 ? _mapType(types.single) : LastTransferType.multiple,
      completedAt: DateTime.now().toUtc(),
    );
    await _persistence.setLastTransfer(record);
    state = record;
  }
}

LastTransferType _mapType(FileType type) {
  return switch (type) {
    FileType.image => LastTransferType.image,
    FileType.video => LastTransferType.video,
    FileType.pdf => LastTransferType.pdf,
    FileType.text => LastTransferType.text,
    FileType.apk => LastTransferType.apk,
    FileType.other => LastTransferType.other,
  };
}
