codeunit 71033583 "SPBLIC Events"
{
    #region UIEvents
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "SPBLIC Extension License"; var IsHandled: Boolean)
    begin
    end;
    #endregion UIEvents

    #region ActiveCheckEvents
    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckActiveBasic(var SPBExtensionLicense: Record "SPBLIC Extension License"; IsActive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckActiveBasicFailure(SubscriptionId: Guid; SubmoduleName: Text[100]; FailureReason: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterLogUsageFailure(SubscriptionId: Guid; SubmoduleName: Text[100]; FailureReason: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckActiveFailure(var SPBExtensionLicense: Record "SPBLIC Extension License"; IsActive: Boolean; FailureReason: Text)
    begin
    end;
    #endregion ActiveCheckEvents

    #region VersionEvents
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeVersionCheckUpgradeAvailable(var SPBExtensionLicense: Record "SPBLIC Extension License"; var LatestVersion: Version; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterVersionCheckFailure(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ApiHttpRespMessage: HttpResponseMessage)
    begin
    end;
    #endregion VersionEvents

    #region MisuseEvents
    [IntegrationEvent(false, false)]
    internal procedure OnAfterThrowPossibleMisuse(var SPBExtensionLicense: Record "SPBLIC Extension License")
    begin
    end;
    #endregion MisuseEvents

    #region Activation
    [IntegrationEvent(false, false)]
    internal procedure OnAfterActivationSuccess(var SPBExtensionLicense: Record "SPBLIC Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterActivationFailure(var SPBExtensionLicense: Record "SPBLIC Extension License"; var AppInfo: ModuleInfo)
    begin
    end;
    #endregion Activation


    #region DeActivation
    [IntegrationEvent(false, false)]
    internal procedure OnAfterLicenseDeactivated(var SPBExtensionLicense: Record "SPBLIC Extension License")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterLicenseDeactivatedByPlatform(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterSetUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; Quantity: Integer; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterLogUsage(var SPBExtensionLicense: Record "SPBLIC Extension License"; var Success: Boolean)
    begin
    end;
    #endregion DeActivation

}
