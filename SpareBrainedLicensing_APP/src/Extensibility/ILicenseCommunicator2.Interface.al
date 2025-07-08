interface "SPBLIC ILicenseCommunicator2"
{
    ObsoleteReason = 'Reorganization. Use IActivation instead for most activation related systems, IProduct for test related calls.';
    ObsoleteState = Pending;

    procedure CallAPIForActivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ResultOK: Boolean;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ResultOK: Boolean;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean;

    procedure GetTestProductUrl(): Text;

    procedure GetTestProductId(): Text;

    procedure GetTestProductKey(): Text;

    procedure GetTestSupportUrl(): Text;

    procedure GetTestBillingEmail(): Text;
}
