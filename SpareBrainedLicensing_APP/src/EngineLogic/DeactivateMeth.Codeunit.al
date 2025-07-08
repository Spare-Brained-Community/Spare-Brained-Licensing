codeunit 71033588 "SPBLIC Deactivate Meth"
{
    internal procedure Deactivate(var SPBExtensionLicense: Record "SPBLIC Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    begin
        DoDeactivate(SPBExtensionLicense, ByPlatform);
    end;

    local procedure DoDeactivate(var SPBExtensionLicense: Record "SPBLIC Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
        SPBLICIsoStoreManager: Codeunit "SPBLIC IsoStore Manager";
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        LicenseActivation: Interface "SPBLIC IActivation";
        DeactivationProblemErr: Label 'There was an issue in contacting the licensing server to deactivate this license.  Contact %1 for assistance.', Comment = '%1 is the App Publisher name';
        AppInfo: ModuleInfo;
        ResponseBody: Text;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        SPBExtensionLicense.Validate("License State", SPBExtensionLicense."License State"::Deactivated);
        SPBExtensionLicense.Modify();
        SPBLICIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        Commit();  // if calling the API fails, the local should still be marked as deactivated


        if ByPlatform then begin
            LicenseActivation := SPBExtensionLicense."License Platform";
            if not LicenseActivation.CallAPIForDeactivation(SPBExtensionLicense, ResponseBody) then begin
                if ByPlatform then begin
                    LicensePlatformV2 := SPBExtensionLicense."License Platform";
                    if not LicensePlatformV2.CallAPIForDeactivation(SPBExtensionLicense, ResponseBody) then begin
                        if GuiAllowed() then
                            Error(DeactivationProblemErr, AppInfo.Publisher);
                    end else
                        DeactivationSuccess := true;
                    SPBLICTelemetry.LicensePlatformDeactivation(SPBExtensionLicense);
                    SPBLICEvents.OnAfterLicenseDeactivatedByPlatform(SPBExtensionLicense, ResponseBody);
                end else begin
                    SPBLICTelemetry.LicenseDeactivation(SPBExtensionLicense);
                    SPBLICEvents.OnAfterLicenseDeactivated(SPBExtensionLicense);
                end;
            end;
}