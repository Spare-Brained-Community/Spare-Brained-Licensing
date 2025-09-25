namespace SPB.PlatformObjects.LemonSqueezy;

using SPB.Extensibility;
using SPB.Extensibility.ApiKey;
using SPB.Storage;
using System.Environment;
using System.Environment.Configuration;
using System.IO;

codeunit 71033582 "SPBLIC LemonSqueezy Comm." implements "SPBLIC ILicenseCommunicator", "SPBLIC ILicenseCommunicator2", "SPBLIC IUsageIntegration", "SPBLIC IActivationLimit"
{
    Access = Public;
    Permissions = tabledata "SPBLIC Extension License" = RM;

    var
        LemonSqueezyActivateAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/activate?license_key=%1&instance_name=%2', Comment = '%1 is the license key, %2 is just a label in the Lemon Squeezy list of Licenses', Locked = true;
#pragma warning disable AA0240
        LemonSqueezyBillingEmailTok: Label 'support@sparebrained.com', Locked = true;
        LemonSqueezySupportUrlTok: Label 'support@sparebrained.com', Locked = true;
#pragma warning restore AA0240
        LemonSqueezyDeactivateAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/deactivate?license_key=%1&instance_id=%2', Comment = '%1 is the license key, %2 is the unique guid assigned by Lemon Squeezy for this installation, created during Activation.', Locked = true;
        LemonSqueezyTestProductIdTok: Label '39128', Locked = true;
        LemonSqueezyTestProductKeyTok: Label 'CE2F02DE-657C-4F76-8F93-0E352C9A30B2', Locked = true;
        LemonSqueezyTestProductUrlTok: Label 'https://sparebrained.lemonsqueezy.com/checkout/buy/cab72f9c-add0-47b0-9a09-feb3b4ccf8e0', Locked = true;
        LemonSqueezySubscriptionsUrlTok: Label 'https://api.lemonsqueezy.com/v1/subscriptions?filter[store_id]=%1&filter[order_id]=%2&filter[order_item_id]=%3&filter[product_id]=%4', Locked = true, Comment = '%1 = Store ID, %2 = Order ID, %3 = Order Item ID, %4 = Product ID';
        LemonSqueezyUsageRecordUrlTok: Label 'https://api.lemonsqueezy.com/v1/usage-records', Locked = true, Comment = 'This is the URL to the Usage Records API endpoint.';
        LemonSqueezyPriceUrlTok: Label 'https://api.lemonsqueezy.com/v1/prices/%1', Locked = true, Comment = '%1 is the price ID to fetch pricing details including usage aggregation.';
        LemonSqueezyVerifyAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/validate?license_key=%1&instance_id=%2', Comment = '%1 is the license key, %2 is the unique guid assigned by Lemon Squeezy for this installation, created during Activation.', Locked = true;

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
        exit(CallLemonSqueezy(ResponseBody, ActivateAPI, SPBExtensionLicense.ApiKeyProvider));
    end;

    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean): Boolean
    var
        VerifyAPI: Text;
    begin
        // First, we'll crosscheck that the record's license_id matches the IsoStorage one for possible tamper checking
        ValidateLicenseIdInfo(SPBExtensionLicense);

        // When verifying the License, we have to pass the instance info that we stored on the record
        VerifyAPI := StrSubstNo(LemonSqueezyVerifyAPITok, SPBExtensionLicense."License Key", SPBExtensionLicense."Licensing ID");
        exit(CallLemonSqueezy(ResponseBody, VerifyAPI, SPBExtensionLicense.ApiKeyProvider));
    end;

    internal procedure CallAPIForPreActivationValidation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text): Boolean
    var
        LemonSqueezyValidateOnlyAPITok: Label 'https://api.lemonsqueezy.com/v1/licenses/validate?license_key=%1', Comment = '%1 is the license key', Locked = true;
        ValidateAPI: Text;
    begin
        // Validate license key without instance_id parameter for pre-activation validation
        ValidateAPI := StrSubstNo(LemonSqueezyValidateOnlyAPITok, SPBExtensionLicense."License Key");
        exit(this.CallLemonSqueezy(ResponseBody, ValidateAPI, SPBExtensionLicense.ApiKeyProvider));
    end;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text) ResultOK: Boolean
    var
        DeactivateAPI: Text;
    begin
        // First, we'll crosscheck that the record's license_id matches the IsoStorage one for possible tamper checking
        ValidateLicenseIdInfo(SPBExtensionLicense);

        // When verifying the License, we have to pass the instance info that we stored on the record
        DeactivateAPI := StrSubstNo(LemonSqueezyDeactivateAPITok, SPBExtensionLicense."License Key", SPBExtensionLicense."Licensing ID");
        exit(CallLemonSqueezy(ResponseBody, DeactivateAPI, SPBExtensionLicense.ApiKeyProvider));
    end;

    local procedure CallLemonSqueezy(var ResponseBody: Text; Method: Text; LemonSqueezyRequestUri: Text; ApiKeyProvider: Interface "SPBLIC IApiKeyProvider"): Boolean
    var
        RequestBody: JsonObject;
    begin
        exit(CallLemonSqueezy(ResponseBody, Method, LemonSqueezyRequestUri, ApiKeyProvider, RequestBody));
    end;

    local procedure CallLemonSqueezy(var ResponseBody: Text; LemonSqueezyRequestUri: Text; ApiKeyProvider: Interface "SPBLIC IApiKeyProvider"; RequestBody: JsonObject): Boolean
    begin
        exit(CallLemonSqueezy(ResponseBody, 'POST', LemonSqueezyRequestUri, ApiKeyProvider, RequestBody));
    end;

    local procedure CallLemonSqueezy(var ResponseBody: Text; LemonSqueezyRequestUri: Text; ApiKeyProvider: Interface "SPBLIC IApiKeyProvider"): Boolean
    var
        RequestBody: JsonObject;
    begin
        exit(CallLemonSqueezy(ResponseBody, 'POST', LemonSqueezyRequestUri, ApiKeyProvider, RequestBody));
    end;

    local procedure CallLemonSqueezy(var ResponseBody: Text; Method: Text; LemonSqueezyRequestUri: Text; ApiKeyProvider: Interface "SPBLIC IApiKeyProvider"; RequestBody: JsonObject): Boolean
    var
        NAVAppSetting: Record "NAV App Setting";
        ApiHttpClient: HttpClient;
        HttpContent: HttpContent;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        EnvironmentBlockErr: Label 'Unable to communicate with the license server due to an environment block. Please resolve and try again.';
        UsageError422Err: Label 'Usage tracking failed due to configuration mismatch. This often occurs when aggregation settings have changed. Please deactivate and reactivate your license to refresh the configuration.';
        WebCallErr: Label 'Unable to verify or activate license.\ %1: %2 \ %3', Comment = '%1 %2 %3';
        AppInfo: ModuleInfo;
        ApiKey: SecretText;
        ContentText: Text;
    begin
        // We REQUIRE HTTP access, so we'll force it on, regardless of Sandbox
        NavApp.GetCurrentModuleInfo(AppInfo);
        if NAVAppSetting.Get(AppInfo.Id()) then begin
            if not NAVAppSetting."Allow HttpClient Requests" then begin
                NAVAppSetting."Allow HttpClient Requests" := true;
                NAVAppSetting.Modify();
            end
        end else begin
            NAVAppSetting."App ID" := AppInfo.Id();
            NAVAppSetting."Allow HttpClient Requests" := true;
            NAVAppSetting.Insert();
        end;

        ApiKey := ApiKeyProvider.GetApiKey();
        if not ApiKey.IsEmpty() then
            ApiHttpClient.DefaultRequestHeaders().Add('Authorization', SecretStrSubstNo('Bearer %1', ApiKey));

        if RequestBody.Keys.Count() > 0 then begin
            RequestBody.WriteTo(ContentText);
            HttpContent.WriteFrom(ContentText);
            ApiHttpRequestMessage.Content(HttpContent);
        end;

        ApiHttpRequestMessage.SetRequestUri(LemonSqueezyRequestUri);
        ApiHttpRequestMessage.Method(Method);

        if not ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsBlockedByEnvironment() then
                Error(EnvironmentBlockErr)
            else
                Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode(), ApiHttpResponseMessage.ReasonPhrase(), ApiHttpResponseMessage.Content());
        end else
            if ApiHttpResponseMessage.IsSuccessStatusCode() then begin
                ApiHttpResponseMessage.Content().ReadAs(ResponseBody);
                exit(true);
            end else
                if (ApiHttpResponseMessage.HttpStatusCode() = 422) and
                   (LemonSqueezyRequestUri.Contains('usage-records')) then
                    Error(UsageError422Err)
                else
                    Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode(), ApiHttpResponseMessage.ReasonPhrase(), ApiHttpResponseMessage.Content());
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
        SqueezyResponseType: Option " ",Activation,Validation,Deactivation;
        TempPlaceholder: Text;
    begin
        // This is a generic function to process all Responses, regardless of Activation, Validation, or Deactivation
        // Which means we need to detect what mode we're in.
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        LSqueezyJson.ReadFrom(ResponseBody);
        case true of
            LSqueezyJson.Get('activated', LSqueezyToken):
                begin
                    SqueezyResponseType := SqueezyResponseType::Activation;
                    CurrentActiveStatus := LSqueezyToken.AsValue().AsBoolean();
                end;
            LSqueezyJson.Get('valid', LSqueezyToken):
                begin
                    SqueezyResponseType := SqueezyResponseType::Validation;
                    CurrentActiveStatus := LSqueezyToken.AsValue().AsBoolean();
                end;
            LSqueezyJson.Get('deactivated', LSqueezyToken):
                begin
                    SqueezyResponseType := SqueezyResponseType::Deactivation;
                    // We flip. If deactivated is true, then it's not active.
                    CurrentActiveStatus := not LSqueezyToken.AsValue().AsBoolean();
                end;
        end;
        if SqueezyResponseType = SqueezyResponseType::" " then
            Error(CommunicationFailureErr, AppInfo.Publisher());

        TempJsonBuffer.ReadFromText(ResponseBody);

        // Update the current Subscription record
        SPBExtensionLicense.Validate(Activated, CurrentActiveStatus);
        TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'created_at', 'license_key');
        Evaluate(SPBExtensionLicense."Created At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'expires_at', 'license_key');
        Evaluate(SPBExtensionLicense."Subscription Ended At", TempPlaceholder);

        // Parse activation_limit from the JSON response if present
        Clear(TempPlaceholder);
        if TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'activation_limit', 'license_key') then begin
            if TempPlaceholder <> '' then
                Evaluate(SPBExtensionLicense."Activation Limit", TempPlaceholder);
        end;

        // TODO: Pending Request to Lemon Squeezy team to add this to their API
        //TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'email', 'license_key');
        //SPBExtensionLicense."Subscription Email" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."Subscription Email"));
        SPBExtensionLicense.CalculateEndDate();

        // Lemon Squeezy relies on having storage of the "instance ID" to verify an instance is still active
        if SqueezyResponseType = SqueezyResponseType::Activation then begin
            TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'id', '*instance*');
            SPBExtensionLicense."Licensing ID" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."Licensing ID"));
            InstanceInfo.Add('id', TempPlaceholder);
            TempJsonBuffer.GetPropertyValueAtPath(TempPlaceholder, 'name', '*instance*');
            InstanceInfo.Add('name', TempPlaceholder);

            InstanceInfo.WriteTo(TempPlaceholder); //TODO: What is this for? Should this be stored in IsoStorage?
            SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'licensingId', SPBExtensionLicense."Licensing ID");
        end;
        PopulateSubscriptionItemIdFromAPI(SPBExtensionLicense, ResponseBody);
    end;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    begin
        // LemonSqueezy allows self-unregistration of an instance of a license 
        exit(true);
    end;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
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

    procedure PopulateSubscriptionItemIdFromAPI(var SPBExtensionLicense: Record "SPBLIC Extension License"; var ResponseBody: Text): Integer
    var
        JObject: JsonObject;
        Meta, TempToken : JsonToken;
        SubscriptionApi: Text;
    begin
        if not SPBExtensionLicense.IsUsageBased then
            exit;

        // Implementation for populating Subscription ID from API response
        JObject.ReadFrom(ResponseBody);
        if JObject.Contains('meta') then begin
            JObject.Get('meta', Meta);
            // Extract order_id, order_item_id and product_id from the meta object
            if Meta.AsObject().Contains('order_id') then
                if Meta.AsObject().Get('order_id', TempToken) then
                    SPBExtensionLicense."Order Id" := TempToken.AsValue().AsInteger();
            if Meta.AsObject().Contains('order_item_id') then
                if Meta.AsObject().Get('order_item_id', TempToken) then
                    SPBExtensionLicense."Order Item Id" := TempToken.AsValue().AsInteger();
            if Meta.AsObject().Contains('product_id') then
                if Meta.AsObject().Get('product_id', TempToken) then
                    SPBExtensionLicense."Product Id" := TempToken.AsValue().AsInteger();
        end;

        SubscriptionApi := StrSubstNo(LemonSqueezySubscriptionsUrlTok, SPBExtensionLicense."Store Id", SPBExtensionLicense."Order Id", SPBExtensionLicense."Order Item Id", SPBExtensionLicense."Product Id");
        Clear(ResponseBody);
        Clear(TempToken);
        Clear(JObject);

        CallLemonSqueezy(ResponseBody, 'GET', SubscriptionApi, SPBExtensionLicense.ApiKeyProvider);
        JObject.ReadFrom(ResponseBody);
        JObject.SelectToken('$.data[0].attributes.first_subscription_item.id', TempToken);
        SPBExtensionLicense."Subscription Item Id" := TempToken.AsValue().AsInteger();

        // Check if subscription is actually usage-based according to LemonSqueezy
        if JObject.SelectToken('$.data[0].attributes.first_subscription_item.is_usage_based', TempToken) then
            SPBExtensionLicense."IsUsageBased" := TempToken.AsValue().AsBoolean();

        // Only populate aggregation settings if this is actually a usage-based subscription
        if SPBExtensionLicense."IsUsageBased" then
            PopulateAggregationSettings(SPBExtensionLicense, JObject);
        SPBExtensionLicense."Last Metadata Refresh" := CurrentDateTime();
    end;

    procedure LogUsageIncrement(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer): Boolean
    var
        ResponseBody: Text;
    begin
        // Check if license is usage-based and subscription item ID is set
        ValidateUsageBasedLicense(SPBExtensionLicense);
        // Validate aggregation settings before usage tracking
        ValidateAggregationForUsage(SPBExtensionLicense);
        // crosscheck that the record's license_id matches the IsoStorage one for possible tamper checking
        ValidateLicenseIdInfo(SPBExtensionLicense);

        // When verifying the License, we have to pass the instance info that we stored on the record
        exit(CallLemonSqueezy(ResponseBody, LemonSqueezyUsageRecordUrlTok, SPBExtensionLicense.ApiKeyProvider, BuildUsageContent(SPBExtensionLicense, 1)));
    end;

    procedure LogUsageSet(var SPBExtensionLicense: Record "SPBLIC Extension License"; UsageCount: Integer): Boolean
    var
        ResponseBody: Text;
    begin
        // Skip API call for zero usage as LemonSqueezy rejects it with 422
        if UsageCount = 0 then
            exit(true);

        // Check if license is usage-based and subscription item ID is set
        ValidateUsageBasedLicense(SPBExtensionLicense);
        // Validate aggregation settings before usage tracking
        ValidateAggregationForUsage(SPBExtensionLicense);
        // crosscheck that the record's license_id matches the IsoStorage one for possible tamper checking
        ValidateLicenseIdInfo(SPBExtensionLicense);

        // When verifying the License, we have to pass the instance info that we stored on the record
        exit(CallLemonSqueezy(ResponseBody, LemonSqueezyUsageRecordUrlTok, SPBExtensionLicense.ApiKeyProvider, BuildUsageContent(SPBExtensionLicense, UsageCount, 'set')));
    end;

    local procedure ValidateUsageBasedLicense(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        LicenseNotUsageBasedErr: Label 'The License %1/%2 is not usage-based and cannot be used for usage tracking.', Comment = '%1 = the Extension Name, %2 = the Submodule Name';
        SubscriptionItemIdMissingErr: Label 'Seems like the Subscription Item ID is missing for License %1/%2. This usually means that the License was not activated yet.', Comment = '%1 = the Extension Name, %2 = the Submodule Name';
        AutoRefreshFailedErr: Label 'Unable to automatically refresh subscription configuration for License %1/%2. The subscription may not be usage-based or there may be connectivity issues.', Comment = '%1 = the Extension Name, %2 = the Submodule Name';
    begin
        // If the license thinks it's usage-based but has no subscription item ID, try to refresh metadata first
        if SPBExtensionLicense."IsUsageBased" and (SPBExtensionLicense."Subscription Item Id" = 0) then
            if not RefreshSubscriptionMetadata(SPBExtensionLicense) then
                Error(AutoRefreshFailedErr, SPBExtensionLicense."Extension Name", SPBExtensionLicense."Submodule Name");

        if not SPBExtensionLicense."IsUsageBased" then
            Error(LicenseNotUsageBasedErr, SPBExtensionLicense."Extension Name", SPBExtensionLicense."Submodule Name");

        if SPBExtensionLicense."Subscription Item Id" = 0 then
            Error(SubscriptionItemIdMissingErr, SPBExtensionLicense."Extension Name", SPBExtensionLicense."Submodule Name");
    end;

    local procedure BuildUsageContent(var SPBExtensionLicense: Record "SPBLIC Extension License"; Quantity: Integer): JsonObject
    begin
        exit(BuildUsageContent(SPBExtensionLicense, Quantity, 'increment'));
    end;
    /// <summary>
    /// Builds the JSON content for usage tracking.
    /// </summary>
    /// <param name="SPBExtensionLicense">The License to use</param>
    /// <param name="Quantity">The quantity to track</param>
    /// <param name="Action">The action being performed, can be either "increment" or "set"</param>
    /// <returns></returns>
    local procedure BuildUsageContent(var SPBExtensionLicense: Record "SPBLIC Extension License"; Quantity: Integer; Action: Text) Result: JsonObject
    var
        Attributes, Data, Relationships, SubscriptionItem, SubscriptionItemData : JsonObject;
        InvalidActionErr: Label 'Invalid action specified. Use "increment" or "set".';
    begin
        Data.Add('type', 'usage-records');
        Attributes.Add('quantity', Quantity);
        case true of
            Action = 'increment', Action = '':
                Attributes.Add('action', 'increment');
            Action = 'set':
                Attributes.Add('action', 'set');
            else
                Error(InvalidActionErr);
        end;
        Data.Add('attributes', Attributes);
        SubscriptionItemData.Add('type', 'subscription-items');
        SubscriptionItemData.Add('id', Format(SPBExtensionLicense."Subscription Item Id"));
        SubscriptionItem.Add('data', SubscriptionItemData);
        Relationships.Add('subscription-item', SubscriptionItem);
        Data.Add('relationships', Relationships);
        Result.Add('data', Data);
    end;

    internal procedure ValidateProductMatch(var SPBExtensionLicense: Record "SPBLIC Extension License"; ResponseBody: Text)
    var
        JObject: JsonObject;
        Meta, ProductIdToken : JsonToken;
        FailedJsonParsingErr: Label 'Failed to parse license validation response from licensing platform.';
        MissingMetaErr: Label 'The license validation response does not contain the expected product information.';
        ProductMismatchErr: Label 'License key does not belong to the expected product. Expected product code %1, but license is for a different product.', Comment = '%1 is the expected Product Code';
        ProductIdFromAPI: Text;
    begin
        // Parse the response to extract product information from meta object
        if not JObject.ReadFrom(ResponseBody) then
            Error(FailedJsonParsingErr);

        // Get the meta object which contains product validation information
        if not JObject.Get('meta', Meta) then
            Error(MissingMetaErr);

        // Extract product_id from meta object
        if Meta.AsObject().Get('product_id', ProductIdToken) then begin
            ProductIdFromAPI := ProductIdToken.AsValue().AsText();

            // Compare with the registered Product Code
            // LemonSqueezy product_id should match the Product Code registered for this extension
            if (SPBExtensionLicense."Product Code" <> '') and
               (SPBExtensionLicense."Product Code" <> ProductIdFromAPI) then
                Error(ProductMismatchErr, SPBExtensionLicense."Product Code");
        end;
    end;

    local procedure PopulateAggregationSettings(var SPBExtensionLicense: Record "SPBLIC Extension License"; JObject: JsonObject)
    var
        PriceId: Integer;
        PriceObject: JsonObject;
        TempToken: JsonToken;
        PriceApi: Text;
        ResponseBody: Text;
        RenewalUnit: Text;
        RenewalQuantity: Integer;
        BillingFrequency: Text;
    begin
        // Get price_id from subscription item to fetch both usage aggregation and billing frequency
        if JObject.SelectToken('$.data[0].attributes.first_subscription_item.price_id', TempToken) then begin
            PriceId := TempToken.AsValue().AsInteger();

            // Fetch Price object to get usage_aggregation and renewal interval
            PriceApi := StrSubstNo(LemonSqueezyPriceUrlTok, PriceId);
            Clear(ResponseBody);

            if CallLemonSqueezy(ResponseBody, 'GET', PriceApi, SPBExtensionLicense.ApiKeyProvider) then begin
                PriceObject.ReadFrom(ResponseBody);
                
                // Get usage aggregation
                if PriceObject.SelectToken('$.data.attributes.usage_aggregation', TempToken) then
                    if not TempToken.AsValue().IsNull() then
                        SPBExtensionLicense."Usage Aggregation Type" := CopyStr(TempToken.AsValue().AsText(), 1, MaxStrLen(SPBExtensionLicense."Usage Aggregation Type"));

                // Get billing frequency from renewal interval
                if PriceObject.SelectToken('$.data.attributes.renewal_interval_unit', TempToken) then
                    RenewalUnit := TempToken.AsValue().AsText();
                    
                if PriceObject.SelectToken('$.data.attributes.renewal_interval_quantity', TempToken) then
                    RenewalQuantity := TempToken.AsValue().AsInteger();

                // Build meaningful billing frequency description
                BillingFrequency := BuildBillingFrequencyText(RenewalUnit, RenewalQuantity);
                SPBExtensionLicense."Billing Frequency" := CopyStr(BillingFrequency, 1, MaxStrLen(SPBExtensionLicense."Billing Frequency"));
            end;
        end;
    end;

    local procedure ValidateAggregationForUsage(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        MetadataAge: Duration;
        MetadataRefreshFailedErr: Label 'Unable to refresh license configuration automatically. This may occur if your subscription is no longer active or network connectivity issues exist. Please verify your subscription status or contact support if the issue persists.';
    begin
        // Check if metadata was never refreshed first (avoids calculation issues)
        if SPBExtensionLicense."Last Metadata Refresh" = 0DT then begin
            if not RefreshSubscriptionMetadata(SPBExtensionLicense) then
                Error(MetadataRefreshFailedErr);
        end else begin
            // Only calculate age if we have a valid timestamp
            MetadataAge := CurrentDateTime() - SPBExtensionLicense."Last Metadata Refresh";
            if MetadataAge > 86400000 then // 24 hours in milliseconds
                if not RefreshSubscriptionMetadata(SPBExtensionLicense) then
                    Error(MetadataRefreshFailedErr);
        end;
    end;

    local procedure RefreshSubscriptionMetadata(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    var
        JObject: JsonObject;
        TempToken: JsonToken;
        ResponseBody: Text;
        SubscriptionApi: Text;
    begin
        // Use existing subscription data to refresh metadata without consuming license activations
        if (SPBExtensionLicense."Store Id" = 0) or (SPBExtensionLicense."Order Id" = 0) or
           (SPBExtensionLicense."Order Item Id" = 0) or (SPBExtensionLicense."Product Id" = 0) then
            exit(false); // Cannot refresh without basic subscription identifiers

        // Build API call using existing subscription identifiers
        SubscriptionApi := StrSubstNo(LemonSqueezySubscriptionsUrlTok,
            SPBExtensionLicense."Store Id",
            SPBExtensionLicense."Order Id",
            SPBExtensionLicense."Order Item Id",
            SPBExtensionLicense."Product Id");

        Clear(ResponseBody);

        // Attempt to fetch current subscription data (no license activation consumed)
        if not CallLemonSqueezy(ResponseBody, 'GET', SubscriptionApi, SPBExtensionLicense.ApiKeyProvider) then
            exit(false); // API call failed - return false to trigger error



        if not JObject.ReadFrom(ResponseBody) then
            exit(false); // JSON parsing failed

        // Verify subscription is still active before updating metadata

        if JObject.SelectToken('$.data[0].attributes.status', TempToken) then
            if TempToken.AsValue().AsText() <> 'active' then
                exit(false); // Don't update metadata if subscription is not active

        // Update subscription item ID with current value from LemonSqueezy
        if JObject.SelectToken('$.data[0].attributes.first_subscription_item.id', TempToken) then
            SPBExtensionLicense."Subscription Item Id" := TempToken.AsValue().AsInteger();

        // Check if subscription is actually usage-based according to LemonSqueezy
        if JObject.SelectToken('$.data[0].attributes.first_subscription_item.is_usage_based', TempToken) then
            SPBExtensionLicense."IsUsageBased" := TempToken.AsValue().AsBoolean();

        // Only refresh aggregation settings if this is actually a usage-based subscription
        if SPBExtensionLicense."IsUsageBased" then
            PopulateAggregationSettings(SPBExtensionLicense, JObject);
        SPBExtensionLicense."Last Metadata Refresh" := CurrentDateTime();
        SPBExtensionLicense.Modify();

        exit(true); // Refresh successful
    end;

    /// <summary>
    /// Manually refresh subscription metadata without consuming license activations.
    /// This is useful when LemonSqueezy configuration has changed (e.g., aggregation settings).
    /// </summary>
    /// <param name="SPBExtensionLicense">The license record to refresh</param>
    /// <returns>True if refresh was successful, false otherwise</returns>
    procedure RefreshMetadata(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    begin
        exit(RefreshSubscriptionMetadata(SPBExtensionLicense));
    end;

    local procedure BuildBillingFrequencyText(RenewalUnit: Text; RenewalQuantity: Integer): Text
    var
        FrequencyText: Text;
    begin
        if (RenewalUnit = '') or (RenewalQuantity = 0) then
            exit('Unknown');

        // Handle singular vs plural and build meaningful description
        case RenewalUnit of
            'day':
                if RenewalQuantity = 1 then
                    FrequencyText := 'Daily'
                else
                    FrequencyText := StrSubstNo('Every %1 days', RenewalQuantity);
            'week':
                if RenewalQuantity = 1 then
                    FrequencyText := 'Weekly'
                else
                    FrequencyText := StrSubstNo('Every %1 weeks', RenewalQuantity);
            'month':
                if RenewalQuantity = 1 then
                    FrequencyText := 'Monthly'
                else
                    FrequencyText := StrSubstNo('Every %1 months', RenewalQuantity);
            'year':
                if RenewalQuantity = 1 then
                    FrequencyText := 'Yearly'
                else
                    FrequencyText := StrSubstNo('Every %1 years', RenewalQuantity);
            else
                FrequencyText := StrSubstNo('%1 %2', RenewalQuantity, RenewalUnit);
        end;

        exit(FrequencyText);
    end;

    procedure GetActivationLimit(LicenseKey: Text): Integer
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        ResponseBody: Text;
        LicenseNotFoundErr: Label 'License key "%1" not found in the system.', Comment = '%1 is the license key';
    begin
        // Validate input parameter
        if LicenseKey = '' then
            exit(0);

        // Find the license record by license key
        SPBExtensionLicense.SetRange("License Key", LicenseKey);
        if not SPBExtensionLicense.FindFirst() then begin
            // License key not found, return 0
            exit(0);
        end;

        // Return stored activation limit if available and valid
        if SPBExtensionLicense."Activation Limit" > 0 then
            exit(SPBExtensionLicense."Activation Limit");
        
        // If not stored locally, try to get from fresh API call
        if CallAPIForActivation(SPBExtensionLicense, ResponseBody) then begin
            PopulateSubscriptionFromResponse(SPBExtensionLicense, ResponseBody);
            if SPBExtensionLicense.Modify() then begin
                // Return the newly retrieved activation limit if it's valid
                if SPBExtensionLicense."Activation Limit" > 0 then
                    exit(SPBExtensionLicense."Activation Limit");
            end;
        end;
        
        // Return 0 if unable to retrieve activation limit or if the API doesn't provide this information
        exit(0);
    end;
}
