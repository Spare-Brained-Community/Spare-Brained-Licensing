interface "SPBLIC ILicenseCommunicator"
{
    ObsoleteReason = 'Reorganization. Use IActivation instead for most activation related systems.';
    ObsoleteState = Pending;

    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBLIC Extension License");

    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text);

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text): Boolean

    procedure SampleKeyFormatText(): Text;
}