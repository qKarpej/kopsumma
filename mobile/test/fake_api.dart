import 'dart:async';

import 'package:kopsumma/api/api_client.dart';
import 'package:kopsumma/api/kopsumma_api.dart';
import 'package:kopsumma/api/models.dart';

enum Mode { ready, empty, error }

class FakeApi implements KopsummaApi {
  FakeApi({this.mode = Mode.ready});

  Mode mode;
  Completer<void>? gate;
  int portfolioCalls = 0;

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
  void logout() {}

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
