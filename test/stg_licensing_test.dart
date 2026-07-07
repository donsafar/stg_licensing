import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stg_licensing/stg_licensing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveLicenseKeyActivation', () {
    test('accepts QA premium master key', () {
      final activation = resolveLicenseKeyActivation('Safar1949!@');
      expect(activation?.tier, StgPlanTier.premium);
    });

    test('rejects invalid keys', () {
      expect(resolveLicenseKeyActivation('wrong'), isNull);
      expect(resolveLicenseKeyActivation(''), isNull);
    });
  });

  group('licensing lifecycle', () {
    test('license activation and reset persist prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const appId = StgPortfolioAppId.health;
      final keys = stgLicensingPrefsKeysFor(appId);

      expect(await activateStgLicenseKey(prefs, appId, 'Safar1949!@'), isTrue);
      expect(prefs.getInt(keys.licenseTierIndex), StgPlanTier.premium.index);
      expect(prefs.getInt(keys.licenseExpiresAtMs), isNotNull);

      await resetStgLicensingTrial(prefs, appId);
      expect(prefs.getInt(keys.licenseTierIndex), isNull);
      expect(prefs.getInt(keys.trialStartedAtMs), isNotNull);
      expect(prefs.getInt(keys.selectedPlanIndex), StgPlanTier.trial.index);
    });

    test('read state tracks trial and license when trial build', () async {
      if (!stgTrialBuild) return;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const appId = StgPortfolioAppId.health;

      await ensureStgLicensingTrialStarted(prefs, appId);
      final trial = readStgLicensingState(prefs, appId);
      expect(trial.phase, StgLicensingPhase.trialActive);

      expect(await activateStgLicenseKey(prefs, appId, 'Safar1949!@'), isTrue);
      final licensed = readStgLicensingState(prefs, appId);
      expect(licensed.phase, StgLicensingPhase.licensedActive);
      expect(licensed.activeTier, StgPlanTier.premium);
    });
  });

  group('StgPortfolioPricing', () {
    test('includes health pricing', () {
      final pricing = StgPortfolioPricing.forApp(StgPortfolioAppId.health);
      expect(pricing.standardPriceLabel, r'$59.99/year');
      expect(pricing.premiumPriceLabel, r'$99.99/year');
    });
  });

  group('stgLicensingBannerLabel', () {
    test('hides minutes when more than one day remains', () {
      final state = StgLicensingState(
        enforced: true,
        phase: StgLicensingPhase.licensedActive,
        activeTier: StgPlanTier.premium,
        expiresAt: DateTime.now().add(const Duration(hours: 51)),
      );
      final content = buildStgLicensingBannerContent(state);
      expect(content.showMinutes, isFalse);
      expect(content.days, greaterThanOrEqualTo(2));
    });

    test('shows minutes when one day or less remains', () {
      final state = StgLicensingState(
        enforced: true,
        phase: StgLicensingPhase.trialActive,
        activeTier: StgPlanTier.trial,
        expiresAt: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
      );
      final content = buildStgLicensingBannerContent(state);
      expect(content.showMinutes, isTrue);
      expect(content.minutes, isNotNull);
    });

    test('shows license expired at zero', () {
      final state = StgLicensingState(
        enforced: true,
        phase: StgLicensingPhase.locked,
        activeTier: StgPlanTier.premium,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(stgLicensingBannerLabel(state), 'Premium License Expired');
    });
  });
}
