codeunit 90004 "TST VC Healthy"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SPBLIC Events", OnBeforeVersionCheckCall, '', false, false)]
    local procedure InterceptWithNewVersion(var SPBExtensionLicense: Record "SPBLIC Extension License"; var VersionResponseBody: Text; var IsHandled: Boolean)
    begin
        IsHandled := true;
        VersionResponseBody := '99.9.9.9';
    end;
}
