@description('First part of the resource name')
param nameprefix string

@description('Azure region for resources')
param location string = resourceGroup().location

var vnetName = '${nameprefix}vnet01'
var vnetAddressPrefix = '10.12.0.0/16'
var appGatewaySubnetName = 'appgateway'
var appGatewaySubnetPrefix = '10.12.0.0/24'
var machineSubnetName = 'machines'
var machineSubnetPrefix = '10.12.1.0/24'
var nsgAppGatewayName = '${nameprefix}agwnsg'

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewaySubnetPrefix
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgAppGatewayName)
          }
        }
      }
      {
        name: machineSubnetName
        properties: {
          addressPrefix: machineSubnetPrefix
        }
      }
    ]
  }
}

resource nsgAppGateway 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgAppGatewayName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Inbound-Internet'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          destinationAddressPrefix: appGatewaySubnetPrefix
          destinationPortRange: '80'
          priority: 1000          
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Inbound-Gateway'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          priority: 4096
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

output vnetName string = vnetName
output vnetAppGatewaySubnetName string = appGatewaySubnetName
output vnetMachineSubnetName string = machineSubnetName
