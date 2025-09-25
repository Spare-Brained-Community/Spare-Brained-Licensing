namespace SPB.Extensibility;

using SPB.PlatformObjects.Gumroad;
using SPB.PlatformObjects.LemonSqueezy;

enum 71033575 "SPBLIC License Platform" implements "SPBLIC ILicenseCommunicator", "SPBLIC ILicenseCommunicator2", "SPBLIC IUsageIntegration", "SPBLIC IActivationLimit"
{
    DefaultImplementation = 
        "SPBLIC ILicenseCommunicator" = "SPBLIC Gumroad Communicator",
        "SPBLIC ILicenseCommunicator2" = "SPBLIC Gumroad Communicator",
        "SPBLIC IUsageIntegration" = "SPBLIC Gumroad Communicator",
        "SPBLIC IActivationLimit" = "SPBLIC Gumroad Communicator";
    Extensible = true;

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "SPBLIC ILicenseCommunicator" = "SPBLIC Gumroad Communicator", "SPBLIC ILicenseCommunicator2" = "SPBLIC Gumroad Communicator", "SPBLIC IUsageIntegration" = "SPBLIC Gumroad Communicator", "SPBLIC IActivationLimit" = "SPBLIC Gumroad Communicator";
    }
    value(1; LemonSqueezy)
    {
        Caption = 'LemonSqueezy';
        Implementation = "SPBLIC ILicenseCommunicator" = "SPBLIC LemonSqueezy Comm.", "SPBLIC ILicenseCommunicator2" = "SPBLIC LemonSqueezy Comm.", "SPBLIC IUsageIntegration" = "SPBLIC LemonSqueezy Comm.", "SPBLIC IActivationLimit" = "SPBLIC LemonSqueezy Comm.";
    }
}
