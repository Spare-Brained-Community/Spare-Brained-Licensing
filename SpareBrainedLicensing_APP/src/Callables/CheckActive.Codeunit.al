namespace SPB.Callables;

using SPB.EngineLogic;
using SPB.Extensibility;
using SPB.Storage;

/// <summary>
/// This Codeunit is for checking basic active/inactive functions to be used by 3rd parties wanting to validate
/// if a license is active.  Two main options exist at this time - with or without Submodule functionality.
/// </summary>
codeunit 71033584 "SPBLIC Check Active"
{
    Access = Public;
    /// <summary>
    /// This function takes an App ID and checks if it is active or not, along with if the user should be shown errors if Inactive.
    /// </summary> 
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"SPBLIC Extension License", 'R', InherentPermissionsScope::Both)]
    procedure CheckBasic(SubscriptionId: Guid; InactiveShowError: Boolean) IsActive: Boolean
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBEvents: Codeunit "SPBLIC Events";
        NoSubFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1', Comment = '%1 is the ID of the App.';
    begin
        SPBExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        //If using this function signature, the Submodule functionality should NOT be considered.
        SPBExtensionLicense.SetRange("Submodule Name", '');
        if not SPBExtensionLicense.FindFirst() then begin
            SPBEvents.OnAfterCheckActiveBasicFailure(SubscriptionId, '', StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));
            Error(NoSubFoundErr, SubscriptionId);
        end;

        IsActive := DoCheckBasic(SPBExtensionLicense, InactiveShowError);
    end;

    /// <summary>
    /// This function takes an App ID and Submodule Name and checks if it is active or not, along with if the user should be shown errors if Inactive.
    /// </summary>
    /// <param name="SubmoduleId">This should be the submodule to check for</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"SPBLIC Extension License", 'R', InherentPermissionsScope::Both)]
    procedure CheckBasicSubmodule(SubmoduleId: Guid; InactiveShowError: Boolean) IsActive: Boolean
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBEvents: Codeunit "SPBLIC Events";
    begin
        if not SPBExtensionLicense.Get(SubmoduleId) then begin
            SPBEvents.OnAfterCheckActiveBasicFailure(SPBExtensionLicense."Extension App Id", SPBExtensionLicense."Submodule Name", StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));
            Error(NoSubscriptionFoundErr, SPBExtensionLicense."Extension App Id", SPBExtensionLicense."Submodule Name");
        end;

        IsActive := DoCheckBasic(SPBExtensionLicense, InactiveShowError);
    end;

    /// <summary>
    /// This function takes an App ID and Submodule Name and checks if it is active or not, along with if the user should be shown errors if Inactive.
    /// </summary>
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="SubmoduleName">This should be the submodule to check for</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"SPBLIC Extension License", 'R', InherentPermissionsScope::Both)]
    procedure CheckBasicSubmodule(SubscriptionId: Guid; SubmoduleName: Text[100]; InactiveShowError: Boolean) IsActive: Boolean
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBEvents: Codeunit "SPBLIC Events";
    begin
        SPBExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        SPBExtensionLicense.SetRange("Submodule Name", SubmoduleName);
        if not SPBExtensionLicense.FindFirst() then begin
            SPBEvents.OnAfterCheckActiveBasicFailure(SubscriptionId, SubmoduleName, StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));
            Error(NoSubscriptionFoundErr, SubscriptionId, SubmoduleName);
        end;

        IsActive := DoCheckBasic(SPBExtensionLicense, InactiveShowError);
    end;

    internal procedure DoCheckBasic(var SPBExtensionLicense: Record "SPBLIC Extension License"; InactiveShowError: Boolean): Boolean
    var
        SPBLICCheckActiveMeth: Codeunit "SPBLIC Check Active Meth";
        IsActive: Boolean;
        SubscriptionInactiveErr: Label 'The License for %1 is not Active.  Contact your system administrator to re-activate it.', Comment = '%1 is the name of the Extension.';
    begin
        IsActive := SPBLICCheckActiveMeth.CheckIfActive(SPBExtensionLicense);
        if not IsActive and InactiveShowError then
            Error(SubscriptionInactiveErr, SPBExtensionLicense."Extension Name");
        exit(IsActive);
    end;

    var
        FailureToFindSubscriptionTok: Label 'Unable to find Subscription Entry (Filters %1)', Locked = true;
        NoSubscriptionFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1 with Submodule name: %2', Comment = '%1 is the ID of the App. %2 is the Submodule.';
}
