namespace SPB.Extensibility.ApiKey;

interface "SPBLIC IApiKeyProvider"
{
    procedure GetApiKey(): SecretText
}