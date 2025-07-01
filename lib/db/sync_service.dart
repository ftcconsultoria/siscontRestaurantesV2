import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:http/http.dart' as http;
import 'product_dao.dart';
import 'company_dao.dart';
import 'contact_dao.dart';
import 'order_dao.dart';
import 'order_item_dao.dart';

class SyncService {
  final _dao = ProductDao();
  final _companyDao = CompanyDao();
  final _contactDao = ContactDao();
  final _orderDao = OrderDao();
  final _itemDao = OrderItemDao();

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
      final path = photo['EPRO_FOTO_PATH'] as String?;
      final productPk = photo['EPRO_PK'] as int?;
      if (productPk == null) continue;
      if (path != null && (url == null || !url.startsWith('http')) ) {
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split('/').last;
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
          await _dao.upsertPhoto(productPk, url: publicUrl);
          await file.delete();
        }
      } else if (url != null) {
        await supabase.from('ESTQ_PRODUTO_FOTO').upsert({
          'EPRO_PK': productPk,
          'EPRO_FOTO_URL': url,
        });
      }
    }

    // push local orders
    final localOrders = await _orderDao.getAll();
    for (final o in localOrders) {
      final orderData = Map<String, dynamic>.from(o)..remove('CCOT_NOME');
      if (companyPk != null) {
        orderData['CEMP_PK'] = companyPk;
      }
      await supabase.from('PEDI_DOCUMENTOS').upsert(orderData);

      final items = await _itemDao.getByOrder(o['PDOC_PK'] as int);
      for (final item in items) {
        final itemData = Map<String, dynamic>.from(item)
          ..remove('EPRO_DESCRICAO')
          ..remove('EPRO_COD_EAN');
        await supabase.from('PEDI_ITENS').upsert(itemData);
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

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path_lib.join(dir.path, 'downloaded_photos'));
      await photosDir.create(recursive: true);
      for (final p in photos) {
        final url = p['EPRO_FOTO_URL'] as String?;
        if (url == null) continue;
        final fileName = url.split('/').last;
        final filePath = path_lib.join(photosDir.path, fileName);
        final file = File(filePath);
        if (!await file.exists()) {
          try {
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200) {
              await file.writeAsBytes(response.bodyBytes);
            }
          } catch (_) {}
        }
        p['EPRO_FOTO_PATH'] = filePath;
      }

      await _dao.replaceAllPhotos(photos);
    } else {
      await _dao.replaceAllPhotos([]);
    }

    // pull remote orders
    final baseQuery = supabase.from('PEDI_DOCUMENTOS');

    final remoteOrders = await (companyPk != null
        ? baseQuery
            .select(
                'PDOC_PK, CEMP_PK, PDOC_DT_EMISSAO, PDOC_VLR_TOTAL, CCOT_PK')
            .eq('CEMP_PK', companyPk)
            .order('PDOC_PK', ascending: false)
        : baseQuery
            .select(
                'PDOC_PK, CEMP_PK, PDOC_DT_EMISSAO, PDOC_VLR_TOTAL, CCOT_PK')
            .order('PDOC_PK', ascending: false));

    final orders = List<Map<String, dynamic>>.from(remoteOrders);
    await _orderDao.replaceAll(orders);

    // pull remote items only for retrieved orders
    final orderPks = orders.map((e) => e['PDOC_PK'] as int).toList();
    if (orderPks.isNotEmpty) {
      final pkList = orderPks.join(',');
      final remoteItems = await supabase
          .from('PEDI_ITENS')
          .select(
              'PITEN_PK, PDOC_PK, EPRO_PK, PITEN_QTD, PITEN_VLR_UNITARIO, PITEN_VLR_TOTAL')
          .filter('PDOC_PK', 'in', '($pkList)');
      final items = List<Map<String, dynamic>>.from(remoteItems);
      await _itemDao.replaceAll(items);
    } else {
      await _itemDao.replaceAll([]);
    }
  }

  /// Performs a push followed by a pull.
  Future<void> sync() async {
    await push();
    await pull();
  }
}
