codeunit 71035 "CAVSB Gumroad Communicator" implements "CAVSB ILicenseCommunicator", "CAVSB ILicenseCommunicator2"
{

    var
        GumroadBillingEmailTok: Label 'support@sparebrained.com', Locked = true;
        GumroadKeyFormatTok: Label 'The key will look like XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX.';
        GumroadSupportUrlTok: Label 'support@sparebrained.com', Locked = true;
        GumroadTestProductIdTok: Label 'bwdCu', Locked = true;
        GumroadTestProductKeyTok: Label '21E2339D-F24D4A92-9813B4F2-8ABA083C', Locked = true;
        GumroadTestProductUrlTok: Label 'https://sparebrained.gumroad.com/l/SBILicensingTest', Locked = true;
        GumroadVerifyAPITok: Label 'https://api.gumroad.com/v2/licenses/verify?product_permalink=%1&license_key=%2&increment_uses_count=%3', Comment = '%1 %2 %3', Locked = true;

    procedure CallAPIForActivation(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text) ResultOK: Boolean
    begin
        exit(CallAPIForVerification(SPBExtensionLicense, ResponseBody, true));
    end;

    procedure CallAPIForVerification(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean
    var
        NAVAppSetting: Record "NAV App Setting";
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        EnvironmentBlockErr: Label 'Unable to communicate with the license server due to an environment block. Please resolve and try again.';
        WebCallErr: Label 'Unable to verify or activate license.\ %1: %2 \ %3', Comment = '%1 %2 %3';
        AppInfo: ModuleInfo;
        VerifyAPI: Text;
    begin
        // We REQUIRE HTTP access, so we'll force it on, regardless of Sandbox
        NavApp.GetCurrentModuleInfo(AppInfo);
        if NAVAppSetting.Get(AppInfo.Id) then begin
            if not NAVAppSetting."Allow HttpClient Requests" then begin
                NAVAppSetting."Allow HttpClient Requests" := true;
                NAVAppSetting.Modify();
            end
        end else begin
            NAVAppSetting."App ID" := AppInfo.Id;
            NAVAppSetting."Allow HttpClient Requests" := true;
            NAVAppSetting.Insert();
        end;

        VerifyAPI := StrSubstNo(GumroadVerifyAPITok, SPBExtensionLicense."Product Code", SPBExtensionLicense."License Key", Format(IncrementLicenseCount, 0, 9));
        ApiHttpRequestMessage.SetRequestUri(VerifyAPI);
        ApiHttpRequestMessage.Method('POST');

        if not ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsBlockedByEnvironment then begin
                if GuiAllowed() then
                    Error(EnvironmentBlockErr)
            end else
                if GuiAllowed() then
                    Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode, ApiHttpResponseMessage.ReasonPhrase, ApiHttpResponseMessage.Content);
        end else
            if ApiHttpResponseMessage.IsSuccessStatusCode() then begin
                ApiHttpResponseMessage.Content.ReadAs(ResponseBody);
                exit(true);
            end else
                if GuiAllowed() then
                    Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode, ApiHttpResponseMessage.ReasonPhrase, ApiHttpResponseMessage.Content);
    end;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text) ResultOK: Boolean
    begin
        exit(CallAPIForVerification(SPBExtensionLicense, ResponseBody, false));
    end;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "CAVSB Extension License")
    var
        CAVSBEvents: Codeunit "CAVSB Events";
    begin
        // Potential future use of 'reporting' misuse attempts.   For example, someone programmatically changing the Subscription Record
        CAVSBEvents.OnAfterThrowPossibleMisuse(SPBExtensionLicense);
    end;

#pragma warning disable AA0150 // TODO - Passed as "var" for the interface
    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text)
#pragma warning restore AA0150
    var
        TempJsonBuffer: Record "JSON Buffer" temporary;
        GumroadJson: JsonObject;
        GumroadToken: JsonToken;
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        AppInfo: ModuleInfo;
        TempPlaceholder: Text;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        GumroadJson.ReadFrom(ResponseBody);
        GumroadJson.Get('success', GumroadToken);
        if not GumroadToken.AsValue().AsBoolean() then
            if GuiAllowed() then
                Error(ActivationFailureErr, AppInfo.Publisher);
        GumroadJson.Get('purchase', GumroadToken);

        TempJsonBuffer.ReadFromText(ResponseBody);

        // Update the current Subscription record
        SPBExtensionLicense.Validate(Activated, true);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'created_at');
        Evaluate(SPBExtensionLicense."Created At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'subscription_ended_at');
        Evaluate(SPBExtensionLicense."Subscription Ended At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'subscription_cancelled_at');
        Evaluate(SPBExtensionLicense."Subscription Cancelled At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'subscription_failed_at');
        Evaluate(SPBExtensionLicense."Subscription Failed At", TempPlaceholder);

        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'email');
        SPBExtensionLicense."Subscription Email" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."Subscription Email"));
        SPBExtensionLicense.CalculateEndDate();
    end;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "CAVSB Extension License"): Boolean;
    begin
        // Gumroad only allows this using an API key, which is unique to each Publisher.  At this time,
        // I can't support the safe storage of that information 
        exit(false);
    end;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "CAVSB Extension License"): Boolean;
    begin
        exit(true);
    end;

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "CAVSB Extension License"; ResponseBody: Text): Boolean
    var
        TempJsonBuffer: Record "JSON Buffer" temporary;
        CAVSBenseUtilities: Codeunit "CAVSB License Utilities";
        LicenseCount: Integer;
        LicenseUses: Integer;
        GumroadJson: JsonObject;
        GumroadToken: JsonToken;
        GumroadErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        AppInfo: ModuleInfo;
    begin
        // The 'Test' product, we never do a Count check on this application
        if SPBExtensionLicense."Entry Id" = CAVSBenseUtilities.GetTestProductAppId() then
            exit(true);

        GumroadJson.ReadFrom(ResponseBody);
        GumroadJson.Get('success', GumroadToken);
        if not GumroadToken.AsValue().AsBoolean() then begin
            NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
            if GuiAllowed() then
                Error(GumroadErr, AppInfo.Publisher);
        end;
        GumroadJson.Get('purchase', GumroadToken);

        TempJsonBuffer.ReadFromText(ResponseBody);
        TempJsonBuffer.GetIntegerPropertyValue(LicenseUses, 'uses');
        TempJsonBuffer.GetIntegerPropertyValue(LicenseCount, 'quantity');

        exit(LicenseUses <= LicenseCount);
    end;

    procedure SampleKeyFormatText(): Text
    begin
        exit(GumroadKeyFormatTok);
    end;

    procedure GetTestProductUrl(): Text
    begin
        exit(GumroadTestProductUrlTok);
    end;

    procedure GetTestProductId(): Text
    begin
        exit(GumroadTestProductIdTok);
    end;

    procedure GetTestProductKey(): Text
    begin
        exit(GumroadTestProductKeyTok);
    end;

    procedure GetTestSupportUrl(): Text
    begin
        exit(GumroadSupportUrlTok);
    end;

    procedure GetTestBillingEmail(): Text
    begin
        exit(GumroadBillingEmailTok);
    end;

    [Obsolete('This event is moved to the central License Management codeunit for platform-agnostic eventing.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterThrowPossibleMisuse(SPBExtensionLicense: Record "CAVSB Extension License")
    begin
    end;
}