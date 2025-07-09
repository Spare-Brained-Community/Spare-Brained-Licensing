codeunit 71033597 "SPBLIC LogUsageMeth"
{
    Access = Internal;

    procedure LogUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer) Success: Boolean
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
    begin
        Success := DoLogUsage(SPBExtensionLicense, UsageCount);

        // We throw the Event here before we begin to deactivate the subscription.
        SPBLICEvents.OnAfterLogUsage(SPBExtensionLicense, Success);
    end;

    procedure DoLogUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer): Boolean
    var
        UsageIntegration: Interface "SPBLIC IUsageIntegration";
    begin
        UsageIntegration := SPBExtensionLicense."License Platform";
        if not UsageIntegration.LogUsageIncrement(SPBExtensionLicense, UsageCount) then
            exit(false);
    end;

    procedure SetUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; Quantity: Integer) Success: Boolean
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
    begin
        Success := DoSetUsage(SPBExtensionLicense, Quantity);

        // We throw the Event here before we begin to deactivate the subscription.
        SPBLICEvents.OnAfterSetUsage(SPBExtensionLicense, Quantity, Success);
    end;

    procedure DoSetUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; Quantity: Integer): Boolean
    var
        UsageIntegration: Interface "SPBLIC IUsageIntegration";
    begin
        UsageIntegration := SPBExtensionLicense."License Platform";
        if not UsageIntegration.LogUsageSet(SPBExtensionLicense, Quantity) then
            exit(false);
    end;

}
