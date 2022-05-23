param containerEnvironmentName string
param location string = resourceGroup().location
param serviceBusName string
param dateNow string = utcNow()

var logAnalyticsWorkspaceName = '${containerEnvironmentName}-logs'
var appInsightsName = '${containerEnvironmentName}-appins'

// Existing

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

// Note: this is for POC/demo concept - do not do this in production!
resource sbAuth 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' existing = {
  name: 'RootManageSharedAccessKey' 
  parent: servicebus
}

// Resources

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerEnvironmentName
  location: location
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspace.id, '2020-03-01-preview').customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, '2020-03-01-preview').primarySharedKey
      }
    }
  }
  resource daprComponent 'daprComponents@2022-03-01' = {
    name: 'pubsub'
    properties: {
      componentType: 'pubsub.azure.servicebus'
      version: 'v1'
      initTimeout: '5s'
      ignoreErrors: false
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: sbAuth.listKeys().primaryConnectionString
        }
      ]
      metadata: [
        {
          name: 'connectionString'
          secretRef: 'sb-root-connectionstring'
        }
      ]
      scopes: [
        'node-subscriber'
        'python-subscriber'
        'react-form'
      ]
    }
  }
}

resource nodeapp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'node-subscriber'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'node-subscriber'
        appProtocol: 'http'
        appPort: 3000
      }
    }
    template: {
      containers: [
        {
          image: 'ghcr.io/dapr/samples/pubsub-node-subscriber:latest'
          name: 'node-subscriber'
          resources: {
            cpu: '0.5'
            memory: '1.0Gi'
          }
        }
      ]
      revisionSuffix: uniqueString(dateNow)
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource pythonapp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'python-subscriber'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'python-subscriber'
        appProtocol: 'http'
        appPort: 5001
      }
    }
    template: {
      containers: [
        {
          image: 'ghcr.io/dapr/samples/pubsub-python-subscriber:latest'
          name: 'python-subscriber'
          resources: {
            cpu: '0.5'
            memory: '1.0Gi'
          }
        }
      ]
      revisionSuffix: uniqueString(dateNow)
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource reactapp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'react-form'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
      dapr: {
        enabled: true
        appId: 'react-form'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: 'ghcr.io/dapr/samples/pubsub-react-form:latest'
          name: 'react-form'
          resources: {
            cpu: '0.5'
            memory: '1.0Gi'
          }
        }
      ]
      revisionSuffix: uniqueString(dateNow)
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

output reactappUri string = reactapp.properties.configuration.ingress.fqdn
