/// Product entitlements — Play Billing + license keys.
enum EntitlementTier { free, proPersonal, proSelfHosted, teamFuture }

enum EntitlementBillingSource { none, googlePlay, licenseKey }

extension EntitlementTierFeatures on EntitlementTier {
  bool get canUseScheduler =>
      this == EntitlementTier.proPersonal ||
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;

  bool get canExportZip =>
      this == EntitlementTier.proPersonal ||
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;

  bool get canUseSmartFolders =>
      this == EntitlementTier.proPersonal ||
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;

  bool get canUseFilenameTemplates =>
      this == EntitlementTier.proPersonal ||
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;

  bool get canBulkActions =>
      this == EntitlementTier.proPersonal ||
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;

  bool get canSelfHostAdvanced =>
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;

  bool get canUseBackupDestinations =>
      this == EntitlementTier.proPersonal ||
      this == EntitlementTier.proSelfHosted ||
      this == EntitlementTier.teamFuture;
}

class EntitlementState {
  final EntitlementTier tier;
  final bool isDemoMode;
  final String? licenseKeyHint;
  final EntitlementBillingSource billingSource;

  const EntitlementState({
    this.tier = EntitlementTier.free,
    this.isDemoMode = false,
    this.licenseKeyHint,
    this.billingSource = EntitlementBillingSource.none,
  });

  bool get isPro => tier != EntitlementTier.free;
}
