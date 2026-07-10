# Annual Subscriptions Deployment Guide (Flutter)

This document details the configuration, architecture, and testing procedures required to deploy two tiers of annual auto-renewable subscriptions (**Standard** and **Premium**) with an app-defined custom trial period using **RevenueCat (`purchases_flutter`)**.

---

## 1. Prerequisites Checklist

Before writing any Flutter code or initializing store products, ensure the following developer accounts and agreements are fully configured:

*   **Apple Developer Program:** Active paid membership.
*   **Google Play Developer Account:** Active registration.
*   **Paid Applications Agreements:** 
    *   **Apple:** In *App Store Connect -> Agreements, Tax, and Banking*, you must accept the **Paid Apps Agreement** and configure your banking and tax forms.
    *   **Google:** In *Google Play Console -> Settings -> Payment profile*, you must link a merchant bank account.
    *   *Note: Storefronts will refuse to fetch or serve products to your app if financial agreements are incomplete.*

---

## 2. Platform Portal Configurations

You will map out product identifier structures for both subscription tiers. It is best practice to use a unified, reverse-domain naming convention across both stores.

*   **Standard Annual Plan:** `com.company.appname.standard.yearly`
*   **Premium Annual Plan:** `com.company.appname.premium.yearly`

### A. Apple App Store Connect Setup
1. Log in to **App Store Connect** and select your app.
2. Go to **Monetization** -> **In-App Purchases**.
3. Create a single **Subscription Group** named "Subscription_Tiers". *Placing both inside the same group allows users to upgrade/downgrade cleanly and prevents them from subscribing to both simultaneously.*
4. Inside that group, click the **+** icon under **Subscriptions** to create your two tiers:
    *   **Tier 1 (Standard):** Product ID: `com.company.appname.standard.yearly` | Duration: 1 Year
    *   **Tier 2 (Premium):** Product ID: `com.company.appname.premium.yearly` | Duration: 1 Year
5. Set the localized display names, descriptions, and pricing matrices for each.
6. **Crucial:** Upload a placeholder review screenshot for both products. Apple will reject the configurations if review screenshots are missing.

### B. Google Play Console Setup
1. Log in to the **Google Play Console** and select your app.
2. Go to **Monetization** -> **Products** -> **Subscriptions**.
3. Click **Create subscription** to create both items:
    *   **Standard Subscription:** Product ID: `com.company.appname.standard.yearly`
    *   **Premium Subscription:** Product ID: `com.company.appname.premium.yearly`
4. Inside each subscription, create a **Base Plan** configured for a 1-year billing period (`standard-yearly-base` and `premium-yearly-base`).
5. Activate both Base Plans.

### C. RevenueCat Dashboard Mapping
RevenueCat decouples physical store products from code logic using entitlements. To support a custom app-side local trial, the entitlements are granted conditionally based on your internal database/preferences logic.

1. Create a RevenueCat account, set up a project, and link your platform API keys.
2. Create **Two Entitlements**:
    *   `standard_access` (Represents access unlocked by the standard tier)
    *   `premium_access` (Represents access unlocked by the premium tier)
3. Create **Two Products**: Map your App Store and Google Play IDs (`com.company.appname.standard.yearly` and `com.company.appname.premium.yearly`) to their corresponding RevenueCat counterparts.
4. Attach each product to its respective entitlement (`standard_access` or `premium_access`).
5. Create an **Offering**: Name it `default_offering`. Inside it, create two packages:
    *   `$rc_yearly` (assigned to your Standard product)
    *   `premium_yearly` (assigned to your Premium product)

---

## 3. Flutter Architecture & Integration

### A. Dependency Configuration
Add the latest RevenueCat package to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  purchases_flutter: ^8.0.0
```

### B. Implementation Blueprint (Custom Trial & Tier Resolution)
Since your initial installation handles an offline/app-defined local trial period, your app code checks the local install timestamp first. If the trial is active, the app unlocks the relevant baseline features. If expired, it falls back strictly to the real-time store entitlements via RevenueCat.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppUserStatus { trial, standard, premium, expired }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureBilling();
  runApp(const MyApp());
}

async Future<void> _configureBilling() async {
  await Purchases.setLogLevel(LogLevel.debug);
  PurchasesConfiguration configuration;
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration("goog_api_key_here");
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration("appl_api_key_here");
  } else {
    return;
  }
  await Purchases.configure(configuration);
}

class SubscriptionService {
  // Configured app-defined trial length
  static const int trialDurationDays = 7;

  // Initialize or track the custom trial timestamp upon first launch
  static Future<void> trackInitialInstallation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('install_date') == null) {
      prefs.setString('install_date', DateTime.now().toIso8601String());
    }
  }

  // Determine the current access state across local trials and remote entitlements
  static Future<AppUserStatus> evaluateUserStatus() async {
    try {
      // 1. Check verified live store entitlements first
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all['premium_access']?.isActive ?? false) {
        return AppUserStatus.premium;
      }
      if (customerInfo.entitlements.all['standard_access']?.isActive ?? false) {
        return AppUserStatus.standard;
      }
      
      // 2. Evaluate app-side local trial fallback
      final prefs = await SharedPreferences.getInstance();
      final installString = prefs.getString('install_date');
      if (installString != null) {
        final installDate = DateTime.parse(installString);
        final trialExpiryDate = installDate.add(const Duration(days: trialDurationDays));
        
        if (DateTime.now().isBefore(trialExpiryDate)) {
          return AppUserStatus.trial;
        }
      }
    } catch (e) {
      // Fallback or logger parsing
    }
    return AppUserStatus.expired;
  }

  // Fetch the configured offering to display packages on your Paywall UI
  static Future<Offering?> fetchCurrentOffering() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      return null;
    }
  }

  // Execute a secure checkout flow for a given tier package
  static Future<AppUserStatus> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      if (customerInfo.entitlements.all['premium_access']?.isActive ?? false) {
        return AppUserStatus.premium;
      }
      if (customerInfo.entitlements.all['standard_access']?.isActive ?? false) {
        return AppUserStatus.standard;
      }
    } catch (e) {
      // User cancelled checkout or payment failed
    }
    return await evaluateUserStatus();
  }

  // Restore historical app store transaction receipts
  static Future<AppUserStatus> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all['premium_access']?.isActive ?? false) {
        return AppUserStatus.premium;
      }
      if (customerInfo.entitlements.all['standard_access']?.isActive ?? false) {
        return AppUserStatus.standard;
      }
    } catch (e) {
      // Error executing restore workflow
    }
    return await evaluateUserStatus();
  }
}
```

---

## 4. Rigorous Testing Requirements

> ⚠️ **Absolute Constraint:** Real in-app purchases and multi-tier subscription switches *cannot* be verified using standard simulated operating system environments. You must deploy code to physical test units.

### Testing Behavior Matrix

| Platform | Verification Track | Sandbox Environment Specifics |
| :--- | :--- | :--- |
| **iOS** | TestFlight Build OR Debug on Device | Sandbox accounts accelerate annual durations down to 1 hour to verify expiration, cross-grade tier transitions, and trial-to-billing switches natively. |
| **Android** | Internal Testing Track | Developer emails must be listed in **License Testing**. This provides zero-cost validation of standard vs premium purchases, upgrades, and cancellations without billing real accounts. |

---

## 5. Pre-Submission Rejection Checklist

To guarantee a clean review cycle from Apple and Google app review teams, verify the following product guidelines are fulfilled:

*   **Explicit Paywall Rules:** Your Paywall UI must clearly state the distinct costs of both paths (e.g., "$19.99/year for Standard" vs "$34.99/year for Premium"), duration rules, renewal dynamics, and a direct disclaimer about your initial free trial duration.
*   **The Restore Purchases Mechanism:** You **must** provide a distinct, functioning "Restore Purchases" button on your subscription wall. Apple will reject your app build immediately if this button is omitted or fails to link to functional code logic.
*   **Terms of Service & Privacy Policy links:** Both App Store Connect and Google Play Console require visible links to your Privacy Policy and Terms of Use (EULA) explicitly on the registration and subscription layout pages.