namespace SPB.Extensibility.ApiKey;

codeunit 71033596 "SPBLIC EmptyApiKeyProvider" implements "SPBLIC IApiKeyProvider"
{
    Access = Internal;
    InherentPermissions = X;

    procedure GetApiKey(): SecretText
    begin
        exit(Format(''));
    end;
}