import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_dao.dart';

class SyncService {
  final _dao = ProductDao();

  /// Pushes local changes to Supabase and pulls remote updates.
  Future<void> sync() async {
    final supabase = Supabase.instance.client;

    // push local products
    final localProducts = await _dao.getAll();
    for (final p in localProducts) {
      final data = Map<String, dynamic>.from(p)..remove('ESTQ_PRODUTO_FOTO');
      await supabase.from('ESTQ_PRODUTO').upsert(data);
    }

    // push local photos
    final localPhotos = await _dao.getAllPhotos();
    for (final photo in localPhotos) {
      final url = photo['EPRO_FOTO_URL'] as String?;
      final productPk = photo['EPRO_PK'] as int?;
      if (url == null || productPk == null) continue;
      if (!url.startsWith('http')) {
        final file = File(url);
        if (await file.exists()) {
          final fileName = url.split('/').last;
          final path = '$productPk/$fileName';
          await supabase.storage.from('fotos-produtos').uploadBinary(path, await file.readAsBytes());
          final publicUrl = supabase.storage.from('fotos-produtos').getPublicUrl(path);
          await supabase.from('ESTQ_PRODUTO_FOTO').upsert({
            'EPRO_PK': productPk,
            'EPRO_FOTO_URL': publicUrl,
          });
          await _dao.upsertPhoto(productPk, publicUrl);
          await file.delete();
        }
      } else {
        await supabase.from('ESTQ_PRODUTO_FOTO').upsert({
          'EPRO_PK': productPk,
          'EPRO_FOTO_URL': url,
        });
      }
    }

    // pull remote products
    final remote = await supabase
        .from('ESTQ_PRODUTO')
        .select('EPRO_PK, EPRO_DESCRICAO, EPRO_VLR_VAREJO, EPRO_ESTQ_ATUAL, EPRO_COD_EAN')
        .order('EPRO_DESCRICAO');
    final list = List<Map<String, dynamic>>.from(remote);
    await _dao.replaceAll(list);

    // pull remote photos
    final remotePhotos = await supabase
        .from('ESTQ_PRODUTO_FOTO')
        .select('EPRO_FOTO_PK, EPRO_PK, EPRO_FOTO_URL');
    final photos = List<Map<String, dynamic>>.from(remotePhotos);
    await _dao.replaceAllPhotos(photos);
  }
}
