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
