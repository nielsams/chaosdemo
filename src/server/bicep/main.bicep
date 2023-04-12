targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@secure()
param vmssAdminPassword string

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${name}-rg'
  location: location
}

module network './resources/network.bicep' = {
  name: '${rg.name}-network'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
  }
}

module vmss './resources/vmss.bicep' = {
  name: '${rg.name}-vmss'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
    vnetName: network.outputs.vnetName
    vnetMachineSubnetName: network.outputs.vnetMachineSubnetName
    appGatewayBackendPoolName: appgateway.outputs.appGatewayBackendPoolName
    appGatewayName: appgateway.outputs.appGatewayName
    vmssAdminPassword: vmssAdminPassword
  }
}

module appgateway './resources/appgateway.bicep' = {
  name: '${rg.name}-appgateway'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
    vnetName: network.outputs.vnetName
    vnetAppGatewaySubnetName: network.outputs.vnetAppGatewaySubnetName
  }
}

module chaos './resources/chaos.bicep' = {
  name: '${rg.name}-chaos'
  scope: rg
  params: {
    nameprefix: toLower(name)
    location: rg.location
    vmssName: vmss.outputs.vmssName
  }
}
