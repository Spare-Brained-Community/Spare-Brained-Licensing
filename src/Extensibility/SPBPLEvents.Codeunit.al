codeunit 71041 "CAVSB Events"
{
    #region UIEvents
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "CAVSB Extension License"; var IsHandled: Boolean)
    begin
    end;
    #endregion UIEvents

    #region ActiveCheckEvents
    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckActiveBasic(var SPBExtensionLicense: Record "CAVSB Extension License"; IsActive: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckActiveBasicFailure(SubscriptionId: Guid; SubmoduleName: Text[100]; FailureReason: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckActiveFailure(var SPBExtensionLicense: Record "CAVSB Extension License"; IsActive: Boolean; FailureReason: Text);
    begin
    end;
    #endregion ActiveCheckEvents

    #region VersionEvents
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeVersionCheckUpgradeAvailable(var SPBExtensionLicense: Record "CAVSB Extension License"; var LatestVersion: Version; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterVersionCheckFailure(var SPBExtensionLicense: Record "CAVSB Extension License"; var ApiHttpRespMessage: HttpResponseMessage)
    begin
    end;
    #endregion VersionEvents

    #region MisuseEvents
    [IntegrationEvent(false, false)]
    internal procedure OnAfterThrowPossibleMisuse(var SPBExtensionLicense: Record "CAVSB Extension License")
    begin
    end;
    #endregion MisuseEvents

    #region Activation
    [IntegrationEvent(false, false)]
    internal procedure OnAfterActivationSuccess(var SPBExtensionLicense: Record "CAVSB Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterActivationFailure(var SPBExtensionLicense: Record "CAVSB Extension License"; var AppInfo: ModuleInfo)
    begin
    end;
    #endregion Activation


    #region DeActivation
    [IntegrationEvent(false, false)]
    internal procedure OnAfterLicenseDeactivated(var SPBExtensionLicense: Record "CAVSB Extension License")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterLicenseDeactivatedByPlatform(var SPBExtensionLicense: Record "CAVSB Extension License"; ResponseBody: Text)
    begin
    end;
    #endregion DeActivation

}
