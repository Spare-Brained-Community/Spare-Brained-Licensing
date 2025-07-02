codeunit 71033586 "SPBLIC Version Check"
{
    Access = Internal;

    var
        SPBLICEvents: Codeunit "SPBLIC Events";

    procedure DoVersionCheck(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        UserTask: Record "User Task";
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        IsHandled: Boolean;
        ApiHttpResponseMessage: HttpResponseMessage;
        DocsTok: Label 'https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center-manage-apps#get-an-overview-and-check-for-updates', Locked = true;
        SubjectTok: Label 'Update Extension: %1', Comment = '%1 is Extension Name';
        AppInfo: ModuleInfo;
        VersionResponseBody: Text;
        LatestVersion: Version;
    begin
        SPBLICEvents.OnBeforeVersionCheck(SPBExtensionLicense, IsHandled);
        if IsHandled then
            exit;

        NavApp.GetCurrentModuleInfo(AppInfo);
        if SPBExtensionLicense."Version Check URL" = '' then
            exit;

        if GetNewVersionFromURI(SPBExtensionLicense, ApiHttpResponseMessage, VersionResponseBody) then begin
            LatestVersion := Version.Create(VersionResponseBody);
            if (AppInfo.AppVersion < LatestVersion) then begin
                SPBExtensionLicense."Update Available" := true;
                SPBExtensionLicense.Modify();

                SPBLICEvents.OnBeforeVersionCheckUpgradeAvailable(SPBExtensionLicense, LatestVersion, IsHandled);
                if IsHandled then
                    exit;

                UserTask.Init();
                UserTask.Title := StrSubstNo(SubjectTok, AppInfo.Name);
                UserTask.SetDescription(DocsTok);
                if not IsNullGuid(SPBExtensionLicense."Activated By") then
                    UserTask."Assigned To" := SPBExtensionLicense."Activated By";
                UserTask."Due DateTime" := CurrentDateTime;
                UserTask."Start DateTime" := CurrentDateTime;
                UserTask."Object Type" := UserTask."Object Type"::Page;
                UserTask."Object ID" := Page::"SPBLIC Extension Licenses";
                UserTask.Insert(true);
            end;
        end else
            SPBLICEvents.OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
        SPBLICTelemetry.VersionUpdateCheck(SPBExtensionLicense);
    end;

    local procedure GetNewVersionFromURI(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ApiHttpResponseMessage: HttpResponseMessage; var VersionResponseBody: Text): Boolean
    var
        IsHandled: Boolean;
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
    begin
        SPBLICEvents.OnBeforeVersionCheckCall(SPBExtensionLicense, ApiHttpResponseMessage, VersionResponseBody, IsHandled);
        if not IsHandled then begin
            ApiHttpRequestMessage.SetRequestUri(SPBExtensionLicense."Version Check URL");
            ApiHttpRequestMessage.Method('GET');

            if ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then
                if ApiHttpResponseMessage.IsSuccessStatusCode then
                    ApiHttpResponseMessage.Content.ReadAs(VersionResponseBody);
        end;
        SPBLICEvents.OnAfterVersionCheckCall(SPBExtensionLicense, ApiHttpResponseMessage, VersionResponseBody);
    end;
}
