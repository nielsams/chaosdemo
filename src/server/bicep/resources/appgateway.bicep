param nameprefix string
param location string = resourceGroup().location
param vnetName string
param vnetAppGatewaySubnetName string

var pipName = '${nameprefix}pip01'
var pipSku = 'Standard'
var pipTier = 'Regional'
var pipAllocationMethod = 'Static'

var appGatewayName = '${nameprefix}agw01'
var appGatewaySize = 'Standard_v2'
var appGatewayMinCap = 1
var appGatewayMaxCap = 3
var appGatewayBackendPoolName = 'BackendPool1'

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: pipName
  location: location
  sku: {
    name: pipSku
    tier: pipTier
  }
  properties: {
    publicIPAllocationMethod: pipAllocationMethod
    dnsSettings: {
      domainNameLabel: nameprefix
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2020-06-01' = {
  name: appGatewayName
  location: location
  properties: {
    sku: {
      name: appGatewaySize
      tier: 'Standard_v2'
    }
    autoscaleConfiguration: {
      minCapacity: appGatewayMinCap
      maxCapacity: appGatewayMaxCap
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vnetAppGatewaySubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGatewayBackendPoolName
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'defaultProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, appGatewayBackendPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'defaultProbe'
        properties: {
          host: '127.0.0.1'
          interval: 5
          match: {
            statusCodes: [
              '200'
            ]
          }
          path: '/'
          pickHostNameFromBackendHttpSettings: false
          port: 80
          protocol: 'http'
          timeout: 3
          unhealthyThreshold: 2
        }
      }
    ]
  }
}

output appGatewayName string = appGatewayName
output appGatewayBackendPoolName string = appGatewayBackendPoolName
output appGatewayDNSName string = publicIp.properties.dnsSettings.fqdn
