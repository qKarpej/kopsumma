import 'dart:async';

import 'package:kopsumma/api/api_client.dart';
import 'package:kopsumma/api/kopsumma_api.dart';
import 'package:kopsumma/api/models.dart';

enum Mode { ready, empty, error }

class FakeApi implements KopsummaApi {
  FakeApi({this.mode = Mode.ready, this.hasSession = false});

  Mode mode;
  Completer<void>? gate;
  int portfolioCalls = 0;
  bool hasSession;
  bool loggedOut = false;
  String? registered;
  final uploads = <String>[];
  final confirmed = <String>[];
  final cancelled = <String>[];

  @override
  String serverUrl = 'http://test';

  static final deadlineList = Deadlines(items: [
    Deadline(periods: const ['2026-Q3'], kind: 'deklaresana', date: DateTime(2026, 10, 15), taxCents: 31240,
        taxableCents: 122510, provisional: false, past: true),
    Deadline(periods: const ['2026-Q3'], kind: 'samaksa', date: DateTime(2026, 10, 23), taxCents: 31240,
        taxableCents: 122510, provisional: false, past: true),
    Deadline(periods: const ['2026-Q4'], kind: 'deklaresana_un_samaksa', date: DateTime(2099, 1, 15),
        taxCents: 2404, taxableCents: 9428, provisional: true, past: false),
  ]);

  static final txs = [
    Tx(id: 't1', date: DateTime(2026, 9, 30), platform: 'Mintos', type: 'procenti', cents: 412,
        currency: 'EUR', status: 'apstiprinats', externalId: 'MT-88412301'),
    Tx(id: 't3', date: DateTime(2026, 9, 28), platform: 'Mintos', type: 'ieguldijums', cents: -25000,
        currency: 'EUR', status: 'apstiprinats', externalId: 'MT-88412302'),
    Tx(id: 't6', date: DateTime(2026, 9, 24), platform: 'Twino', type: 'procenti', cents: 305,
        currency: 'USD', status: 'japarbauda', externalId: 'TW-551205'),
  ];

  Future<void> _maybe() async {
    if (gate != null) await gate!.future;
    if (mode == Mode.error) {
      throw const ApiException(503, 'SERVICE_UNAVAILABLE', 'Nav savienojuma ar serveri. Jūsu dati ir saglabāti.');
    }
  }

  @override
  Future<void> login(String email, String password) async {
    if (password != 'Kopsumma2026') {
      throw const ApiException(401, 'INVALID_CREDENTIALS', 'E-pasts vai parole nav pareiza.');
    }
  }

  @override
  Future<void> register(String email, String password) async {
    if (email == 'anna@inbox.lv') {
      throw const ApiException(409, 'EMAIL_TAKEN', 'Šis e-pasts jau ir reģistrēts.', field: 'epasts');
    }
    registered = email;
  }

  @override
  Future<bool> restoreSession() async => hasSession;

  @override
  Future<void> logout() async => loggedOut = true;

  @override
  Future<String> currentEmail() async => 'anna@inbox.lv';

  @override
  Future<Deadlines> deadlines() async {
    await _maybe();
    return mode == Mode.empty ? const Deadlines(items: []) : Deadlines(items: deadlineList.items, next: deadlineList.items.last);
  }

  @override
  Future<List<PlatformInfo>> platforms() async => const [
        PlatformInfo(id: 1, name: 'Mintos', active: true),
        PlatformInfo(id: 2, name: 'Twino', active: true),
      ];

  @override
  Future<ImportPreview> uploadStatement({required int platformId, required String fileName, required List<int> bytes}) async {
    uploads.add(fileName);
    if (fileName.contains('bojats')) {
      throw const ApiException(422, 'IMPORT_INVALID_ROW', "47. rindā: Summa 'abc' nav skaitlis.", field: 'fails.row[47]');
    }
    return ImportPreview(
      id: 'imp-1',
      platform: platformId == 2 ? 'Twino' : 'Mintos',
      rows: 84,
      newCount: fileName.contains('atkartots') ? 0 : 83,
      duplicates: fileName.contains('atkartots') ? 83 : 0,
      skipped: 1,
      incomeCents: 9428,
      from: DateTime(2026, 10, 2),
      to: DateTime(2026, 11, 18),
      fileName: fileName,
    );
  }

  @override
  Future<ImportResult> confirmImport(String importId) async {
    confirmed.add(importId);
    return const ImportResult(saved: 83, duplicates: 0);
  }

  @override
  Future<void> cancelImport(String importId) async => cancelled.add(importId);

  @override
  Future<List<ImportRecord>> imports() async => [
        ImportRecord(id: 'a', platform: 'Mintos', fileName: 'mintos.csv', status: 'apstiprinats', newCount: 128,
            duplicates: 2, created: DateTime(2026, 11, 2)),
        ImportRecord(id: 'b', platform: 'Mintos', fileName: 'bojats.csv', status: 'kluda', newCount: 0,
            duplicates: 0, errorRow: 47, created: DateTime(2026, 11, 2)),
      ];

  @override
  Future<Portfolio> portfolio() async {
    portfolioCalls++;
    await _maybe();
    if (mode == Mode.empty) {
      return const Portfolio(totalCents: 0, quarterIncomeCents: 0, platforms: []);
    }
    return Portfolio(
      totalCents: 1938000,
      quarterIncomeCents: 31845,
      platforms: const [
        PlatformShare(id: 1, name: 'Mintos', cents: 1241860, count: 96),
        PlatformShare(id: 2, name: 'Twino', cents: 696140, count: 41),
      ],
      tax: TaxPreview(period: '2026-Q3', cents: 31240, deadline: DateTime(2026, 10, 15)),
    );
  }

  @override
  Future<List<Tx>> transactions({String? platform}) async {
    await _maybe();
    if (mode == Mode.empty) return [];
    return txs.where((t) => platform == null || t.platform == platform).toList();
  }

  @override
  Future<Tx> transaction(String id) async {
    await _maybe();
    return txs.firstWhere((t) => t.id == id);
  }

  @override
  Future<TaxSummary> tax(String period) async {
    await _maybe();
    return TaxSummary(
      period: period,
      interestCents: mode == Mode.empty ? 0 : 104130,
      capitalGainCents: mode == Mode.empty ? 0 : 18380,
      taxableCents: mode == Mode.empty ? 0 : 122510,
      rateBp: 2550,
      taxCents: mode == Mode.empty ? 0 : 31240,
      declareBy: DateTime(2026, 10, 15),
      payBy: DateTime(2026, 10, 23),
      excluded: mode == Mode.empty ? 0 : 1,
    );
  }
}
