class PlatformShare {
  const PlatformShare({required this.id, required this.name, required this.cents, required this.count});

  factory PlatformShare.fromJson(Map<String, dynamic> j) => PlatformShare(
        id: j['id'] as int,
        name: j['nosaukums'] as String,
        cents: j['summa_centos'] as int,
        count: j['darijumu_skaits'] as int,
      );

  final int id;
  final String name;
  final int cents;
  final int count;
}

class TaxPreview {
  const TaxPreview({required this.period, required this.cents, required this.deadline});

  factory TaxPreview.fromJson(Map<String, dynamic> j) => TaxPreview(
        period: j['periods'] as String,
        cents: j['summa_centos'] as int,
        deadline: DateTime.parse(j['deklaresanas_termins'] as String),
      );

  final String period;
  final int cents;
  final DateTime deadline;
}

class Portfolio {
  const Portfolio({required this.totalCents, required this.quarterIncomeCents, required this.platforms, this.tax});

  factory Portfolio.fromJson(Map<String, dynamic> j) => Portfolio(
        totalCents: j['kopsumma_centos'] as int,
        quarterIncomeCents: j['ienakumi_ceturksni_centos'] as int,
        platforms: (j['platformas'] as List<dynamic>)
            .map((p) => PlatformShare.fromJson(p as Map<String, dynamic>))
            .toList(),
        tax: j['nodoklis'] == null ? null : TaxPreview.fromJson(j['nodoklis'] as Map<String, dynamic>),
      );

  final int totalCents;
  final int quarterIncomeCents;
  final List<PlatformShare> platforms;
  final TaxPreview? tax;

  bool get isEmpty => platforms.isEmpty;
}

class Tx {
  const Tx({
    required this.id,
    required this.date,
    required this.platform,
    required this.type,
    required this.cents,
    required this.currency,
    required this.status,
    required this.externalId,
  });

  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'] as String,
        date: DateTime.parse(j['datums'] as String),
        platform: j['platforma'] as String,
        type: j['veids'] as String,
        cents: j['summa_centos'] as int,
        currency: j['valuta'] as String,
        status: j['statuss'] as String,
        externalId: j['arejais_id'] as String,
      );

  final String id;
  final DateTime date;
  final String platform;
  final String type;
  final int cents;
  final String currency;
  final String status;
  final String externalId;

  static const typeLabels = {
    'procenti': 'Procentu ienākums',
    'kapitala_pieaugums': 'Kapitāla pieaugums',
    'ieguldijums': 'Ieguldījums',
    'atmaksa': 'Pamatsummas atmaksa',
    'maksa': 'Maksa',
  };

  String get typeLabel => typeLabels[type] ?? type;
  bool get needsReview => status == 'japarbauda';
}

class TaxSummary {
  const TaxSummary({
    required this.period,
    required this.interestCents,
    required this.capitalGainCents,
    required this.taxableCents,
    required this.rateBp,
    required this.taxCents,
    required this.declareBy,
    required this.payBy,
    required this.excluded,
  });

  factory TaxSummary.fromJson(Map<String, dynamic> j) => TaxSummary(
        period: j['periods'] as String,
        interestCents: j['procenti_centos'] as int,
        capitalGainCents: j['kapitala_pieaugums_centos'] as int,
        taxableCents: j['apliekams_centos'] as int,
        rateBp: j['likme_bazes_punktos'] as int,
        taxCents: j['nodoklis_centos'] as int,
        declareBy: DateTime.parse(j['deklaresanas_termins'] as String),
        payBy: DateTime.parse(j['samaksas_termins'] as String),
        excluded: j['neieklauti'] as int,
      );

  final String period;
  final int interestCents;
  final int capitalGainCents;
  final int taxableCents;
  final int rateBp;
  final int taxCents;
  final DateTime declareBy;
  final DateTime payBy;
  final int excluded;

  bool get isEmpty => taxableCents == 0 && interestCents == 0 && capitalGainCents == 0;
}

class PlatformInfo {
  const PlatformInfo({required this.id, required this.name, required this.active});

  factory PlatformInfo.fromJson(Map<String, dynamic> j) =>
      PlatformInfo(id: j['id'] as int, name: j['nosaukums'] as String, active: j['aktiva'] as bool);

  final int id;
  final String name;
  final bool active;
}

/// API-05 atbilde: ko imports saglabās, pirms lietotājs to apstiprina.
class ImportPreview {
  const ImportPreview({
    required this.id,
    required this.platform,
    required this.rows,
    required this.newCount,
    required this.duplicates,
    required this.skipped,
    required this.incomeCents,
    this.from,
    this.to,
    this.fileName = '',
  });

  factory ImportPreview.fromJson(Map<String, dynamic> j, {String fileName = ''}) {
    final period = j['periods'] as Map<String, dynamic>?;
    return ImportPreview(
      id: j['importa_id'] as String,
      platform: (j['platforma'] as String?) ?? '',
      rows: (j['rindas'] as int?) ?? 0,
      newCount: j['jauni'] as int,
      duplicates: j['dublikati'] as int,
      skipped: (j['izlaisti'] as int?) ?? 0,
      incomeCents: (j['ienakumi_centos'] as int?) ?? 0,
      from: period == null ? null : DateTime.parse(period['no'] as String),
      to: period == null ? null : DateTime.parse(period['lidz'] as String),
      fileName: fileName,
    );
  }

  final String id;
  final String platform;
  final int rows;
  final int newCount;
  final int duplicates;
  final int skipped;
  final int incomeCents;
  final DateTime? from;
  final DateTime? to;
  final String fileName;

  bool get nothingNew => newCount == 0;
}

class ImportResult {
  const ImportResult({required this.saved, required this.duplicates});

  factory ImportResult.fromJson(Map<String, dynamic> j) =>
      ImportResult(saved: j['saglabati'] as int, duplicates: j['dublikati'] as int);

  final int saved;
  final int duplicates;
}

class ImportRecord {
  const ImportRecord({
    required this.id,
    required this.platform,
    required this.fileName,
    required this.status,
    required this.newCount,
    required this.duplicates,
    this.errorRow,
    this.created,
  });

  factory ImportRecord.fromJson(Map<String, dynamic> j) => ImportRecord(
        id: j['importa_id'] as String,
        platform: j['platforma'] as String,
        fileName: j['faila_nosaukums'] as String,
        status: j['statuss'] as String,
        newCount: j['jauni'] as int,
        duplicates: j['dublikati'] as int,
        errorRow: j['kludas_rinda'] as int?,
        created: j['izveidots'] == null ? null : DateTime.parse(j['izveidots'] as String).toLocal(),
      );

  final String id;
  final String platform;
  final String fileName;
  final String status;
  final int newCount;
  final int duplicates;
  final int? errorRow;
  final DateTime? created;

  static const statusLabels = {
    'apstiprinats': 'Saglabāts',
    'parbaude': 'Nav apstiprināts',
    'atcelts': 'Atcelts',
    'kluda': 'Kļūda failā',
  };

  String get statusLabel => statusLabels[status] ?? status;
}

/// API-12: viens nodokļa termiņš.
class Deadline {
  const Deadline({
    required this.periods,
    required this.kind,
    required this.date,
    required this.taxCents,
    required this.taxableCents,
    required this.provisional,
    required this.past,
  });

  factory Deadline.fromJson(Map<String, dynamic> j) => Deadline(
        periods: (j['periods'] as String).split(', '),
        kind: j['veids'] as String,
        date: DateTime.parse(j['datums'] as String),
        taxCents: j['nodoklis_centos'] as int,
        taxableCents: j['apliekams_centos'] as int,
        provisional: j['provizorisks'] as bool,
        past: j['pagajis'] as bool,
      );

  final List<String> periods;
  final String kind; // deklaresana | samaksa | deklaresana_un_samaksa
  final DateTime date;
  final int taxCents;
  final int taxableCents;
  final bool provisional;
  final bool past;

  String get action => switch (kind) {
        'deklaresana' => 'Iesniegt deklarāciju',
        'samaksa' => 'Samaksāt nodokli',
        _ => 'Deklarēt un samaksāt nodokli',
      };

  /// Stabils identifikators atgādinājumiem un kalendāra notikumiem.
  String get key => '${date.toIso8601String().substring(0, 10)}-$kind';
}

class Deadlines {
  const Deadlines({required this.items, this.next});

  factory Deadlines.fromJson(Map<String, dynamic> j) => Deadlines(
        items: (j['items'] as List<dynamic>).map((d) => Deadline.fromJson(d as Map<String, dynamic>)).toList(),
        next: j['nakamais'] == null ? null : Deadline.fromJson(j['nakamais'] as Map<String, dynamic>),
      );

  final List<Deadline> items;
  final Deadline? next;

  List<Deadline> get upcoming => items.where((d) => !d.past).toList();
  bool get isEmpty => items.isEmpty;
}
