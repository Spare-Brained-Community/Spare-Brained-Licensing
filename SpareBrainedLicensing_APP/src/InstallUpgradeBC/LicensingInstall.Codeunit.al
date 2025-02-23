codeunit 71033579 "SPBLIC Licensing Install"
{
    Subtype = Install;

    var
        GumroadTestSubscriptionIdTok: Label 'b08c8cbe-ff20-4c38-9448-21e68b509e84';
        LemonSqueezyTestSubscriptionIdTok: Label '62922d07-87e2-4959-aece-2cacf9222e9b';

    trigger OnInstallAppPerDatabase()
    var
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        PerformInstallOfTestSubscriptions();
        SPBLICTelemetry.LicensingAppInstalled();
        UpgradeTag.SetAllUpgradeTags();
    end;

    procedure PerformInstallOfTestSubscriptions()
    begin
        AddTestProduct(Enum::"SPBLIC License Platform"::Gumroad, GumroadTestSubscriptionIdTok);
        AddTestProduct(Enum::"SPBLIC License Platform"::LemonSqueezy, LemonSqueezyTestSubscriptionIdTok);
    end;

    procedure GetGumroadTestAppId() TestProductGuid: Guid
    begin
        Evaluate(TestProductGuid, GumroadTestSubscriptionIdTok);
    end;

    [Obsolete('Use GetLemonSqueezyTestAppId instead.')]
    procedure GetLemongSqueezyTestAppId() TestProductGuid: Guid
    begin
        exit(GetLemonSqueezyTestAppId());
    end;

    procedure GetLemonSqueezyTestAppId() TestProductGuid: Guid
    begin
        Evaluate(TestProductGuid, LemonSqueezyTestSubscriptionIdTok);
    end;

    internal procedure AddTestProduct(WhichLicensePlatform: Enum "SPBLIC License Platform"; TestProductId: Text)
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        TestProductGuid: Guid;
        LicensePlatform: Interface "SPBLIC ILicenseCommunicator2";
        TestLicenseNameTok: Label '%1 Test Subscription', Comment = '%1 is the Licensing Extension name.';
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        Evaluate(TestProductGuid, TestProductId);

        if not SPBExtensionLicense.Get(TestProductGuid) then begin
            SPBExtensionLicense.Init();
            Evaluate(SPBExtensionLicense."Entry Id", TestProductGuid);
            SPBExtensionLicense.Insert(true);
        end;

        SPBExtensionLicense."Extension App Id" := AppInfo.Id;
        SPBExtensionLicense."Extension Name" := StrSubstNo(TestLicenseNameTok, AppInfo.Name);
        SPBExtensionLicense."License Platform" := WhichLicensePlatform;
        LicensePlatform := SPBExtensionLicense."License Platform";
        SPBExtensionLicense."Submodule Name" := CopyStr(UpperCase(Format(WhichLicensePlatform)), 1, MaxStrLen(SPBExtensionLicense."Submodule Name"));

        SPBExtensionLicense."Product Code" := CopyStr(LicensePlatform.GetTestProductId(), 1, MaxStrLen(SPBExtensionLicense."Product Code"));
        SPBExtensionLicense."Product URL" := CopyStr(LicensePlatform.GetTestProductUrl(), 1, MaxStrLen(SPBExtensionLicense."Product URL"));
        SPBExtensionLicense."Support URL" := CopyStr(LicensePlatform.GetTestSupportUrl(), 1, MaxStrLen(SPBExtensionLicense."Support URL"));
        SPBExtensionLicense."Billing Support Email" := CopyStr(LicensePlatform.GetTestBillingEmail(), 1, MaxStrLen(SPBExtensionLicense."Billing Support Email"));
        SPBExtensionLicense.Modify();
    end;
}
