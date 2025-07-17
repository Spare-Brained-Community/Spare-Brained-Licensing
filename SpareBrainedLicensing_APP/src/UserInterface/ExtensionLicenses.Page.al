namespace SPB.UserInterface;

using SPB.EngineLogic;
using SPB.Extensibility;
using SPB.Storage;

page 71033575 "SPBLIC Extension Licenses"
{
    ApplicationArea = All;
    Caption = 'Extension Licenses';
    Editable = false;
    Extensible = true;
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
                    Visible = false;
                }
                field("Extension App Id"; Rec."Extension App Id")
                {
                    Visible = false;
                }
                field("Extension Name"; Rec."Extension Name")
                {
                    StyleExpr = SubscriptionStatusStyle;
                }
                field("Submodule Name"; Rec."Submodule Name")
                {
                }
                field(Activated; Rec.Activated)
                {
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
                }
                field("Subscription Email"; Rec."Subscription Email")
                {
                    ExtendedDatatype = EMail;
                }
                field("Product URL"; Rec."Product URL")
                {
                    ExtendedDatatype = URL;
                }
                field("Support URL"; Rec."Support URL")
                {
                    ExtendedDatatype = URL;
                }
                field("Billing Support Email"; Rec."Billing Support Email")
                {
                    ExtendedDatatype = EMail;
                }
                field("License Platform"; Rec."License Platform")
                {
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
        UserHasWritePermission := Rec.WritePermission();

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
        SubscriptionStatusStyle := Format(PageStyle::Standard);
        if Rec.Activated then begin
            if (Rec."Subscription End Date" = 0DT) then
                SubscriptionStatusStyle := Format(PageStyle::Favorable)
            else
                if (Rec."Subscription End Date" > CurrentDateTime()) then
                    SubscriptionStatusStyle := Format(PageStyle::Attention);
        end else
            if (Rec."Trial Grace End Date" <> 0D) then
                if (Rec."Trial Grace End Date" < Today()) then
                    SubscriptionStatusStyle := Format(PageStyle::StandardAccent)
                else
                    SubscriptionStatusStyle := Format(PageStyle::Ambiguous)
            else
                SubscriptionStatusStyle := Format(PageStyle::Unfavorable);
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
        LicensePlatform: Interface "SPBLIC ILicenseCommunicator2";
        DeactivationNotPossibleWarningQst: Label 'This will deactivate this license in this Business Central instance, but you will need to contact the Publisher to release the assigned license. \ \Are you sure you want to deactivate this license?';
        DeactivationPossibleQst: Label 'This will deactivate this license in this Business Central instance.\ \Are you sure you want to deactivate this license?';
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";

        // Depending on the platform capabilities, we give the user a different message
        if LicensePlatform.ClientSideDeactivationPossible(SPBExtensionLicense) then
            DoDeactivation := Confirm(DeactivationPossibleQst, false)
        else
            DoDeactivation := Confirm(DeactivationNotPossibleWarningQst, false);

        if DoDeactivation then
            exit(SPBLICDeactivateMeth.Deactivate(SPBExtensionLicense, false));
    end;
}