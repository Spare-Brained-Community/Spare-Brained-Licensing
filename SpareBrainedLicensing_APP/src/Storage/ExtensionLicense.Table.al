table 71033575 "SPBLIC Extension License"
{
    Caption = 'Extension License';
    DataClassification = AccountData;
    DataPerCompany = false;
    DrillDownPageId = "SPBLIC Extension Licenses";
    LookupPageId = "SPBLIC Extension Licenses";

    fields
    {
        field(1; "Entry Id"; Guid)
        {
            Caption = 'Entry Id';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'This Guid is the Subscription Entry Id.';
        }
        field(2; "Extension Name"; Text[100])
        {
            Caption = 'Extension Name';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'The name of the Extension that is registered to have a Subscription requirement.';
        }
        field(3; "Product Code"; Text[100])
        {
            Caption = 'Product Code';
            Editable = false;
        }
        field(4; Activated; Boolean)
        {
            Caption = 'Activated';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Shows if this Extension has been Activated with a Product Key.';
            trigger OnValidate()
            begin
                if Activated then begin
                    "Activated At" := CurrentDateTime();
                    "Activated By" := UserSecurityId();
                    "Trial Grace End Date" := 0D;
                end;
            end;
        }
        field(5; "Installed At"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Installed At';
            Editable = false;
        }
        field(6; "Activated At"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Activated At';
            Editable = false;
        }
        field(7; "License Key"; Text[50])
        {
            AllowInCustomizations = Always;
            Caption = 'License Key';
            DataClassification = CustomerContent;
            Editable = false;
            ExtendedDatatype = Masked;
        }
        field(8; "Activated By"; Guid)
        {
            AllowInCustomizations = Always;
            Caption = 'Activated By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Subscription End Date"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Subscription End Date';
            Editable = false;
        }
        field(10; "Created At"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Created At';
            Editable = false;
        }
        field(11; "Subscription Ended At"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Subscription Ended At';
            Editable = false;
        }
        field(12; "Subscription Cancelled At"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Subscription Cancelled At';
            Editable = false;
        }
        field(13; "Subscription Failed At"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Subscription Failed At';
            Editable = false;
        }
        field(14; "Trial Grace End Date"; Date)
        {
            Caption = 'Trial Grace End Date';
            Editable = false;
            ToolTip = 'If the Extension is not yet Activated, this is the last date the Extension can run in Trial Mode.';
        }
        field(15; "Sandbox Grace Days"; Integer)
        {
            AllowInCustomizations = Always;
            Caption = 'Sandbox Grace Days';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(19; "Extension App Id"; Guid)
        {
            Caption = 'Extension App Id';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'This Guid is the Extension''s App Id.';
        }
        field(20; "Subscription Email"; Text[250])
        {
            Caption = 'Subscription Email';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ToolTip = 'This shows the email address that the License Key is registered to, in case there is a need to find it later.';
        }
        field(21; "Product URL"; Text[250])
        {
            Caption = 'Product URL';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = URL;
            ToolTip = 'The page where one can find more information about purchasing a Subscription for this Extension.';
        }
        field(22; "Support URL"; Text[250])
        {
            Caption = 'Support URL';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = URL;
            ToolTip = 'The page where one can find more information about how to get Support for the Extension.';
        }
        field(23; "Billing Support Email"; Text[250])
        {
            Caption = 'Billing Support Email';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = EMail;
            ToolTip = 'The email address to contact with Billing related questions about this Subscription.';
        }
        field(25; "Version Check URL"; Text[250])
        {
            AllowInCustomizations = Always;
            Caption = 'Version Check URL';
            DataClassification = SystemMetadata;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(26; "Update Available"; Boolean)
        {
            AllowInCustomizations = Always;
            Caption = 'Update Available';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(27; "Update News URL"; Text[250])
        {
            AllowInCustomizations = Always;
            Caption = 'Update News URL';
            DataClassification = SystemMetadata;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(28; "Submodule Name"; Text[100])
        {
            Caption = 'Submodule Name';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'If this Extension uses Module based Subscriptions, this displays which Submodule/Edition this is.';
        }
        field(30; "License Platform"; Enum "SPBLIC License Platform")
        {
            Caption = 'License Platform';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the value of the License Platform field.';
        }
        field(40; "Licensing ID"; Text[250])
        {
            AllowInCustomizations = Always;
            // This is for generic storage of 3rd party system ID fields in case needed
            Caption = 'Licensing ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Entry Id")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid("Extension App Id") then
            "Extension App Id" := "Entry Id";
    end;

    internal procedure CalculateEndDate()
    var
    begin
        // Whichever date is lowest is our actual 'end' date. Weird API
        if (Rec."Subscription Cancelled At" <> 0DT) or
          (Rec."Subscription Ended At" <> 0DT) or
          (Rec."Subscription Failed At" <> 0DT) and
          (Rec."Subscription End Date" = 0DT)
        then begin
            if Rec."Subscription Ended At" <> 0DT then
                Rec."Subscription End Date" := Rec."Subscription Ended At";
            if Rec."Subscription Failed At" <> 0DT then
                if (Rec."Subscription End Date" = 0DT) or (Rec."Subscription Failed At" < Rec."Subscription End Date") then
                    Rec."Subscription End Date" := Rec."Subscription Failed At";
            if Rec."Subscription Cancelled At" <> 0DT then
                if (Rec."Subscription End Date" = 0DT) or (Rec."Subscription Cancelled At" < Rec."Subscription End Date") then
                    Rec."Subscription End Date" := Rec."Subscription Cancelled At";
        end;
    end;

    internal procedure IsTestSubscription(): Boolean
    var
        SPBLicenseUtilities: Codeunit "SPBLIC License Utilities";
    begin
        exit(Rec."Extension App Id" = SPBLicenseUtilities.GetTestProductAppId());
    end;

    internal procedure LaunchProductUrl()
    var
        SBPLicEvents: Codeunit "SPBLIC Events";
        IsHandled: Boolean;
    begin
        SBPLicEvents.OnBeforeLaunchProductUrl(Rec, IsHandled);
        if not IsHandled then
            Hyperlink("Product URL");
    end;
}
