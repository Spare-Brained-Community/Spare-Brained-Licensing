namespace SPB.InstallUpgradeBC;

using SPB.Storage;
using SPB.Telemetry;
using System.Upgrade;

codeunit 71033581 "SPBLIC Upgrade"
{
    Access = Public;
    Permissions =
        tabledata "SPBLIC Extension License" = RMD;
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(v20ReasonLbl) then begin
            Performv20Upgrade();
            UpgradeTag.SetUpgradeTag(v20ReasonLbl);
        end;
        if not UpgradeTag.HasUpgradeTag(v21ReasonLbl) then begin
            Performv21Upgrade();
            UpgradeTag.SetUpgradeTag(v21ReasonLbl);
        end;
        SPBLICTelemetry.LicensingAppUpgraded();
    end;

    local procedure Performv20Upgrade()
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
    begin
        if SPBExtensionLicense.FindSet() then
            repeat
                if IsNullGuid(SPBExtensionLicense."Extension App Id") then begin
                    SPBExtensionLicense."Extension App Id" := SPBExtensionLicense."Entry Id";
                    SPBExtensionLicense.Modify(true);
                end;
            until SPBExtensionLicense.Next() = 0;
    end;

    local procedure Performv21Upgrade()
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBLicensingInstall: Codeunit "SPBLIC Licensing Install";
        AppInfo: ModuleInfo;
    begin
        // Removing any older Subscriptions that was just for Gumroad
        NavApp.GetCurrentModuleInfo(AppInfo);
        SPBExtensionLicense.SetRange("Extension App Id", AppInfo.Id());
        SPBExtensionLicense.DeleteAll();

        // To using the submodule system to test whatever platforms
        SPBLicensingInstall.PerformInstallOfTestSubscriptions();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure OnGetPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(v20ReasonLbl);
        PerDatabaseUpgradeTags.Add(v21ReasonLbl);
    end;


    var
        v20ReasonLbl: Label 'SBI-V20-20220430', Locked = true;
        v21ReasonLbl: Label 'SBILicensing-V21-20230212', Locked = true;
}