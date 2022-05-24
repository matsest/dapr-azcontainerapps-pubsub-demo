param environmentName string
param serviceBusName string
param location string = resourceGroup().location
param dateNow string = utcNow()

// Existing
resource environment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: environmentName
}

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

// Note: this is for POC/demo concept - do not do this in production!
resource sbAuth 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' existing = {
  name: 'RootManageSharedAccessKey' 
  parent: servicebus
}


// Resources
resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
    name: 'pubsub'
    parent: environment
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
