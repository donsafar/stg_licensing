// Portfolio standard / premium pricing (sheet 01 Pricing, 2026-06-09).
// Update this single file when workbook pricing changes.

import 'package:stg_licensing/src/stg_portfolio_app_id.dart';

class StgAppPricing {
  const StgAppPricing({
    required this.appId,
    required this.trialDays,
    required this.trialPriceLabel,
    required this.standardPriceLabel,
    required this.premiumPriceLabel,
    required this.standardYearlyPrice,
    required this.premiumYearlyPrice,
  });

  final StgPortfolioAppId appId;
  final int trialDays;
  final String trialPriceLabel;
  final String standardPriceLabel;
  final String premiumPriceLabel;
  final double standardYearlyPrice;
  final double premiumYearlyPrice;

  String priceLabelFor(StgPlanTier tier) => switch (tier) {
        StgPlanTier.trial => trialPriceLabel,
        StgPlanTier.standard => standardPriceLabel,
        StgPlanTier.premium => premiumPriceLabel,
      };
}

/// Canonical yearly pricing for every portfolio app.
abstract final class StgPortfolioPricing {
  static const Map<StgPortfolioAppId, StgAppPricing> byApp = {
    StgPortfolioAppId.health: StgAppPricing(
      appId: StgPortfolioAppId.health,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'$59.99/year',
      premiumPriceLabel: r'$99.99/year',
      standardYearlyPrice: 59.99,
      premiumYearlyPrice: 99.99,
    ),
    StgPortfolioAppId.checklist: StgAppPricing(
      appId: StgPortfolioAppId.checklist,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'$99.00/year',
      premiumPriceLabel: r'$249.00/year',
      standardYearlyPrice: 99.00,
      premiumYearlyPrice: 249.00,
    ),
    StgPortfolioAppId.taskapp: StgAppPricing(
      appId: StgPortfolioAppId.taskapp,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'$49.00/year',
      premiumPriceLabel: r'$149.00/year',
      standardYearlyPrice: 49.00,
      premiumYearlyPrice: 149.00,
    ),
    StgPortfolioAppId.dms: StgAppPricing(
      appId: StgPortfolioAppId.dms,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'TBD',
      premiumPriceLabel: r'TBD',
      standardYearlyPrice: 0,
      premiumYearlyPrice: 0,
    ),
    StgPortfolioAppId.project: StgAppPricing(
      appId: StgPortfolioAppId.project,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'TBD',
      premiumPriceLabel: r'TBD',
      standardYearlyPrice: 0,
      premiumYearlyPrice: 0,
    ),
    StgPortfolioAppId.propertyInventory: StgAppPricing(
      appId: StgPortfolioAppId.propertyInventory,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'TBD',
      premiumPriceLabel: r'TBD',
      standardYearlyPrice: 0,
      premiumYearlyPrice: 0,
    ),
    StgPortfolioAppId.life: StgAppPricing(
      appId: StgPortfolioAppId.life,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'TBD',
      premiumPriceLabel: r'TBD',
      standardYearlyPrice: 0,
      premiumYearlyPrice: 0,
    ),
    StgPortfolioAppId.fileCatalog: StgAppPricing(
      appId: StgPortfolioAppId.fileCatalog,
      trialDays: 14,
      trialPriceLabel: r'$0',
      standardPriceLabel: r'TBD',
      premiumPriceLabel: r'TBD',
      standardYearlyPrice: 0,
      premiumYearlyPrice: 0,
    ),
  };

  static StgAppPricing forApp(StgPortfolioAppId appId) {
    final pricing = byApp[appId];
    if (pricing == null) {
      throw ArgumentError('No portfolio pricing for $appId');
    }
    return pricing;
  }
}
