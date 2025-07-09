import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'product_dao.dart';
import 'company_dao.dart';
import 'contact_dao.dart';
import 'order_dao.dart';
import 'order_item_dao.dart';
import 'log_event_dao.dart';
import 'user_dao.dart';

class SyncService {
  final _dao = ProductDao();
  final _companyDao = CompanyDao();
  final _contactDao = ContactDao();
  final _orderDao = OrderDao();
  final _itemDao = OrderItemDao();
  final _logDao = LogEventDao();
  final _userDao = UserDao();

  Future<int?> _companyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  Future<String?> _companyCnpj() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_CNPJ'] as String?;
  }

  Future<int?> _vendorPk() async {
    final prefs = await SharedPreferences.getInstance();
    final userPk = prefs.getInt('logged_user_pk');
    if (userPk == null) return null;
    final user = await _userDao.getByPk(userPk);
    return user?['CCOT_VEND_PK'] as int?;
  }

  /// Pushes local changes to Supabase.
  Future<void> push({
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    try {
    final supabase = Supabase.instance.client;
    final companyPk = await _companyPk();
    final companyCnpj = await _companyCnpj();

    // gather local data counts
    final localProducts = await _dao.getAll();
    final localClients = await _contactDao.getAll();
    final localPhotos = await _dao.getAllPhotos();
    final localOrders = await _orderDao.getPending();
    final localLogs = await _logDao.getAll();

    int total = localProducts.length +
        localClients.length +
        localPhotos.length +
        localOrders.length +
        localLogs.length;

    for (final o in localOrders) {
      final orderPk = o['PDOC_PK'] as int?;
      if (orderPk != null) {
        final items = await _itemDao.getByOrder(orderPk);
        total += items.length;
      }
    }

    int completed = 0;
    void report() {
      if (onProgress != null && total > 0) {
        onProgress(completed / total);
      }
    }

    // push local products
    onStatus?.call('Produtos');
    for (final _ in localProducts) {
      // Product registration is kept local only.
      completed++;
      report();
    }

    // push local clients
    onStatus?.call('Clientes');
    for (final c in localClients) {
      final data = Map<String, dynamic>.from(c);
      if (companyPk != null) {
        data['CEMP_PK'] = companyPk;
      }
      await supabase.from('CADE_CONTATO').upsert(data);
      completed++;
      report();
    }

    // push local photos
    for (final photo in localPhotos) {
      final url = photo['EPRO_FOTO_URL'] as String?;
      final path = photo['EPRO_FOTO_PATH'] as String?;
      final productPk = photo['EPRO_PK'] as int?;
      if (productPk == null) continue;
      if (path != null && (url == null || !url.startsWith('http'))) {
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split('/').last;
          final productCode =
              (photo['EPRO_COD_EAN'] ?? productPk).toString();
          final uploadPath =
              '${companyCnpj ?? 'sem_cnpj'}/$productCode/$fileName';
          await supabase.storage
              .from('fotos-produtos')
              .uploadBinary(uploadPath, await file.readAsBytes());
          final publicUrl =
              supabase.storage.from('fotos-produtos').getPublicUrl(uploadPath);
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
      completed++;
      report();
    }

    // push local orders
    onStatus?.call('Pedidos');
    for (final o in localOrders) {
      final orderPk = o['PDOC_PK'] as int?;
      final orderData = Map<String, dynamic>.from(o);
      orderData.remove('CCOT_NOME');
      if (companyPk != null) {
        orderData['CEMP_PK'] = companyPk;
      }
      orderData['PDOC_ESTADO_PEDIDO'] = 'ENVIADO_CLOUD';
      await supabase.from('PEDI_DOCUMENTOS').upsert(orderData);

      if (orderPk != null) {
        final items = await _itemDao.getByOrder(orderPk);
        for (final item in items) {
          final itemData = Map<String, dynamic>.from(item)
            ..remove('EPRO_DESCRICAO')
            ..remove('EPRO_COD_EAN')
            ..remove('EPRO_ESTQ_ATUAL');
          await supabase.from('PEDI_ITENS').upsert(itemData);
          completed++;
          report();
        }
        await _orderDao.updateStatus(orderPk, 'ENVIADO_CLOUD');
      }
      completed++;
      report();
    }

    // push local logs
    for (final log in localLogs) {
      final logData = Map<String, dynamic>.from(log)
        ..remove('LOG_PK');
      await supabase.from('SIS_LOG_EVENTO').insert(logData);
      completed++;
      report();
    }
    if (localLogs.isNotEmpty) {
      await _logDao.deleteAll();
    }
    report();
    } catch (e, s) {
      await _logDao.insert(
        entidade: 'SYNC',
        tipo: 'ERRO_EXPORT',
        tela: 'SyncService',
        mensagem: e.toString(),
        dados: {'stack': s.toString()},
      );
      rethrow;
    }
  }

  /// Pulls remote data from Supabase and updates local tables.
  Future<void> pull({void Function(double progress)? onProgress}) async {
    try {
    final supabase = Supabase.instance.client;
    final companyPk = await _companyPk();

    const totalSteps = 5;
    int step = 0;
    void report() => onProgress?.call(step / totalSteps);
    report();

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
    step++;
    report();

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
    step++;
    report();

    // pull remote clients
    final contactQuery = supabase
        .from('CADE_CONTATO')
        .select(
            'CCOT_PK, CCOT_NOME, CCOT_FANTASIA, CCOT_CNPJ, CCOT_IE, CCOT_END_CEP, CCOT_END_NOME_LOGRADOURO, CCOT_END_COMPLEMENTO, CCOT_END_QUADRA, CCOT_END_LOTE, CCOT_END_NUMERO, CCOT_END_BAIRRO, CCOT_END_MUNICIPIO, CCOT_END_CODIGO_IBGE, CCOT_END_UF, CCOT_END_LAT, CCOT_END_LON, CEMP_PK, CCOT_TP_PESSOA')
        .order('CCOT_NOME');
    final remoteContacts = companyPk != null
        ? await supabase
            .from('CADE_CONTATO')
            .select(
                'CCOT_PK, CCOT_NOME, CCOT_FANTASIA, CCOT_CNPJ, CCOT_IE, CCOT_END_CEP, CCOT_END_NOME_LOGRADOURO, CCOT_END_COMPLEMENTO, CCOT_END_QUADRA, CCOT_END_LOTE, CCOT_END_NUMERO, CCOT_END_BAIRRO, CCOT_END_MUNICIPIO, CCOT_END_CODIGO_IBGE, CCOT_END_UF, CCOT_END_LAT, CCOT_END_LON, CEMP_PK, CCOT_TP_PESSOA')
            .eq('CEMP_PK', companyPk)
            .order('CCOT_NOME')
        : await contactQuery;
    final contacts = List<Map<String, dynamic>>.from(remoteContacts);
    await _contactDao.replaceAll(contacts);
    step++;
    report();

    // pull remote orders
    final vendorPk = await _vendorPk();
    var query = supabase
        .from('PEDI_DOCUMENTOS')
        .select('PDOC_PK, PDOC_UUID, CEMP_PK, PDOC_DT_EMISSAO, PDOC_VLR_TOTAL, CCOT_PK, CCOT_VEND_PK, PDOC_ESTADO_PEDIDO');

    if (companyPk != null) {
      query = query.eq('CEMP_PK', companyPk);
    }
    if (vendorPk != null) {
      query = query.eq('CCOT_VEND_PK', vendorPk);
    }

    final orderQuery = query.order('PDOC_PK', ascending: false);
    final remoteOrders = await orderQuery;

    final orders = List<Map<String, dynamic>>.from(remoteOrders);
    await _orderDao.replaceAll(orders);
    step++;
    report();

    // pull remote items only for retrieved orders
    final orderPks = orders.map((e) => e['PDOC_PK'] as int).toList();
    if (orderPks.isNotEmpty) {
      final pkList = orderPks.join(',');
      final remoteItems = await supabase
          .from('PEDI_ITENS')
          .select(
              'PITEN_PK, PDOC_UUID, PDOC_PK, EPRO_PK, PITEN_QTD, PITEN_VLR_UNITARIO, PITEN_VLR_TOTAL')
          .filter('PDOC_PK', 'in', '($pkList)');
      final items = List<Map<String, dynamic>>.from(remoteItems);
      await _itemDao.replaceAll(items);
    } else {
      await _itemDao.replaceAll([]);
    }
    step++;
    report();
    } catch (e, s) {
      await _logDao.insert(
        entidade: 'SYNC',
        tipo: 'ERRO_IMPORT',
        tela: 'SyncService',
        mensagem: e.toString(),
        dados: {'stack': s.toString()},
      );
      rethrow;
    }
  }

  /// Performs a push followed by a pull.
  Future<void> sync() async {
    try {
      await push();
      await pull();
    } catch (e, s) {
      await _logDao.insert(
        entidade: 'SYNC',
        tipo: 'ERRO_SYNC',
        tela: 'SyncService',
        mensagem: e.toString(),
        dados: {'stack': s.toString()},
      );
      rethrow;
    }
  }
}
