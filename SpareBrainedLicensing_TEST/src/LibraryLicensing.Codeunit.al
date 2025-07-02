codeunit 90006 "TST Library - Licensing"
{
    procedure CreateAppRegistration(var ExtensionLicense: Record "SPBLIC Extension License"; Platform: Enum "SPBLIC License Platform")
    var
        ExtensionRegistration: Codeunit "SPBLIC Extension Registration";
        AppInfo: ModuleInfo;
    begin
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
            Platform,
            true
        );

        ExtensionLicense.Get(AppInfo.Id);
    end;

    procedure CreateAppRegistration(var ExtensionLicense: Record "SPBLIC Extension License")
    begin
        // This overload assumes MockSuccess
        CreateAppRegistration(ExtensionLicense, Enum::"SPBLIC License Platform"::MockSuccess);
    end;
}
