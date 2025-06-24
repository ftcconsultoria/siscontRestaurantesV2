import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_dao.dart';
import 'company_dao.dart';
import 'contact_dao.dart';

class SyncService {
  final _dao = ProductDao();
  final _companyDao = CompanyDao();
  final _contactDao = ContactDao();

  Future<int?> _companyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  /// Pushes local changes to Supabase.
  Future<void> push() async {
    final supabase = Supabase.instance.client;
    final companyPk = await _companyPk();

    // push local products
    final localProducts = await _dao.getAll();
    for (final p in localProducts) {
      final data = Map<String, dynamic>.from(p)..remove('ESTQ_PRODUTO_FOTO');
      if (companyPk != null) {
        data['CEMP_PK'] = companyPk;
      }
      await supabase.from('ESTQ_PRODUTO').upsert(data);
    }

    // push local clients
    final localClients = await _contactDao.getAll();
    for (final c in localClients) {
      final data = Map<String, dynamic>.from(c);
      if (companyPk != null) {
        data['CEMP_PK'] = companyPk;
      }
      await supabase.from('CADE_CONTATO').upsert(data);
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
          await supabase.storage
              .from('fotos-produtos')
              .uploadBinary(path, await file.readAsBytes());
          final publicUrl =
              supabase.storage.from('fotos-produtos').getPublicUrl(path);
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
  }

  /// Pulls remote data from Supabase and updates local tables.
  Future<void> pull() async {
    final supabase = Supabase.instance.client;
    final companyPk = await _companyPk();

    // pull remote products
    final remoteQuery = supabase
        .from('ESTQ_PRODUTO')
        .select(
            'EPRO_PK, EPRO_DESCRICAO, EPRO_VLR_VAREJO, EPRO_ESTQ_ATUAL, EPRO_COD_EAN, CEMP_PK')
        .order('EPRO_DESCRICAO');
    final remote = companyPk != null
        ? await supabase
            .from('ESTQ_PRODUTO')
            .select(
                'EPRO_PK, EPRO_DESCRICAO, EPRO_VLR_VAREJO, EPRO_ESTQ_ATUAL, EPRO_COD_EAN, CEMP_PK')
            .eq('CEMP_PK', companyPk)
            .order('EPRO_DESCRICAO')
        : await remoteQuery;
    final list = List<Map<String, dynamic>>.from(remote);
    await _dao.replaceAll(list);

    // pull remote photos only for retrieved products
    final productPks = list.map((e) => e['EPRO_PK'] as int).toList();
    if (productPks.isNotEmpty) {
      final pkList = productPks.join(',');
      final remotePhotos = await supabase
          .from('ESTQ_PRODUTO_FOTO')
          .select('EPRO_FOTO_PK, EPRO_PK, EPRO_FOTO_URL')
          .filter('EPRO_PK', 'in', '($pkList)');
      final photos = List<Map<String, dynamic>>.from(remotePhotos);
      await _dao.replaceAllPhotos(photos);
    } else {
      await _dao.replaceAllPhotos([]);
    }
  }

  /// Performs a push followed by a pull.
  Future<void> sync() async {
    await push();
    await pull();
  }
}
