page 71033576 "SPBLIC License Activation"
{

    ApplicationArea = All;
    Caption = 'Licensing Activation Wizard';
    PageType = NavigatePage;
    SourceTable = "SPBLIC Extension License";

    layout
    {
        area(Content)
        {
            group(Step1)
            {
                Visible = Step1Visible;
                group(WelcomeText)
                {
                    Caption = 'This is the Activation Wizard for the Licensing system.';
                    group(WelcomeExplainer)
                    {
                        InstructionalText = 'You will enter the License Key for the following License.  If you do not have a License key, please click on the "Get License Key" link.';
                        ShowCaption = false;
                    }
                    field(LicenseLinkField; LicenseLinkText)
                    {
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Rec.LaunchProductUrl();
                        end;
                    }
                }
                group(LetsStart)
                {
                    Caption = 'Start Activation';
                    group(StartText)
                    {
                        InstructionalText = 'Click Next to begin the activation process. You will need your Subscription License key.';
                        ShowCaption = false;
                    }
                }
            }
            group(Step2)
            {
                Visible = Step2Visible;

                group(LicenseKeyInstruction)
                {
                    InstructionalText = 'Please enter your Subscription License Key:';
                    ShowCaption = false;
                }
                field(LicenseKeyField; LicenseKey)
                {
                    ShowCaption = false;
                    ShowMandatory = true;
                }
                field(LicenseKeyFormat; LicenseFormatHintText)
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step2Test)
            {
                Visible = Step2TestVisible;

                group(TestPathLicenseKeyInstruction)
                {
                    InstructionalText = 'Please enter your Subscription License Key:';
                    ShowCaption = false;
                }
                field(TestPathLicenseKeyField; LicenseKey)
                {
                    ShowCaption = false;
                    ShowMandatory = true;
                }
                field(TestPathLicenseKeyFormat; LicenseFormatHintText)
                {
                    Editable = false;
                    ShowCaption = false;
                }
                group(TestLicenseOption)
                {
                    InstructionalText = 'This is the Test Subscription, so you can use a test License Key here by clicking:';
                    ShowCaption = false;
                }
                field(TestLicenseHint; TestLicenseLinkText)
                {
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        LicenseKey := SPBLicenseUtilities.GetTestProductKey(Rec);
                    end;
                }
            }
            group(Step3)
            {
                Visible = Step3Visible;
                group(ActivationResultsPageText)
                {
                    Caption = 'Activation Results';
                    group(ActivationWorked)
                    {
                        InstructionalText = 'Activation Successful!';
                        ShowCaption = false;
                        Visible = ActivationResult;
                    }
                    group(ActivationDidNotWork)
                    {
                        InstructionalText = 'Activation Unsuccessful!';
                        ShowCaption = false;
                        Visible = not ActivationResult;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if (Step = Step::Step2) and (LicenseKey = '') then
                        Error(LicenseKeyNeededErr);
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }

    var
        SPBLICActivateMeth: Codeunit "SPBLIC Activate Meth";
        SPBLicenseUtilities: Codeunit "SPBLIC License Utilities";
        ActivationResult: Boolean;
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        ShowAsTestSubscription: Boolean;
        Step1Visible: Boolean;
        Step2TestVisible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        LicenseKeyNeededErr: Label 'You need to enter a License Key to continue.';
        LicenseLinkUriTok: Label 'Get License Key';
        TestLicenseKeyOfferTok: Label 'Use Test Key';
        Step: Option Start,Step2,Step2Test,Finish;
        LicenseFormatHintText: Text;
        LicenseKey: Text;
        LicenseLinkText: Text;
        TestLicenseLinkText: Text;


    trigger OnOpenPage()
    var
        LicensePlatform: Interface "SPBLIC ILicenseCommunicator";
    begin
        LicenseLinkText := LicenseLinkUriTok;
        LicensePlatform := Rec."License Platform";
        LicenseFormatHintText := LicensePlatform.SampleKeyFormatText();
        Step := Step::Start;
        EnableControls();
    end;

    trigger OnAfterGetRecord()
    begin
        ShowAsTestSubscription := Rec.IsTestSubscription();
        TestLicenseLinkText := TestLicenseKeyOfferTok;
    end;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Finish:
                ShowStep3();
        end;
    end;

    local procedure FinishAction()
    begin
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        // Validation trigger when moving from Step2 to 3
        if (Step = Step::Step2) and not Backwards then begin
            Rec."License Key" := CopyStr(LicenseKey, 1, MaxStrLen(Rec."License Key"));
            Rec.Modify();
            ActivationResult := SPBLICActivateMeth.Activate(Rec);
            Step := Step + 1;
        end;

        if (Step = Step::Finish) and Backwards then
            Step := Step - 1;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStep1()
    begin
        Step1Visible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowStep2()
    begin
        if ShowAsTestSubscription then
            Step2TestVisible := true
        else
            Step2Visible := true;
    end;

    local procedure ShowStep3()
    begin
        Step3Visible := true;

        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step2TestVisible := false;
        Step3Visible := false;
    end;


}
