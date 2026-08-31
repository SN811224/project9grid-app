class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.occupation,
    this.company,
    this.annualPremium = 0,
  });

  final String id;
  final String name;
  final String? phone;
  final String? occupation;
  final String? company;
  final double annualPremium;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      phone: map['phone'] as String?,
      occupation: map['occupation'] as String?,
      company: map['company'] as String?,
      annualPremium:
          double.tryParse((map['annual_premium'] ?? 0).toString()) ?? 0,
    );
  }
}
