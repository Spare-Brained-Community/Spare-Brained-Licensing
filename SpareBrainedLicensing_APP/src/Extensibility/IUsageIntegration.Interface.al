interface "SPBLIC IUsageIntegration"
{
    procedure PopulateSubscriptionItemIdFromAPI(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text): Integer
    procedure LogUsageIncrement(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer): Boolean
    procedure LogUsageSet(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer): Boolean
}