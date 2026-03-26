import '../services/read/home_read_service.dart';
import 'base_provider.dart';

class HomeProvider extends BaseProvider {
  final HomeReadService _readService;

  HomeProvider(this._readService);

  HomeReadModel? _data;
  HomeReadModel? get data => _data;

  Future<void> load() async {
    await execute(() async {
      _data = await _readService.loadWorkbench();
      markInitialized();
    });
  }

  Future<void> refresh() async {
    await execute(() async {
      _data = await _readService.loadWorkbench();
    });
  }
}
