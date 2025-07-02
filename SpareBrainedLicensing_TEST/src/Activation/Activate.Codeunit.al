codeunit 90007 "TST Activate"
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
    procedure CanActivate()
    begin
        Initialize();


    end;
}
