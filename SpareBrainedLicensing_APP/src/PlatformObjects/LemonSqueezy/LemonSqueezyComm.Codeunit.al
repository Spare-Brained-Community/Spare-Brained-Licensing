codeunit 71033582 "SPBLIC LemonSqueezy Comm." implements "SPBLIC ILicenseCommunicator", "SPBLIC ILicenseCommunicator2"
{
    var
        LemonSqueezyActivateAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/activate?license_key=%1&instance_name=%2', Comment = '%1 is the license key, %2 is just a label in the Lemon Squeezy list of Licenses', Locked = true;
#pragma warning disable AA0240
        LemonSqueezyBillingEmailTok: Label 'support@sparebrained.com', Locked = true;
#pragma warning restore AA0240
        LemonSqueezyDeactivateAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/deactivate?license_key=%1&instance_id=%2', Comment = '%1 is the license key, %2 is the unique guid assigned by Lemon Squeezy for this installation, created during Activation.', Locked = true;
#pragma warning disable AA0240
        LemonSqueezySupportUrlTok: Label 'support@sparebrained.com', Locked = true;
#pragma warning restore AA0240
        LemonSqueezyTestProductIdTok: Label '39128', Locked = true;
        LemonSqueezyTestProductKeyTok: Label 'CE2F02DE-657C-4F76-8F93-0E352C9A30B2', Locked = true;
        LemonSqueezyTestProductUrlTok: Label 'https://sparebrained.lemonsqueezy.com/checkout/buy/cab72f9c-add0-47b0-9a09-feb3b4ccf8e0', Locked = true;
        LemonSqueezyVerifyAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/verify?license_key=%1&instance_id=%2', Comment = '%1 is the license key, %2 is the unique guid assigned by Lemon Squeezy for this installation, created during Activation.', Locked = true;

    procedure CallAPIForActivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text): Boolean
    var
        EnvInformation: Codeunit "Environment Information";
        OnPremEnvironmentIDTok: Label 'OnPrem-%1-%2', Comment = '%1 is the Tenant ID, %2 is the Environment name', Locked = true;
        ProdEnvironmentIDTok: Label 'Prod-%1-%2', Comment = '%1 is the Tenant ID, %2 is the Environment name', Locked = true;
        SandboxEnvironmentIDTok: Label 'Sandbox-%1-%2', Comment = '%1 is the Tenant ID, %2 is the Environment name', Locked = true;
        ActivateAPI: Text;
        EnvironID: Text;
    begin
        // When activating against LemonSqueezy, we want to register the tenant ID in their end, plus environ type
        case true of
            EnvInformation.IsOnPrem():
                EnvironID := StrSubstNo(OnPremEnvironmentIDTok, Database.TenantId(), EnvInformation.GetEnvironmentName());
            EnvInformation.IsSandbox():
                EnvironID := StrSubstNo(SandboxEnvironmentIDTok, Database.TenantId(), EnvInformation.GetEnvironmentName());
            EnvInformation.IsProduction():
                EnvironID := StrSubstNo(ProdEnvironmentIDTok, Database.TenantId(), EnvInformation.GetEnvironmentName());
        end;

        ActivateAPI := StrSubstNo(LemonSqueezyActivateAPITok, SPBExtensionLicense."License Key", EnvironID);
        exit(CallLemonSqueezy(ResponseBody, ActivateAPI));
    end;

    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean): Boolean
    var
        VerifyAPI: Text;
    begin
        // First, we'll crosscheck that the record's license_id matches the IsoStorage one for possible tamper checking
        ValidateLicenseIdInfo(SPBExtensionLicense);

        // When verifying the License, we have to pass the instance info that we stored on the record
        VerifyAPI := StrSubstNo(LemonSqueezyVerifyAPITok, SPBExtensionLicense."License Key", SPBExtensionLicense."Licensing ID");
        exit(CallLemonSqueezy(ResponseBody, VerifyAPI));
    end;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ResultOK: Boolean
    var
        DeactivateAPI: Text;
    begin
        // First, we'll crosscheck that the record's license_id matches the IsoStorage one for possible tamper checking
        ValidateLicenseIdInfo(SPBExtensionLicense);

        // When verifying the License, we have to pass the instance info that we stored on the record
        DeactivateAPI := StrSubstNo(LemonSqueezyDeactivateAPITok, SPBExtensionLicense."License Key", SPBExtensionLicense."Licensing ID");
        exit(CallLemonSqueezy(ResponseBody, DeactivateAPI));
    end;

    local procedure CallLemonSqueezy(var ResponseBody: Text; LemonSquezyRequestUri: Text): Boolean
    var
        NAVAppSetting: Record "NAV App Setting";
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        EnvironmentBlockErr: Label 'Unable to communicate with the license server due to an environment block. Please resolve and try again.';
        WebCallErr: Label 'Unable to verify or activate license.\ %1: %2 \ %3', Comment = '%1 %2 %3';
        AppInfo: ModuleInfo;
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

        ApiHttpRequestMessage.SetRequestUri(LemonSquezyRequestUri);
        ApiHttpRequestMessage.Method('POST');

        if not ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsBlockedByEnvironment then
                Error(EnvironmentBlockErr)
            else
                Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode, ApiHttpResponseMessage.ReasonPhrase, ApiHttpResponseMessage.Content);
        end else
            if ApiHttpResponseMessage.IsSuccessStatusCode() then begin
                ApiHttpResponseMessage.Content.ReadAs(ResponseBody);
                exit(true);
            end else
                Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode, ApiHttpResponseMessage.ReasonPhrase, ApiHttpResponseMessage.Content);
    end;

    local procedure ValidateLicenseIdInfo(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        SPBIsoStoreManager: Codeunit "SPBLIC IsoStore Manager";
        LSqueezyIdJson: JsonObject;
        LSqueezyIdJsonToken: JsonToken;
        TempPlaceholder: Text;
    begin
        if SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'licensingId', TempPlaceholder) then
            if LSqueezyIdJson.ReadFrom(TempPlaceholder) then
                if LSqueezyIdJson.Get('id', LSqueezyIdJsonToken) then
                    if LSqueezyIdJsonToken.AsValue().AsText() <> SPBExtensionLicense."Licensing ID" then
                        ReportPossibleMisuse(SPBExtensionLicense);
    end;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        SPBLICEvents: Codeunit "SPBLIC Events";
    begin
        // Potential future use of 'reporting' misuse attempts.   For example, someone programmatically changing the Subscription Record
        SPBLICEvents.OnAfterThrowPossibleMisuse(SPBExtensionLicense);
    end;

#pragma warning disable AA0150
    //The interface implements this as 'var', so yes, this is fine.
    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text)
#pragma warning restore AA0150
    var
        TempJsonBuffer: Record "JSON Buffer" temporary;
        SPBIsoStoreManager: Codeunit "SPBLIC IsoStore Manager";
        CurrentActiveStatus: Boolean;
        InstanceInfo: JsonObject;
        LSqueezyJson: JsonObject;
        LSqueezyToken: JsonToken;
        CommunicationFailureErr: Label 'An error occurred communicating with the licensing platform.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        AppInfo: ModuleInfo;
        SqueezyReponseType: Option " ",Activation,Validation,Deactivation;
        TempPlaceholder: Text;
    begin
        // This is a generic function to process all Responses, regardless of Activation, Validation, or Deactivation
        // Which means we need to detect what mode we're in.
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        LSqueezyJson.ReadFrom(ResponseBody);
        case true of
            LSqueezyJson.Get('activated', LSqueezyToken):
                begin
                    SqueezyReponseType := SqueezyReponseType::Activation;
                    CurrentActiveStatus := LSqueezyToken.AsValue().AsBoolean();
                end;
            LSqueezyJson.Get('valid', LSqueezyToken):
                begin
                    SqueezyReponseType := SqueezyReponseType::Validation;
                    CurrentActiveStatus := LSqueezyToken.AsValue().AsBoolean();
                end;
            LSqueezyJson.Get('deactivated', LSqueezyToken):
                begin
                    SqueezyReponseType := SqueezyReponseType::Deactivation;
                    // We flip. If deactivated is true, then it's not active.
                    CurrentActiveStatus := not LSqueezyToken.AsValue().AsBoolean();
                end;
        end;
        if SqueezyReponseType = SqueezyReponseType::" " then
            Error(CommunicationFailureErr, AppInfo.Publisher);

        TempJsonBuffer.ReadFromText(ResponseBody);

        // Update the current Subscription record
        SPBExtensionLicense.Validate(Activated, CurrentActiveStatus);
        TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'created_at', 'license_key');
        Evaluate(SPBExtensionLicense."Created At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'expires_at', 'license_key');
        Evaluate(SPBExtensionLicense."Subscription Ended At", TempPlaceholder);

        // TODO: Pending Request to Lemon Squeezy team to add this to their API
        //TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'email', 'license_key');
        //SPBExtensionLicense."Subscription Email" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."Subscription Email"));
        SPBExtensionLicense.CalculateEndDate();

        // Lemon Squeezy relies on having storage of the "instance ID" to verify an instance is still active
        if SqueezyReponseType = SqueezyReponseType::Activation then begin
            TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'id', '*instance*');
            SPBExtensionLicense."Licensing ID" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."Licensing ID"));
            InstanceInfo.Add('id', TempPlaceholder);
            TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'name', '*instance*');
            InstanceInfo.Add('name', TempPlaceholder);

            InstanceInfo.WriteTo(TempPlaceholder);
            SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'licensingId', SPBExtensionLicense."Licensing ID");
        end;
    end;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean;
    begin
        // LemonSqueezy allows self-unregistration of an instance of a license 
        exit(true);
    end;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean;
    begin
        exit(false);
    end;

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text): Boolean
    begin
        // LemonSqueezy does server side count checking during the Activation flow, so we should NOT check client side.
        exit(true);
    end;

    procedure SampleKeyFormatText(): Text
    var
        LemonSqueezyKeyFormatTok: Label 'The key will look like XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.';
    begin
        exit(LemonSqueezyKeyFormatTok);
    end;

    procedure GetTestProductUrl(): Text
    begin
        exit(LemonSqueezyTestProductUrlTok);
    end;

    procedure GetTestProductId(): Text
    begin
        exit(LemonSqueezyTestProductIdTok);
    end;

    procedure GetTestProductKey(): Text
    begin
        exit(LemonSqueezyTestProductKeyTok);
    end;

    procedure GetTestSupportUrl(): Text
    begin
        exit(LemonSqueezySupportUrlTok);
    end;

    procedure GetTestBillingEmail(): Text
    begin
        exit(LemonSqueezyBillingEmailTok);
    end;
}
