namespace SPB.Utilities;

using SPB.Extensibility;
using SPB.Storage;

codeunit 71033575 "SPBLIC License Utilities"
{
    internal procedure GetTestProductAppId(): Guid
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Id());
    end;

    internal procedure GetTestProductKey(SPBExtensionLicense: Record "SPBLIC Extension License"): Text
    var
        LicensePlatform: Interface "SPBLIC ILicenseCommunicator2";
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        exit(LicensePlatform.GetTestProductKey());
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "SPBLIC Extension License"; var IsHandled: Boolean)
    begin
    end;
}
