namespace SPB.Obsoleting;

using SPB.Storage;

codeunit 71033578 "SPBLIC License Management"
{
    InherentPermissions = X;
    ObsoleteReason = 'Refactored to new Method Codeunits and separate Event wrapper.';
    ObsoleteState = Pending;
    Permissions = tabledata "SPBLIC Extension License" = RIM;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterLicenseDeactivated(var SPBExtensionLicense: Record "SPBLIC Extension License")
    begin
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterLicenseDeactivatedByPlatform(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text)
    begin
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationFailure(var SPBExtensionLicense: Record "SPBLIC Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVersionCheckUpgradeAvailable(var SPBExtensionLicense: Record "SPBLIC Extension License"; var LatestVersion: Version; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationSuccess(var SPBExtensionLicense: Record "SPBLIC Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterVersionCheckFailure(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ApiHttpRespMessage: HttpResponseMessage)
    begin
    end;

    [Obsolete('Use new Events in SPBLIC Events codeunit.')]
    [IntegrationEvent(false, false)]
    internal procedure OnAfterThrowPossibleMisuse(var SPBExtensionLicense: Record "SPBLIC Extension License")
    begin
    end;
}
