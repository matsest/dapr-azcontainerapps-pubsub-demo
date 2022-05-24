targetScope = 'subscription'

param rgName string
param location string
param containerEnvironmentName string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module servicebus 'modules/servicebus.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-servicebus'
  params: {
    name: 'dapr-pubsub${uniqueString(resourceGroup.id)}'
    location: location
  }
}

module containerEnvironment 'modules/environment.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-env'
  params: {
    containerEnvironmentName: containerEnvironmentName
    location: location
  }
}

module containerApps 'modules/apps.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-apps'
  params: {
    location: location
    environmentName: containerEnvironment.outputs.environmentName
    serviceBusName: servicebus.outputs.name
  }
}

output uri string = containerApps.outputs.reactappUri
