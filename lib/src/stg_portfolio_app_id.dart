/// Portfolio STG apps with shared licensing.
enum StgPortfolioAppId {
  health,
  checklist,
  taskapp,
  dms,
  project,
  propertyInventory,
  life,
  fileCatalog,
}

extension StgPortfolioAppIdX on StgPortfolioAppId {
  String get prefsPrefix => switch (this) {
        StgPortfolioAppId.health => 'stg_health',
        StgPortfolioAppId.checklist => 'stg_checklist',
        StgPortfolioAppId.taskapp => 'stg_taskapp',
        StgPortfolioAppId.dms => 'stg_dms',
        StgPortfolioAppId.project => 'stg_project',
        StgPortfolioAppId.propertyInventory => 'stg_property_inventory',
        StgPortfolioAppId.life => 'stg_life',
        StgPortfolioAppId.fileCatalog => 'stg_file_catalog',
      };

  String get displayName => switch (this) {
        StgPortfolioAppId.health => 'STG Health',
        StgPortfolioAppId.checklist => 'STG Checklist',
        StgPortfolioAppId.taskapp => 'STG Task App',
        StgPortfolioAppId.dms => 'STG DMS',
        StgPortfolioAppId.project => 'STG Projects',
        StgPortfolioAppId.propertyInventory => 'STG Property Inventory',
        StgPortfolioAppId.life => 'STG Life',
        StgPortfolioAppId.fileCatalog => 'STG File Catalog',
      };
}

/// Commercial tier (trial is time-boxed evaluation, not a paid SKU).
enum StgPlanTier {
  trial,
  standard,
  premium,
}

extension StgPlanTierX on StgPlanTier {
  String get label => switch (this) {
        StgPlanTier.trial => 'Trial',
        StgPlanTier.standard => 'Standard',
        StgPlanTier.premium => 'Premium',
      };
}
