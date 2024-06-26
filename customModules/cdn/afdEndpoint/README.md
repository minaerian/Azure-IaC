# CDN Profiles AFD Endpoints `[Microsoft.Cdn/profiles/afdEndpoints]`

This module deploys a CDN Profile AFD Endpoint.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Cdn/profiles/afdEndpoints` | [2023-05-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Cdn/profiles/afdEndpoints) |
| `Microsoft.Cdn/profiles/afdEndpoints/routes` | [2023-05-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Cdn/profiles/afdEndpoints/routes) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-name) | string | The name of the AFD Endpoint. |

**Conditional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`profileName`](#parameter-profilename) | string | The name of the parent CDN profile. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`autoGeneratedDomainNameLabelScope`](#parameter-autogenerateddomainnamelabelscope) | string | Indicates the endpoint name reuse scope. The default value is TenantReuse. |
| [`enableDefaultTelemetry`](#parameter-enabledefaulttelemetry) | bool | Enable telemetry via a Globally Unique Identifier (GUID). |
| [`enabledState`](#parameter-enabledstate) | string | Indicates whether the AFD Endpoint is enabled. The default value is Enabled. |
| [`location`](#parameter-location) | string | The location of the AFD Endpoint. |
| [`routes`](#parameter-routes) | array | The list of routes for this AFD Endpoint. |
| [`tags`](#parameter-tags) | object | The tags of the AFD Endpoint. |

### Parameter: `autoGeneratedDomainNameLabelScope`

Indicates the endpoint name reuse scope. The default value is TenantReuse.
- Required: No
- Type: string
- Default: `'TenantReuse'`
- Allowed: `[NoReuse, ResourceGroupReuse, SubscriptionReuse, TenantReuse]`

### Parameter: `enableDefaultTelemetry`

Enable telemetry via a Globally Unique Identifier (GUID).
- Required: No
- Type: bool
- Default: `True`

### Parameter: `enabledState`

Indicates whether the AFD Endpoint is enabled. The default value is Enabled.
- Required: No
- Type: string
- Default: `'Enabled'`
- Allowed: `[Disabled, Enabled]`

### Parameter: `location`

The location of the AFD Endpoint.
- Required: No
- Type: string
- Default: `[resourceGroup().location]`

### Parameter: `name`

The name of the AFD Endpoint.
- Required: Yes
- Type: string

### Parameter: `profileName`

The name of the parent CDN profile. Required if the template is used in a standalone deployment.
- Required: Yes
- Type: string

### Parameter: `routes`

The list of routes for this AFD Endpoint.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `tags`

The tags of the AFD Endpoint.
- Required: No
- Type: object
- Default: `{object}`


## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `location` | string | The location the resource was deployed into. |
| `name` | string | The name of the AFD Endpoint. |
| `resourceGroupName` | string | The name of the resource group the endpoint was created in. |
| `resourceId` | string | The resource id of the AFD Endpoint. |

## Cross-referenced modules

_None_
