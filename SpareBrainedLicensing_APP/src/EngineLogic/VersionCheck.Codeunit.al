codeunit 71033586 "SPBLIC Version Check"
{
    Access = Internal;

    procedure DoVersionCheck(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        UserTask: Record "User Task";
        SPBLICEvents: Codeunit "SPBLIC Events";
        SPBLICTelemetry: Codeunit "SPBLIC Telemetry";
        IsHandled: Boolean;
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        DocsTok: Label 'https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center-manage-apps#get-an-overview-and-check-for-updates', Locked = true;
        SubjectTok: Label 'Update Extension: %1', Comment = '%1 is Extension Name';
        AppInfo: ModuleInfo;
        VersionResponseBody: Text;
        LatestVersion: Version;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if SPBExtensionLicense."Version Check URL" = '' then
            exit;

        ApiHttpRequestMessage.SetRequestUri(SPBExtensionLicense."Version Check URL");
        ApiHttpRequestMessage.Method('GET');

        if ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsSuccessStatusCode() then begin
                ApiHttpResponseMessage.Content().ReadAs(VersionResponseBody);
                LatestVersion := Version.Create(VersionResponseBody);
                if (AppInfo.AppVersion() < LatestVersion) then begin
                    SPBExtensionLicense."Update Available" := true;
                    SPBExtensionLicense.Modify();

                    SPBLICEvents.OnBeforeVersionCheckUpgradeAvailable(SPBExtensionLicense, LatestVersion, IsHandled);
                    if IsHandled then
                        exit;

                    UserTask.Init();
                    UserTask.Title := StrSubstNo(SubjectTok, AppInfo.Name());
                    UserTask.SetDescription(DocsTok);
                    if not IsNullGuid(SPBExtensionLicense."Activated By") then
                        UserTask."Assigned To" := SPBExtensionLicense."Activated By";
                    UserTask."Due DateTime" := CurrentDateTime();
                    UserTask."Start DateTime" := CurrentDateTime();
                    UserTask."Object Type" := UserTask."Object Type"::Page;
                    UserTask."Object ID" := Page::"SPBLIC Extension Licenses";
                    UserTask.Insert(true);
                end;
            end else
                SPBLICEvents.OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
        end else
            SPBLICEvents.OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
        SPBLICTelemetry.VersionUpdateCheck(SPBExtensionLicense);
    end;
}
