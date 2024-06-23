# Azure Infrastructure as Code (IaC) Deployment

This project leverages Azure Bicep to manage and deploy infrastructure across various environments in Azure. It ensures consistent and secure handling of subscription IDs and network configurations, facilitating efficient infrastructure management and deployment.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Deployment Scopes](#deployment-scopes)
  - [Development Environment](#development-environment)
  - [Production Environment](#production-environment)
  - [Disaster Recovery Development Environment](#disaster-recovery-development-environment)
  - [Disaster Recovery Production Environment](#disaster-recovery-production-environment)
- [Resource Modules](#resource-modules)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Overview

This project is designed to manage deployment scopes for multiple environments including `dev`, `qa`, `prod`, `drdev`, and `drprod`. Each environment contains various resource environments such as `dev`, `prod`, and others. The project ensures secure and consistent handling of subscription IDs and network configurations across different Azure subscriptions.

## Prerequisites

Before you begin, ensure you have met the following requirements:
- You have an Azure account with appropriate permissions.
- You have [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your local machine.
- You have [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) installed on your local machine.
- You have [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) installed on your local machine.

## Installation

1. Clone the repository to your local machine:

    ```bash
    git clone https://github.com/minaerian/Azure-IaC.git
    ```

2. Navigate to the project directory:

    ```bash
    cd Azure-IaC
    ```

3. Ensure all required tools are installed and configured.

## Usage

1. Update the `deployment_scopes` configuration in the respective `.bicep` files as per your environment needs.
2. Use the Azure CLI to deploy the configurations:

    ```bash
    az deployment group create --resource-group <your-resource-group> --template-file hub.bicep
    ```

3. Verify the deployments through the Azure portal or using the Azure CLI.

## Deployment Scopes

### Development Environment

- **dev**: This environment is used for development purposes. It includes resources for various stages such as dev, qa, and prod.
  - **dev**, **qa**, **prod**: Each of these stages has configurations for:
    - `this_subscriptionId`: Deploys resources under a specific subscription for the respective stage.
    - `hub_subscriptionId`: Deploys the hub network and related resources.
    - `vnet_prefix`: Specifies the virtual network prefix.

### Production Environment

- **prod**: This environment is used for production deployments. It ensures the resources are ready for live use.
  - **dev**, **qa**, **prod**: Each of these stages has configurations similar to the development environment but tailored for production readiness.

### Disaster Recovery Development Environment

- **drdev**: This environment is used for disaster recovery scenarios in a development setting. It ensures that resources can be recovered and tested for resilience.
  - **dev**, **qa**, **prod**: Each of these stages has configurations for disaster recovery in the development setting.

### Disaster Recovery Production Environment

- **drprod**: This environment is used for disaster recovery scenarios in a production setting. It ensures that live resources can be recovered and maintained.
  - **dev**, **qa**, **prod**: Each of these stages has configurations for disaster recovery in the production setting.

## Resource Modules

### Network Resources

- **Resource Group**: Defines the resource group for network resources.
- **Virtual WAN (vWAN)**: Configures the virtual WAN with options for branch-to-branch traffic, VNet-to-VNet traffic, VPN encryption, etc.
- **Virtual Hub (vHub)**: Configures the virtual hub with address prefixes and connections to the virtual WAN.
- **Azure Firewall**: Deploys and configures the Azure Firewall with rules and diagnostics.
- **P2S VPN Gateway**: Configures the Point-to-Site VPN gateway with necessary parameters.
- **S2S VPN Gateway**: Configures the Site-to-Site VPN gateway with necessary parameters.
- **BGP Connections**: Manages BGP connections between virtual networks and the virtual hub.

### Identity Resources

- **Resource Group**: Defines the resource group for identity services.
- **Virtual Network**: Configures the virtual network for identity services.
- **Availability Set**: Sets up availability sets for high availability of identity services.
- **Domain Controllers**: Deploys domain controllers within the identity VNet.

### Private DNS Resources

- **Resource Group**: Defines the resource group for private DNS.
- **DNS Zones**: Creates and configures private DNS zones.
- **VNet Links**: Links DNS zones to virtual networks for DNS resolution.

### Shared Services Resources

- **Resource Group**: Defines the resource group for shared services.
- **Virtual Network**: Configures the virtual network for shared services.
- **Bastion Host**: Deploys a Bastion host for secure remote access.
- **Load Balancer**: Configures load balancers for shared services.
- **Private Link Service**: Sets up private link services for secure access to Azure resources.

### Meraki vMX Resources

- **Resource Group**: Defines the resource group for Meraki vMX resources.
- **Virtual Network**: Configures the virtual network for Meraki vMX.
- **Meraki vMX Appliances**: Deploys Meraki vMX virtual appliances.

### Front Door Resources

- **Resource Group**: Defines the resource group for Front Door resources.
- **Web Application Firewall (WAF)**: Configures the WAF policies for Front Door.
- **Front Door**: Deploys Azure Front Door with security policies and configurations.

### Key Vault Resources

- **Resource Group**: Defines the resource group for Key Vault.
- **Key Vault**: Deploys Azure Key Vault for secure storage of secrets.

### Data Collection Rule (DCR) Resources

- **Resource Group**: Defines the resource group for data collection rules.
- **Data Collection Rule**: Configures data collection rules for monitoring and diagnostics.

## Contributing

Contributions are welcome! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch:

    ```bash
    git checkout -b feature-branch
    ```

3. Make your changes and commit them:

    ```bash
    git commit -m "Add feature"
    ```

4. Push to the branch:

    ```bash
    git push origin feature-branch
    ```

5. Open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please contact Mina Erian at [mina.info.tech@gmail.com](mailto:mina.info.tech@gmail.com).
