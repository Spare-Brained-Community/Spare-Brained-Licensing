namespace SPB.EngineLogic;

using SPB.Extensibility;
using SPB.PlatformObjects.LemonSqueezy;
using SPB.Storage;
using SPB.Telemetry;

codeunit 71033587 "SPBLIC Activate Meth"
{
    Access = Internal;
    Permissions =
        tabledata "SPBLIC Extension License" = RM;

    internal procedure Activate(var SPBExtensionLicense: Record "SPBLIC Extension License") ActivationSuccess: Boolean
    var
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        ResponseBody: Text;
    begin
        ActivationSuccess := CheckPlatformCanActivate(SPBExtensionLicense, ResponseBody);
        if ActivationSuccess then
            DoActivationInLocalSystem(SPBExtensionLicense);

        if ActivationSuccess then
            SPBLICTelemetry.LicenseActivation(SPBExtensionLicense)
        else
            SPBLICTelemetry.LicenseActivationFailure(SPBExtensionLicense);

        OnAfterActivate(SPBExtensionLicense);
    end;

    local procedure CheckPlatformCanActivate(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ActivationSuccess: Boolean
    var
        LicensePlatform: Interface "SPBLIC ILicenseCommunicator";
        LicensePlatformV2: Interface "SPBLIC ILicenseCommunicator2";
        ActivationFailureErr: Label 'An error occurred validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        NoRemainingUsesErr: Label 'There are no remaining uses of that license key to assign to this installation.';
        AppInfo: ModuleInfo;
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        LicensePlatformV2 := SPBExtensionLicense."License Platform";
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        // First validate the license key without consuming it (for LemonSqueezy)
        ValidateBeforeActivation(SPBExtensionLicense);

        if LicensePlatformV2.CallAPIForActivation(SPBExtensionLicense, ResponseBody) then begin
            if LicensePlatformV2.ClientSideLicenseCount(SPBExtensionLicense) then begin
                if LicensePlatform.CheckAPILicenseCount(SPBExtensionLicense, ResponseBody) then
                    ActivationSuccess := true
                else
                    Error(NoRemainingUsesErr)
            end else
                // if the Activation is Server Side, then the activation would have failed on a count issue
                ActivationSuccess := true;
            LicensePlatform.PopulateSubscriptionFromResponse(SPBExtensionLicense, ResponseBody);
            ValidateConfigurationConsistency(SPBExtensionLicense);
        end else
            // In case of a malformed Implementation where the user is given no errors by the API call CU, we'll have a failsafe one here
            Error(ActivationFailureErr, AppInfo.Publisher());
    end;

    local procedure DoActivationInLocalSystem(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
        SPBLICIsoStoreManager: Codeunit "SPBLIC IsoStore Manager";
        LicenseKeyExpiredErr: Label 'The License Key provided has already expired due to a Subscription End.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        AppInfo: ModuleInfo;
    begin
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        if (SPBExtensionLicense."Subscription End Date" <> 0DT) and
          (SPBExtensionLicense."Subscription End Date" < CurrentDateTime())
        then begin
            SPBExtensionLicense.Activated := false;
            SPBExtensionLicense.Modify();
            Commit();
            SPBLICEvents.OnAfterActivationFailure(SPBExtensionLicense, AppInfo);
            Error(LicenseKeyExpiredErr, AppInfo.Publisher());
        end else begin
            SPBExtensionLicense.Modify();
            Commit();
            SPBLICEvents.OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
        end;

        // Now pop the details into IsolatedStorage
        SPBLICIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        exit(SPBExtensionLicense.Activated);
    end;

    local procedure ValidateBeforeActivation(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        LemonSqueezyComm: Codeunit "SPBLIC LemonSqueezy Comm.";
        PreValidationFailedErr: Label 'Unable to validate license key before activation. Please check your internet connection and try again.';
        AppInfo: ModuleInfo;
        ResponseBody: Text;
    begin
        // For LemonSqueezy platform, validate the license key first to prevent consuming it for wrong products
        if SPBExtensionLicense."License Platform" = SPBExtensionLicense."License Platform"::LemonSqueezy then
            if LemonSqueezyComm.CallAPIForPreActivationValidation(SPBExtensionLicense, ResponseBody) then
                LemonSqueezyComm.ValidateProductMatch(SPBExtensionLicense, ResponseBody)
            else begin
                NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
                Error(PreValidationFailedErr);
            end;
        // Other platforms can add their own pre-validation logic here
    end;

    local procedure OnAfterActivate(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        SPBLICEvents.OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
    end;

    local procedure ValidateConfigurationConsistency(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        IncompleteMetadataErr: Label 'License activation succeeded but subscription metadata is incomplete. This may indicate a platform configuration issue.';
    begin
        if SPBExtensionLicense.IsUsageBased then
            if (SPBExtensionLicense."Subscription Item Id" = 0) or
               (SPBExtensionLicense."Usage Aggregation Type" = '') then
                Error(IncompleteMetadataErr);
    end;
}