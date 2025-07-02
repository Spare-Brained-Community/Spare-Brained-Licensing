page 71033575 "SPBLIC Extension Licenses"
{

    ApplicationArea = All;
    Caption = 'Extension Licenses';
    Editable = false;
    PageType = List;
    SourceTable = "SPBLIC Extension License";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry Id"; Rec."Entry Id")
                {
                    ToolTip = 'This Guid is the Subscription Entry Id.';
                    Visible = false;
                }
                field("Extension App Id"; Rec."Extension App Id")
                {
                    ToolTip = 'This Guid is the Extension''s App Id.';
                    Visible = false;
                }
                field("Extension Name"; Rec."Extension Name")
                {
                    StyleExpr = SubscriptionStatusStyle;
                    ToolTip = 'The name of the Extension that is registered to have a Subscription requirement.';
                }
                field("Submodule Name"; Rec."Submodule Name")
                {
                    ToolTip = 'If this Extension uses Module based Subscriptions, this displays which Submodule/Edition this is.';
                }
                field(Activated; Rec.Activated)
                {
                    ToolTip = 'Shows if this Extension has been Activated with a Product Key.';
                }
                field(UpdateLink; UpdateLink)
                {
                    Caption = 'Update News';
                    DrillDown = true;
                    Style = Favorable;
                    ToolTip = 'If an Update is available, this will link to where to find out more.';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(Rec."Update News URL");
                    end;
                }
                field("Trial Grace End Date"; Rec."Trial Grace End Date")
                {
                    ToolTip = 'If the Extension is not yet Activated, this is the last date the Extension can run in Trial Mode.';
                }
                field("Subscription Email"; Rec."Subscription Email")
                {
                    ExtendedDatatype = EMail;
                    ToolTip = 'This shows the email address that the License Key is registered to, in case there is a need to find it later.';
                }
                field("Product URL"; Rec."Product URL")
                {
                    ExtendedDatatype = URL;
                    ToolTip = 'The page where one can find more information about purchasing a Subscription for this Extension.';
                }
                field("Support URL"; Rec."Support URL")
                {
                    ExtendedDatatype = URL;
                    ToolTip = 'The page where one can find more information about how to get Support for the Extension.';
                }
                field("Billing Support Email"; Rec."Billing Support Email")
                {
                    ExtendedDatatype = EMail;
                    ToolTip = 'The email address to contact with Billing related questions about this Subscription.';
                }
                field("License Platform"; Rec."License Platform")
                {
                    ToolTip = 'Specifies the value of the License Platform field.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActivateProduct)
            {
                Caption = 'Activate';
                Enabled = not Rec.Activated and UserHasWritePermission;
                Image = SuggestElectronicDocument;
                ToolTip = 'Launches the Activation Wizard for this Subscription.';

                trigger OnAction()
                begin
                    LaunchActivation(Rec);
                    Rec.SetRange("Entry Id");
                end;
            }
            action(DeactivateProduct)
            {
                Caption = 'Deactivate';
                Enabled = Rec.Activated and UserHasWritePermission;
                Image = Cancel;
                ToolTip = 'Forces this Subscription inactive, which will allow entry of a new License Key.';

                trigger OnAction()
                begin
                    DeactivateExtension(Rec);
                    Rec.SetRange("Entry Id");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ActivateProduct_Promoted; ActivateProduct)
                {
                }
                actionref(DeactivateProduct_Promoted; DeactivateProduct)
                {
                }
            }
        }
    }

    var
        UserHasWritePermission: Boolean;
        UpdateAvailableTok: Label 'Available';
        SubscriptionStatusStyle: Text;
        UpdateLink: Text;

    trigger OnOpenPage()
    begin
        // necessary since Enabled can't be bound to procedures.
        UserHasWritePermission := Rec.WritePermission;

        if UserHasWritePermission then
            CheckAllForUpdates();
    end;

    trigger OnAfterGetRecord()
    begin
        SetSubscriptionStyle();

        if Rec."Update Available" and (Rec."Update News URL" <> '') then
            UpdateLink := UpdateAvailableTok
        else
            UpdateLink := '';
    end;

    local procedure SetSubscriptionStyle()
    begin
        SubscriptionStatusStyle := 'Standard';
        if Rec.Activated then begin
            if (Rec."Subscription End Date" = 0DT) then
                SubscriptionStatusStyle := 'Favorable'
            else
                if (Rec."Subscription End Date" > CurrentDateTime) then
                    SubscriptionStatusStyle := 'Attention';
        end else
            if (Rec."Trial Grace End Date" <> 0D) then
                if (Rec."Trial Grace End Date" < Today) then
                    SubscriptionStatusStyle := 'StandardAccent'
                else
                    SubscriptionStatusStyle := 'Ambiguous'
            else
                SubscriptionStatusStyle := 'Unfavorable';
    end;

    local procedure CheckAllForUpdates()
    var
        SPBLicense: Record "SPBLIC Extension License";
        SPBLICVersionCheck: Codeunit "SPBLIC Version Check";
    begin
        if SPBLicense.FindSet(true) then
            repeat
                if SPBLicense."Update News URL" <> '' then
                    SPBLICVersionCheck.DoVersionCheck(SPBLicense);
            until SPBLicense.Next() = 0;
    end;

    internal procedure LaunchActivation(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        SPBLicenseActivationWizard: Page "SPBLIC License Activation";
    begin
        Clear(SPBLicenseActivationWizard);
        SPBExtensionLicense.SetRecFilter();
        SPBLicenseActivationWizard.SetTableView(SPBExtensionLicense);
        SPBLicenseActivationWizard.RunModal();
    end;

    internal procedure DeactivateExtension(var SPBExtensionLicense: Record "SPBLIC Extension License"): Boolean
    var
        SPBLICDeactivateMeth: Codeunit "SPBLIC Deactivate Meth";
        DoDeactivation: Boolean;
        LicenseActivation: Interface "SPBLIC IActivation";
        DeactivationNotPossibleWarningQst: Label 'This will deactivate this license in this Business Central instance, but you will need to contact the Publisher to release the assigned license. \ \Are you sure you want to deactivate this license?';
        DeactivationPossibleQst: Label 'This will deactivate this license in this Business Central instance.\ \Are you sure you want to deactivate this license?';
    begin
        LicenseActivation := SPBExtensionLicense."License Platform";

        // Depending on the platform capabilities, we give the user a different message
        if LicenseActivation.ClientSideDeactivationPossible(SPBExtensionLicense) then
            DoDeactivation := Confirm(DeactivationPossibleQst, false)
        else
            DoDeactivation := Confirm(DeactivationNotPossibleWarningQst, false);

        if DoDeactivation then
            exit(SPBLICDeactivateMeth.Deactivate(SPBExtensionLicense, false));
    end;
}