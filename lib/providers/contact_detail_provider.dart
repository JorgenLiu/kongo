import 'base_provider.dart';
import '../services/read/contact_read_service.dart';

class ContactDetailProvider extends BaseProvider {
  final ContactReadService _contactReadService;
  final String _contactId;

  ContactDetailProvider(this._contactReadService, this._contactId);

  ContactDetailReadModel? _data;

  ContactDetailReadModel? get data => _data;

  Future<void> load() async {
    await execute(() async {
      _data = await _contactReadService.getContactDetail(_contactId);
      markInitialized();
    });
  }

  Future<void> refresh() => load();
}