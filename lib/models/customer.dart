class Customer {
  int? id;
  String name;
  String? phone;
  String? email;
  String? address;
  String? idNumber;
  double creditLimit;
  double currentBalance;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.idNumber,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'id_number': idNumber,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      idNumber: map['id_number'],
      creditLimit: map['credit_limit'] ?? 0,
      currentBalance: map['current_balance'] ?? 0,
      notes: map['notes'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? idNumber,
    double? creditLimit,
    double? currentBalance,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
