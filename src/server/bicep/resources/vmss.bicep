param nameprefix string
param location string = resourceGroup().location
param vnetName string
param vnetMachineSubnetName string
param appGatewayName string
param appGatewayBackendPoolName string
@secure()
param vmssAdminPassword string
//param forceUpdateTag string = utcNow()

var nicName = '${nameprefix}vmssnic'
var ipConfigName = '${nameprefix}ipconfig'

var vmssName = '${nameprefix}vmss'
var vmssComputerNamePrefix = 'vmss'
var vmssAdminUser = 'vmssadmin'
var vmssInstanceCount = 3
var vmssVmSku = 'Standard_A1_v2'

var imageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

// This is the user managed identity used by the chaos agent on VMSS to report back to the Chaos Service
resource chaosagent_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${nameprefix}-chaos-id'
  location: location
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmssVmSku
    tier: 'Standard'
    capacity: vmssInstanceCount
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${chaosagent_identity.id}': {}
    }
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssComputerNamePrefix
        adminUsername: vmssAdminUser
        adminPassword: vmssAdminPassword
        customData: loadFileAsBase64('../../content/payload.aspx')
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vnetMachineSubnetName)
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, appGatewayBackendPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'customScript'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.8'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: loadTextContent('../../content/iis-setup.cmd')
              }
            }
          }
        ]
      }
    }
  }
}

// This extension installs IIS and deploys our aspx payload
// resource vmss_customscript 'Microsoft.Compute/virtualMachineScaleSets/extensions@2022-11-01' = {
//   name: 'customScript'
//   parent: vmss
//   properties: {
//     publisher: 'Microsoft.Compute'
//     type: 'CustomScriptExtension'
//     typeHandlerVersion: '1.8'
//     autoUpgradeMinorVersion: true
//     protectedSettings: {
//       commandToExecute: loadTextContent('../../content/iis-setup.cmd')
//     }
//   }
// }



output vmssName string = vmssName
