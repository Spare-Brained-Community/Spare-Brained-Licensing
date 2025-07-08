codeunit 90000 "TST License Install"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        IsInitialized: Boolean;

#pragma warning disable AA0005
    procedure Initialize()
    begin
        if not IsInitialized then begin
            IsInitialized := true;
        end;
    end;
#pragma warning restore AA0005

    //Scenario:  Validate that the 2 built-in Test licensing entries are created
    [Test]
    procedure ConfirmTestProductsInstalled()
    var
        ExtensionLicense: Record "SPBLIC Extension License";
        LicensingInstall: Codeunit "SPBLIC Licensing Install";
    begin
        Initialize();

        // Each Platform in the base Licensing app should exist by GUID
        ExtensionLicense.Get(LicensingInstall.GetGumroadTestAppId());
        ExtensionLicense.Get(LicensingInstall.GetLemonSqueezyTestAppId());
    end;
}