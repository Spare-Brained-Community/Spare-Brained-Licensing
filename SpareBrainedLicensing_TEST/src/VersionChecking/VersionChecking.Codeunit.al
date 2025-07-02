codeunit 90005 "TST Version Checking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ExtensionLicense: Record "SPBLIC Extension License";
        Assert: Codeunit "Assert";
        LibraryLicensing: Codeunit "TST Library - Licensing";
        IsInitialized: Boolean;

#pragma warning disable AA0005
    procedure Initialize()
    begin
        if not IsInitialized then begin
            LibraryLicensing.CreateAppRegistration(ExtensionLicense);
            IsInitialized := true;
        end;
    end;
#pragma warning restore AA0005

    [Test]
    procedure CheckNewVersionOK()
    var
        SPBLICVersionCheck: Codeunit "SPBLIC Version Check";
        TSTVCHealthy: Codeunit "TST VC Healthy";
    begin
        Initialize();

        // Given an app registration
        // Handled by initialize

        // Given a manual event binding to ensure a new version will be available
        BindSubscription(TSTVCHealthy);

        // When version checking
        SPBLICVersionCheck.DoVersionCheck(ExtensionLicense);

        // Then Unbind the subcription
        UnbindSubscription(TSTVCHealthy);

        // Then we should have an "Update" on the license
        Assert.IsTrue(ExtensionLicense."Update Available", 'Should have found a new version');
    end;
}
