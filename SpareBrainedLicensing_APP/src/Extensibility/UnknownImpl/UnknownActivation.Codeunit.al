codeunit 71033591 "SPBLIC Unknown Activation" implements "SPBLIC IActivation"
{
    Access = Internal;

    var
        UnknownPlatformErr: Label 'This License uses an unknown platform that may have been uninstalled or misconfigured.  Please contact %1 for help.', Comment = '%1 is the Support Email Address on the license record.';

#pragma warning disable AA0150
    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean): Boolean
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure CallAPIForActivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text): Boolean
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text): Boolean
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBLIC Extension License")
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text)
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text): Boolean
    begin
        Error(UnknownPlatformErr, SPBExtensionLicense."Billing Support Email");
    end;

#pragma warning restore AA0150
}
