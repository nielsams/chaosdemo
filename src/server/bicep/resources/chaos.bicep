param nameprefix string
param location string = resourceGroup().location
param vmssName string 

var chaosName = '${nameprefix}-chaos'

var selectorId = guid('${chaosName}-${vmssName}')
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var vmssResourceId = resourceId('Microsoft.Compute/virtualMachineScaleSets', vmssName)

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: contributorRoleId
}

resource chaos_experiment 'Microsoft.Chaos/experiments@2022-10-01-preview' = {
  name: chaosName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    startOnCreation: false
    selectors: [
      {
        type: 'List'
        id: selectorId
        targets: [
          {
            id: '${vmssResourceId}/providers/Microsoft.Chaos/targets/Microsoft-Agent'
            type: 'ChaosTarget'
          }
        ]
      }
    ]
    steps: [
      {
        name: 'Step 1'
        branches: [
          {
            name: 'Branch 1'
            actions: [
              {
                type: 'continuous'
                selectorId: selectorId
                duration: 'PT5M' // 5 minutes
                parameters: [
                  {
                    key: 'serviceName'
                    value: 'W3SVC'
                  }
                  {
                    key: 'virtualMachineScaleSetInstances'
                    value: '[0]' // Experiment targets only the first node of the VMSS
                  }
                ]
                name: 'urn:csci:microsoft:agent:stopService/1.0'
              }
            ]
          }
        ]
      }
    ]
  }
}

resource experimentRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid('${chaosName}-roleAssignment')
  properties: {
    principalId: chaos_experiment.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRole.id
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-07-01' existing = {
  name: vmssName
}

resource chaosagent_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: '${nameprefix}-chaos-id'
}

resource chaos_agent_extension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2021-07-01' = {
  name: 'ChaosAgent'
  parent: vmss
  properties: {
    publisher: 'Microsoft.Azure.Chaos'
    type: 'ChaosWindowsAgent'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    typeHandlerVersion: '1.0'
    settings: {
      profile: chaos_agent_target.properties.agentProfileId
      'auth.msi.clientid': chaosagent_identity.properties.clientId
      appinsightskey: ''
    }
  }
}

resource chaos_service_target 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'Microsoft-virtualMachineScaleSet'
  scope: vmss
  properties: {}
}

resource chaos_agent_target 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'Microsoft-Agent'
  scope: vmss
  properties: {
    identities: [
      {
        type: 'AzureManagedIdentity'
        clientId: chaosagent_identity.properties.clientId
        tenantId: chaosagent_identity.properties.tenantId
      }
    ]
  }
}

resource chaos_target_capability_stopservice 'Microsoft.Chaos/targets/capabilities@2022-10-01-preview' = {
  name: 'StopService-1.0'
  parent: chaos_agent_target
}
