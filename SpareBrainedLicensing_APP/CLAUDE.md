# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Spare Brained Licensing** - a Microsoft Dynamics 365 Business Central AL extension that provides a licensing validation and management framework for other BC extensions. It's a defensive security tool that helps extension publishers verify subscription licenses and manage activation/deactivation workflows.

### Key Architecture Components

- **Namespace**: `SPB` (Spare Brained) with sub-namespaces like `SPB.Extensibility`, `SPB.Storage`, `SPB.Callables`
- **AppSourceCop prefix**: `SPB` (configured in AppSourceCop.json and AL-Go settings)
- **Central license storage**: `SPBLIC Extension License` table stores all license information
- **Interface-based platform communication**: Extensible enum pattern with `ILicenseCommunicator` interfaces
- **Built-in platform support**: Gumroad and LemonSqueezy licensing platforms

## Directory Structure

```
src/
├── Callables/           # Public APIs for 3rd party extensions
├── EngineLogic/         # Core business logic (internal methods)
├── Extensibility/       # Interfaces and events system
├── InstallUpgradeBC/    # Installation and upgrade handling
├── PlatformObjects/     # Platform-specific implementations (Gumroad, LemonSqueezy)
├── Storage/             # Data persistence layer
├── Telemetry/           # Application insights integration
└── UserInterface/       # Pages for license management
```

## Development Commands

Since this is an AL project using AL-Go framework:

- **Build**: Handled by AL-Go CI/CD pipeline (no local build commands)
- **Testing**: Test project exists in `../SpareBrainedLicensing_TEST/` 
- **Code Analysis**: Uses AL-Go with CodeCop, UICop, PerTenantExtensionCop, AppSourceCop
- **Ruleset**: Custom rules in `src/.rulesets/SPBLicensing.ruleset.json`

## Core Architectural Patterns

### Interface-Based Platform Integration
The system uses extensible enums implementing multiple interfaces:
- `ILicenseCommunicator`: Basic license verification and misuse reporting
- `ILicenseCommunicator2`: Activation/deactivation operations and test data
- `IUsageIntegration`: Usage-based billing support

### Public API Layer
Extensions integrate via `SPB.Callables` namespace:
- `SPBLIC Extension Registration`: Register extensions for licensing
- `SPBLIC Check Active`: Verify if licenses are active (with/without submodules)
- `SPBLIC Log Usage`: Report usage for usage-based billing

### License State Management
Core workflow through `SPB.EngineLogic`:
- `CheckActiveMeth`: Determines if license is currently valid
- `ActivateMeth`: Handles license key activation process
- `DeactivateMeth`: Manages deactivation (local and platform)
- `LogUsageMeth`: Reports usage metrics to platforms

### Data Architecture
- **Primary table**: `SPBLIC Extension License` (cross-company, AccountData classification)
- **Key fields**: Entry Id (GUID), Extension App Id, Submodule Name, License Platform
- **Isolated storage**: `IsoStoreManager` for sensitive data persistence
- **Trial support**: Grace periods with environment-specific rules

## Extension Points

### Events System
`SPBLIC Events` codeunit provides integration points:
- `OnAfterCheckActiveBasic`: After license validation
- `OnAfterCheckActiveBasicFailure`: When license check fails
- `OnBeforeLaunchProductUrl`: Before opening product pages

### Platform Extension
Add new licensing platforms by:
1. Extending `SPBLIC License Platform` enum
2. Implementing the three core interfaces
3. Adding platform-specific codeunit in `PlatformObjects/`

### API Key Management
Extensible API key providers via `SPBLIC ApiKeyProvider` enum and `IApiKeyProvider` interface.

## Security and Compliance

- **Data classification**: Proper CustomerContent/SystemMetadata/AccountData classification
- **Permissions**: Uses InherentPermissions throughout
- **Sensitive data**: License keys use ExtendedDatatype = Masked
- **Cross-company**: License table spans all companies (DataPerCompany = false)
- **Telemetry**: Application Insights integration for monitoring

## Development Guidelines

- **Error handling**: Use Label declarations, avoid technical jargon in user messages
- **XML documentation**: All public procedures have comprehensive documentation
- **Testing**: Comprehensive test coverage in separate test app
- **Versioning**: Follows semantic versioning, maintains backward compatibility
- **Environment handling**: Different grace periods for Production vs Sandbox
- **Submodule support**: Optional feature for licensing parts of extensions

## Integration Examples

### Basic License Check
```al
procedure CheckMyExtensionLicense()
var
    CheckActive: Codeunit "SPBLIC Check Active";
begin
    // Simple check with error dialog if inactive
    CheckActive.CheckBasic(MyAppId, true);
end;
```

### Extension Registration
```al
procedure RegisterMyExtension()
var
    ExtensionRegistration: Codeunit "SPBLIC Extension Registration";
    AppInfo: ModuleInfo;
    LicensePlatform: Enum "SPBLIC License Platform";
begin
    NavApp.GetCurrentModuleInfo(AppInfo);
    LicensePlatform := LicensePlatform::Gumroad;
    
    ExtensionRegistration.RegisterExtension(
        AppInfo, ProductCode, ProductUrl, SupportUrl, 
        BillingEmail, VersionUrl, UpdateNewsUrl,
        7, 30, Version.Create('25.0.0.0'), LicensePlatform, false);
end;
```

This framework enables extension publishers to easily add subscription-based licensing to their BC extensions while providing a unified management experience for end users.