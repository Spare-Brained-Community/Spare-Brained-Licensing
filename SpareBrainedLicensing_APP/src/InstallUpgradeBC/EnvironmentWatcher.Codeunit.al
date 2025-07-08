codeunit 71033589 "SPBLIC Environment Watcher"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerDatabase', '', false, false)]
    local procedure DeactivateLicensesWhenEnvironmentCopied(DestinationEnvironmentType: Option Production,Sandbox)
    var
        SPBExtensionLicense: Record "SPBLIC Extension License";
        SPBLICDeactivateMeth: Codeunit "SPBLIC Deactivate Meth";
        GraceDaysMathTok: Label '<+%1D>', Locked = true;
    begin
        SPBExtensionLicense.SetRange(Activated, true);
        if SPBExtensionLicense.FindSet(true) then
            repeat
                if DestinationEnvironmentType = DestinationEnvironmentType::Sandbox then begin
                    // Reset all licenses to Sandbox grace
                    if SPBExtensionLicense."Sandbox Grace Days" <> 0 then
                        SPBExtensionLicense."Trial Grace End Date" := CalcDate(StrSubstNo(GraceDaysMathTok, SPBExtensionLicense."Sandbox Grace Days"), Today());
                    SPBLICDeactivateMeth.Deactivate(SPBExtensionLicense, false);
                end else
                    // Deactivate the licenses in general
                    SPBLICDeactivateMeth.Deactivate(SPBExtensionLicense, false);
            until SPBExtensionLicense.Next() = 0;
    end;
}
