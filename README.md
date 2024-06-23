# Deployment Scopes Management

This project manages deployment scopes across different environments for various Azure subscriptions using Bicep, a domain-specific language (DSL) for deploying Azure resources. The project ensures consistent and secure handling of subscription IDs and network prefixes, facilitating efficient infrastructure management and deployment.

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
  - **dev**: 
    - `this_subscriptionId`: Deploys resources under a specific subscription for development.
    - `hub_subscriptionId`: Deploys the hub network and related resources.
    - `vnet_prefix`: Specifies the virtual network prefix.
  - **qa**: 
    - Similar to dev but used for quality assurance testing.
  - **prod**: 
    - Similar to dev but used for production-ready development resources.

### Production Environment

- **prod**: This environment is used for production deployments. It ensures the resources are ready for live use.
  - **dev**:
    - `this_subscriptionId`: Deploys resources under a specific subscription for production development.
    - `hub_subscriptionId`: Deploys the hub network and related resources.
    - `vnet_prefix`: Specifies the virtual network prefix.
  - **qa**:
    - Similar to dev but used for quality assurance testing in a production setting.
  - **prod**:
    - Similar to dev but used for live production resources.

### Disaster Recovery Development Environment

- **drdev**: This environment is used for disaster recovery scenarios in a development setting. It ensures that resources can be recovered and tested for resilience.
  - **dev**:
    - `this_subscriptionId`: Deploys resources under a specific subscription for disaster recovery development.
    - `hub_subscriptionId`: Deploys the hub network and related resources.
    - `vnet_prefix`: Specifies the virtual network prefix.
  - **qa**:
    - Similar to dev but used for quality assurance testing in a disaster recovery setting.
  - **prod**:
    - Similar to dev but used for production-ready disaster recovery resources.

### Disaster Recovery Production Environment

- **drprod**: This environment is used for disaster recovery scenarios in a production setting. It ensures that live resources can be recovered and maintained.
  - **dev**:
    - `this_subscriptionId`: Deploys resources under a specific subscription for disaster recovery production development.
    - `hub_subscriptionId`: Deploys the hub network and related resources.
    - `vnet_prefix`: Specifies the virtual network prefix.
  - **qa**:
    - Similar to dev but used for quality assurance testing in a disaster recovery setting.
  - **prod**:
    - Similar to dev but used for live production disaster recovery resources.

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

