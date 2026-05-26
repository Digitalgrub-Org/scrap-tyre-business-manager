class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.taxId,
  });

  final String businessName;
  final String ownerName;
  final String phone;
  final String address;
  final String taxId;

  bool get isConfigured => businessName.trim().isNotEmpty;

  factory BusinessProfile.empty() => const BusinessProfile(
    businessName: '',
    ownerName: '',
    phone: '',
    address: '',
    taxId: '',
  );

  factory BusinessProfile.fromMap(Map<String, Object?> map) => BusinessProfile(
    businessName: (map['business_name'] as String?) ?? '',
    ownerName: (map['owner_name'] as String?) ?? '',
    phone: (map['phone'] as String?) ?? '',
    address: (map['address'] as String?) ?? '',
    taxId: (map['tax_id'] as String?) ?? '',
  );

  Map<String, Object?> toMap() => {
    'id': 1,
    'business_name': businessName,
    'owner_name': ownerName,
    'phone': phone,
    'address': address,
    'tax_id': taxId,
  };
}
