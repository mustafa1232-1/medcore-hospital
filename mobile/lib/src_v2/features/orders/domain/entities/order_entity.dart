class OrderEntity {
  final String id;

  /// UUIDs
  final String admissionId;
  final String patientId;

  /// MEDICATION | LAB | PROCEDURE
  final String kind;

  /// CREATED | IN_PROGRESS | PARTIALLY_COMPLETED | COMPLETED | OUT_OF_STOCK | CANCELLED
  final String status;

  /// JSON payload from backend (med/lab/procedure + pharmacy info)
  final Map<String, dynamic> payload;

  final String? notes;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;

  const OrderEntity({
    required this.id,
    required this.admissionId,
    required this.patientId,
    required this.kind,
    required this.status,
    required this.payload,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.notes,
  });

  // ---------- Convenience for UI ----------
  bool get isMedication => kind.toUpperCase() == 'MEDICATION';
  bool get isLab => kind.toUpperCase() == 'LAB';
  bool get isProcedure => kind.toUpperCase() == 'PROCEDURE';

  /// A display title derived from payload
  String get title {
    final p = payload;
    if (isMedication) return (p['medicationName'] ?? 'Medication').toString();
    if (isLab) return (p['testName'] ?? 'Lab Test').toString();
    if (isProcedure) return (p['procedureName'] ?? 'Procedure').toString();
    return kind;
  }

  /// Extra details for list tiles (optional)
  String? get subtitle {
    final p = payload;
    if (isMedication) {
      final dose = p['dose']?.toString();
      final route = p['route']?.toString();
      final freq = p['frequency']?.toString();
      final dur = p['duration']?.toString();
      final parts = <String>[
        if (dose != null && dose.isNotEmpty) dose,
        if (route != null && route.isNotEmpty) route,
        if (freq != null && freq.isNotEmpty) freq,
        if (dur != null && dur.isNotEmpty) 'for $dur',
      ];
      return parts.isEmpty ? null : parts.join(' • ');
    }

    if (isLab) {
      final pr = p['priority']?.toString(); // ROUTINE|STAT
      final sp = p['specimen']?.toString();
      final parts = <String>[
        if (pr != null && pr.isNotEmpty) pr,
        if (sp != null && sp.isNotEmpty) sp,
      ];
      return parts.isEmpty ? null : parts.join(' • ');
    }

    if (isProcedure) {
      final u = p['urgency']?.toString(); // NORMAL|URGENT
      return (u == null || u.isEmpty) ? null : u;
    }

    return null;
  }
}
