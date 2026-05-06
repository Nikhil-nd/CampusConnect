class AppConstants {
  AppConstants._();

  static const String appName = 'CampusConnect';
  static const bool enableFirebaseStorageUploads = false;
  static const List<String> allowedCollegeEmailDomains = <String>[
    'ncuindia.edu',
    'college.edu',
  ];

  static const List<String> marketplaceCategories = <String>[
    'Notes',
    'Books',
    'Gadgets',
    'Furniture',
    'Cycles',
    'Other',
  ];

  static const List<String> feedTypes = <String>[
    'event',
    'marketplace',
    'lost_found',
    'job',
  ];
}
