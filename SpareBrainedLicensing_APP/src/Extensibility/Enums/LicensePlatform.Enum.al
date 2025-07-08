enum 71033575 "SPBLIC License Platform" implements "SPBLIC IActivation", "SPBLIC IProduct"
{
    Extensible = true;
    UnknownValueImplementation = "SPBLIC IActivation" = "SPBLIC Unknown Activation", "SPBLIC IProduct" = "SPBLIC Unknown Product";

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "SPBLIC IActivation" = "SPBLIC Gumroad Communicator", "SPBLIC IProduct" = "SPBLIC Gumroad Communicator";
    }
    value(1; LemonSqueezy)
    {
        Caption = 'LemonSqueezy';
        Implementation = "SPBLIC IActivation" = "SPBLIC LemonSqueezy Comm.", "SPBLIC IProduct" = "SPBLIC LemonSqueezy Comm.";
    }
}
