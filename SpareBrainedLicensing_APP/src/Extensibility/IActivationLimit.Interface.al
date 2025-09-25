namespace SPB.Extensibility;

/// <summary>
/// Interface for retrieving activation limits from licensing platforms.
/// This interface is implemented by licensing platforms that support 
/// dynamic activation limits (e.g., user count restrictions).
/// </summary>
interface "SPBLIC IActivationLimit"
{
    /// <summary>
    /// Retrieves the activation limit for a given license key.
    /// </summary>
    /// <param name="LicenseKey">The license key to query for activation limit</param>
    /// <returns>
    /// Integer representing the activation limit:
    /// - Positive number: Actual activation limit from the platform
    /// - 0: Unlimited activations or feature not supported by platform
    /// </returns>
    procedure GetActivationLimit(LicenseKey: Text): Integer;
}