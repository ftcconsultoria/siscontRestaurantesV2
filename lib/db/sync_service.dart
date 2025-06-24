import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_dao.dart';

class SyncService {
  final _dao = ProductDao();

  /// Pushes local changes to Supabase and pulls remote updates.
  Future<void> sync() async {
    final supabase = Supabase.instance.client;

    // push local data
    final localProducts = await _dao.getAll();
    for (final p in localProducts) {
      await supabase.from('ESTQ_PRODUTO').upsert(p);
    }

    // pull remote data
    final remote = await supabase
        .from('ESTQ_PRODUTO')
        .select('EPRO_PK, EPRO_DESCRICAO, EPRO_VLR_VAREJO, EPRO_ESTQ_ATUAL, EPRO_COD_EAN')
        .order('EPRO_DESCRICAO');
    final list = List<Map<String, dynamic>>.from(remote);
    await _dao.replaceAll(list);
  }
}
