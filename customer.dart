class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.lineId,
    this.birthday,
    this.occupation,
    this.company,
    this.familyStatus,
    this.annualPremium = 0,
    this.closedDate,
    this.priority = 3,
    this.notes,
  });

  final String id;
  final String name;
  final String? phone;
  final String? lineId;
  final DateTime? birthday;
  final String? occupation;
  final String? company;
  final String? familyStatus;
  final double annualPremium;
  final DateTime? closedDate;
  final int priority;
  final String? notes;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      lineId: map['line_id'] as String?,
      birthday: DateTime.tryParse(map['birthday'] as String? ?? ''),
      occupation: map['occupation'] as String?,
      company: map['company'] as String?,
      familyStatus: map['family_status'] as String?,
      annualPremium: (map['annual_premium'] as num?)?.toDouble() ?? 0,
      closedDate: DateTime.tryParse(map['closed_date'] as String? ?? ''),
      priority: (map['priority'] as num?)?.toInt() ?? 3,
      notes: map['notes'] as String?,
    );
  }
}
