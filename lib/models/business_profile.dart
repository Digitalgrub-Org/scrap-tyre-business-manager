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

  factory BusinessProfile.fromFirestore(Map<String, dynamic> data) =>
      BusinessProfile(
        businessName: (data['businessName'] as String?) ?? '',
        ownerName: (data['ownerName'] as String?) ?? '',
        phone: (data['phone'] as String?) ?? '',
        address: (data['address'] as String?) ?? '',
        taxId: (data['taxId'] as String?) ?? '',
      );

  Map<String, Object?> toFirestore() => {
    'businessName': businessName,
    'ownerName': ownerName,
    'phone': phone,
    'address': address,
    'taxId': taxId,
  };
}
