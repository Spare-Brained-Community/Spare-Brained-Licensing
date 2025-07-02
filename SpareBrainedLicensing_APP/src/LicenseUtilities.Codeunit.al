codeunit 71033575 "SPBLIC License Utilities"
{
    internal procedure GetTestProductAppId(): Guid
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Id);
    end;

    internal procedure GetTestProductKey(SPBExtensionLicense: Record "SPBLIC Extension License"): Text
    var
        LicenseProduct: Interface "SPBLIC IProduct";
    begin
        LicenseProduct := SPBExtensionLicense."License Platform";
        exit(LicenseProduct.GetTestProductKey());
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "SPBLIC Extension License"; var IsHandled: Boolean)
    begin
    end;
}
