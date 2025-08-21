namespace SPB.EngineLogic;

using SPB.Extensibility;
using SPB.Storage;
using SPB.Telemetry;

codeunit 71033588 "SPBLIC Deactivate Meth"
{
    Access = Public;
    Permissions =
        tabledata "SPBLIC Extension License" = RM;

    internal procedure Deactivate(var SPBExtensionLicense: Record "SPBLIC Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    begin
        DoDeactivate(SPBExtensionLicense, ByPlatform);
    end;

    local procedure DoDeactivate(var SPBExtensionLicense: Record "SPBLIC Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
        SPBLICIsoStoreManager: Codeunit "SPBLIC IsoStore Manager";
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        LicensePlatformV2: Interface "SPBLIC ILicenseCommunicator2";
        DeactivationProblemErr: Label 'There was an issue in contacting the licensing server to deactivate this license.  Contact %1 for assistance.', Comment = '%1 is the App Publisher name';
        AppInfo: ModuleInfo;
        ResponseBody: Text;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        if ByPlatform then begin
            LicensePlatformV2 := SPBExtensionLicense."License Platform";
            if not LicensePlatformV2.CallAPIForDeactivation(SPBExtensionLicense, ResponseBody) then begin
                if GuiAllowed() then
                    Error(DeactivationProblemErr, AppInfo.Publisher());
            end else
                DeactivationSuccess := true;
            SPBLICTelemetry.LicensePlatformDeactivation(SPBExtensionLicense);
            SPBLICEvents.OnAfterLicenseDeactivatedByPlatform(SPBExtensionLicense, ResponseBody);
        end else begin
            SPBLICTelemetry.LicenseDeactivation(SPBExtensionLicense);
            SPBLICEvents.OnAfterLicenseDeactivated(SPBExtensionLicense);
        end;

        SPBExtensionLicense.Validate(Activated, false);
        ClearSubscriptionMetadata(SPBExtensionLicense);
        SPBExtensionLicense.Modify();
        SPBLICIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);

    end;

    local procedure ClearSubscriptionMetadata(var SPBExtensionLicense: Record "SPBLIC Extension License")
    begin
        SPBExtensionLicense."Subscription Item Id" := 0;
        SPBExtensionLicense."Order Id" := 0;
        SPBExtensionLicense."Order Item Id" := 0;
        SPBExtensionLicense."Product Id" := 0;
        SPBExtensionLicense."Usage Aggregation Type" := '';
        SPBExtensionLicense."Billing Frequency" := '';
        SPBExtensionLicense."Last Metadata Refresh" := 0DT;
        SPBExtensionLicense."Licensing ID" := '';
    end;
}