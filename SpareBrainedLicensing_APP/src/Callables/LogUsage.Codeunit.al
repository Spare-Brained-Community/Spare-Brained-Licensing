namespace SPB.Callables;

using SPB.EngineLogic;
using SPB.Extensibility;
using SPB.Storage;

/// <summary>
/// This codeunit is used to log usage of a submodule for a specific subscription.
/// It checks if the subscription is active and logs the usage if it is.
/// </summary>
codeunit 71033598 "SPBLIC LogUsage"
{

    var
        FailureToFindSubscriptionTok: Label 'Unable to find Subscription Entry (Filters %1)', Locked = true;

    /// <summary>
    /// This function logs usage for a specific subscription and submodule.
    /// </summary>
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="SubmoduleName">This should be the name of the submodule</param>
    /// <param name="UsageCount">This should be the number to increment by</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"SPBLIC Extension License", 'R', InherentPermissionsScope::Both)]
    procedure LogUsage(SubscriptionId: Guid; SubmoduleName: Text[100]; UsageCount: Integer; InactiveShowError: Boolean): Boolean
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBEvents: Codeunit "SPBLIC Events";
        NoSubscriptionFoundErr: Label 'No License was found in the Licenses list for Subscription %1 with Submodule name: %2', Comment = '%1 is the ID of the App. %2 is the Submodule.';
    begin
        SPBExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        SPBExtensionLicense.SetRange("Submodule Name", SubmoduleName);
        if not SPBExtensionLicense.FindFirst() then begin
            SPBEvents.OnAfterLogUsageFailure(SubscriptionId, SubmoduleName, StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));
            Error(NoSubscriptionFoundErr, SubscriptionId, SubmoduleName);
        end;
        exit(DoLogUsage(SPBExtensionLicense, UsageCount, InactiveShowError));
    end;

    internal procedure DoLogUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer; InactiveShowError: Boolean): Boolean
    var
        CheckActive: Codeunit "SPBLIC Check Active";
        LogUsageMeth: Codeunit "SPBLIC LogUsageMeth";
    begin
        if not CheckActive.DoCheckBasic(SPBExtensionLicense, InactiveShowError) then
            exit(false);
        // If we get here, the license is active, so we can log usage

        LogUsageMeth.LogUsage(SPBExtensionLicense, UsageCount);

        exit(true);
    end;


    /// <summary>
    /// This function sets the usage for a specific subscription and submodule.
    /// </summary>
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="SubmoduleName">This should be the name of the submodule</param>
    /// <param name="Quantity">This should be the quantity to log</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"SPBLIC Extension License", 'R', InherentPermissionsScope::Both)]
    procedure SetUsage(SubscriptionId: Guid; SubmoduleName: Text[100]; Quantity: Integer; InactiveShowError: Boolean): Boolean
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBEvents: Codeunit "SPBLIC Events";
        NoSubscriptionFoundErr: Label 'No License was found in the Licenses list for Subscription %1 with Submodule name: %2', Comment = '%1 is the ID of the App. %2 is the Submodule.';
    begin
        SPBExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        SPBExtensionLicense.SetRange("Submodule Name", SubmoduleName);
        if not SPBExtensionLicense.FindFirst() then begin
            SPBEvents.OnAfterLogUsageFailure(SubscriptionId, SubmoduleName, StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));
            Error(NoSubscriptionFoundErr, SubscriptionId, SubmoduleName);
        end;
        exit(DoSetUsage(SPBExtensionLicense, Quantity, InactiveShowError));
    end;

    internal procedure DoSetUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; Quantity: Integer; InactiveShowError: Boolean): Boolean
    var
        CheckActive: Codeunit "SPBLIC Check Active";
        LogUsageMeth: Codeunit "SPBLIC LogUsageMeth";
    begin
        if not CheckActive.DoCheckBasic(SPBExtensionLicense, InactiveShowError) then
            exit(false);
        // If we get here, the license is active, so we can log usage

        LogUsageMeth.SetUsage(SPBExtensionLicense, Quantity);

        exit(true);
    end;
}