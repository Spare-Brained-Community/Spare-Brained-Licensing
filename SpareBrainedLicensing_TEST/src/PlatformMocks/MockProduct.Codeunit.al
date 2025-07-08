codeunit 90003 "TST Mock Product" implements "SPBLIC IProduct"
{

    procedure SampleKeyFormatText(): Text
    begin
        exit('abc-001');
    end;

    procedure GetTestProductUrl(): Text
    begin
        exit('https://sparebrained.com');
    end;

    procedure GetTestProductId(): Text
    begin
        exit('abc-001');
    end;

    procedure GetTestProductKey(): Text
    begin
        exit('abc-001');
    end;

    procedure GetTestSupportUrl(): Text
    begin
        exit('https://sparebrained.com');
    end;

    procedure GetTestBillingEmail(): Text
    begin
        exit('support@sparebrained.com');
    end;

}
