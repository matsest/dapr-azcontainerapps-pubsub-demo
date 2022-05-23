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
    authName: 'auth'
    name: 'dapr-pubsub${uniqueString(resourceGroup.id)}'
    location: location
  }
}


module containerApps 'modules/containerapp.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-apps'
  params: {
    containerEnvironmentName: containerEnvironmentName
    location: location
    serviceBusName: servicebus.outputs.name
  }
}

output uri string = containerApps.outputs.reactappUri
