import 'package:taskduo/data/local_store.dart';

class TestStore implements LocalStore {
  String? value;
  bool failWrites = false;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('Device storage is unavailable');
    this.value = value;
    writes++;
  }
}
