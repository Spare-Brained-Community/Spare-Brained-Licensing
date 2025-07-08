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
        }
        field(2; "Extension Name"; Text[100])
        {
            Caption = 'Extension Name';
            DataClassification = SystemMetadata;
            Editable = false;
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
            ObsoleteReason = 'Migrated to the License State field Enum.';
            ObsoleteState = Pending;

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
            Caption = 'Installed At';
            Editable = false;
        }
        field(6; "Activated At"; DateTime)
        {
            Caption = 'Activated At';
            Editable = false;
        }
        field(7; "License Key"; Text[50])
        {
            Caption = 'License Key';
            DataClassification = CustomerContent;
            Editable = false;
            ExtendedDatatype = Masked;
        }
        field(8; "Activated By"; Guid)
        {
            Caption = 'Activated By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Subscription End Date"; DateTime)
        {
            Caption = 'Subscription End Date';
            Editable = false;
        }
        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
        }
        field(11; "Subscription Ended At"; DateTime)
        {
            Caption = 'Subscription Ended At';
            Editable = false;
        }
        field(12; "Subscription Cancelled At"; DateTime)
        {
            Caption = 'Subscription Cancelled At';
            Editable = false;
        }
        field(13; "Subscription Failed At"; DateTime)
        {
            Caption = 'Subscription Failed At';

        }
        field(14; "Trial Grace End Date"; Date)
        {
            Caption = 'Trial Grace End Date';
            Editable = false;
        }
        field(15; "Sandbox Grace Days"; Integer)
        {
            Caption = 'Sandbox Grace Days';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(19; "Extension App Id"; Guid)
        {
            Caption = 'Extension App Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Subscription Email"; Text[250])
        {
            Caption = 'Subscription Email';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
        }
        field(21; "Product URL"; Text[250])
        {
            Caption = 'Product URL';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(22; "Support URL"; Text[250])
        {
            Caption = 'Support URL';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(23; "Billing Support Email"; Text[250])
        {
            Caption = 'Billing Support Email';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = EMail;
        }
        field(25; "Version Check URL"; Text[250])
        {
            Caption = 'Version Check URL';
            DataClassification = SystemMetadata;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(26; "Update Available"; Boolean)
        {
            Caption = 'Update Available';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(27; "Update News URL"; Text[250])
        {
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
        }
        field(30; "License Platform"; Enum "SPBLIC License Platform")
        {
            Caption = 'License Platform';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(40; "Licensing ID"; Text[250])
        {
            // This is for generic storage of 3rd party system ID fields in case needed
            Caption = 'Licensing ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "Licensing Mode"; Enum "SPBLIC Licensing Mode")
        {
            Caption = 'Licensing Mode';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(51; "Licensing Scope"; Enum "SPBLIC Licensing Scope")
        {
            Caption = 'Licensing Scope';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(52; "Tenant Id"; Guid)
        {
            Caption = 'Tenant Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(53; "Company Id"; Guid)
        {
            Caption = 'Company Id';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Company.SystemId;
        }
        field(54; "User Id"; Guid)
        {
            Caption = 'User Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60; "License State"; Enum "SPBLIC License State")
        {
            Caption = 'License State';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            begin
                if "License State" = "License State"::Active then begin
                    "Activated At" := CurrentDateTime();
                    "Activated By" := UserSecurityId();
                    "Trial Grace End Date" := 0D;
                end;
            end;
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

    internal procedure IsActive(): Boolean
    begin
        case "License State" of
            "License State"::Active, "License State"::Trial:
                exit(true);
            else
                exit(false);
        end;
    end;
}
