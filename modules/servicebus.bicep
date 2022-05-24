param name string
param location string = resourceGroup().location

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
}

output name string = servicebus.name
