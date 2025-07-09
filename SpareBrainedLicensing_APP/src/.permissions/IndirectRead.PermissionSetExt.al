namespace SPB.Permissions;

using SPB.Storage;
using System.Security.AccessControl;

permissionsetextension 71033575 "SPBLIC Indirect Read" extends "D365 READ"
{
    Permissions = tabledata "SPBLIC Extension License" = rim;
}
