# Pub-Sub Dapr Container Apps in Azure

> Learning Azure Container Apps

This repo contains code to deploy the [Dapr pub-sub application](https://github.com/dapr/quickstarts/tree/master/tutorials/pub-sub) on [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/overview) with [Dapr](https://dapr.io/) using Azure Service Bus for handling publisher and subscriber (Pub-Sub) functionality. The application consists of a React web frontend, a Python subscriber component and a Node subscriber component.

### Technologies

- :hammer: Azure PowerShell and AZ CLI for interaction with Azure
- :gear: PowerShell for deployment script
- :muscle: Bicep for Infrastructure as Code

### Overview

> TODO: update diagram. Redis -> Azure Service Bus

![diagram](static/Local_Architecture_Diagram.png)
([diagram by Dapr](https://docs.microsoft.com/en-us/azure/container-apps/microservices-dapr-azure-resource-manager?tabs=powershell&pivots=container-apps-bicep#prerequisites) - [Apache 2.0](https://github.com/dapr/quickstarts/blob/master/LICENSE))

## Usage

### Prerequisites

1. [Install/update Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=latest)
2. [Install/update Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
    - Install `containerapp` extension: `az extension add --name containerapp --upgrade` (as of May 2022 this is not available in Azure PowerShell)
3. [Install/update Bicep CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually=)
4. Connect to Azure:
    - Az Pwsh: `Connect-AzAccount`
    - az cli: `az login`
5. Set Context:
    - Az Pwsh: `Set-AzContext -SubscriptionName <subscription name>`
    - az cli: `az account set --name <subscription name>`
6. Register resource provider: `Register-AzResourceProvider -ProviderNamespace Microsoft.App`

### Deploy

Open PowerShell and run [deploy.ps1](./deploy.ps1) to deploy the resources:

```powershell
./deploy.ps1

# Example output
🚀 Deploying container apps...(this will take a few minutes)

✔️  Deploy succeeded! React frontend url:
https://react-form.<unique name>.canadacentral.azurecontainerapps.io/order
```

### Send a publisher message

1. Open the React frontend url:

![](static/reactform.png)

2. Choose one of the message types and enter your custom message, and press **Submit**

**Note:** If you choose 'B' the message will only be received by the Node app, while 'C' will only be received by the Python app. 'A' will be received by both.

### Verify messages in subscribers

> Todo - fetch logs from containers / log analytics

## Clean up resources

To clean up resources run the following command:

```powershell
Remove-AzResourceGroup -Name dapr-pubsub-containerapps-demo -Force
```