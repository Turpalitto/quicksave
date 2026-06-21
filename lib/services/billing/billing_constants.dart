/// Google Play product identifiers (configure matching IDs in Play Console).
class BillingConstants {
  BillingConstants._();

  static const String proPersonalMonthly = 'quicksave_pro_monthly';
  static const String proPersonalYearly = 'quicksave_pro_yearly';

  static const Set<String> proProductIds = {
    proPersonalMonthly,
    proPersonalYearly,
  };

  static const String billingPrefsKey = 'quicksave.billing.v1';
}

enum BillingSource { none, play, license }
