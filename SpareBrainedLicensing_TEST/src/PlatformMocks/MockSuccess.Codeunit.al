codeunit 90002 "TST Mock Success" implements "SPBLIC IActivation"
{
#pragma warning disable AA0150
    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean
    begin
        exit(true);
    end;

    procedure CallAPIForActivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ResultOK: Boolean
    begin
        exit(true);
    end;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ResultOK: Boolean
    begin
        exit(true);
    end;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    begin
        exit(true);
    end;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    begin
        exit(true);
    end;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBLIC Extension License")
    begin

    end;

    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text)
    begin

    end;

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text): Boolean
    begin

    end;
#pragma warning restore AA0150
}
