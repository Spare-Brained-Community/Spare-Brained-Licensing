codeunit 90001 "TST App Registration"
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

    // Scenario - when an app is registered, there should be a License entry for it.
    [Test]
    procedure TestBasicRegistration()
    var
        ExtensionLicense: Record "SPBLIC Extension License";
        ExtensionRegistration: Codeunit "SPBLIC Extension Registration";
        AppInfo: ModuleInfo;
    begin
        Initialize();

        // Given an app, in this case the test app is fine.
        NavApp.GetCurrentModuleInfo(AppInfo);

        // When we register it:
        ExtensionRegistration.RegisterExtension(
            AppInfo,
            'TestBasic',
            'https://sparebrained.com',
            'https://sparebrained.com',
            'support@sparebrained.com',
            '',
            '',
            0,
            0,
            Version.Create('2.0.0.0'),
            Enum::"SPBLIC License Platform"::MockSuccess,
            true
        );

        // Then an extension should exist for it
        ExtensionLicense.SetRange("Entry Id", AppInfo.Id);
        Assert.RecordCount(ExtensionLicense, 1);

        // Then it should have the correct Platform
        ExtensionLicense.Get(AppInfo.Id);
        Assert.AreEqual(Enum::"SPBLIC License Platform"::MockSuccess, ExtensionLicense."License Platform", 'Unexpected license platform.');
    end;
}