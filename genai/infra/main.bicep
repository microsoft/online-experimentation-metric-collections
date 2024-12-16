targetScope = 'subscription'

param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceLocation string
param logAnalyticsWorkspaceResourceGroupName string

resource logAnalyticsWorkspaceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: logAnalyticsWorkspaceResourceGroupName
}


// summary rule module
var ruleDefinitions = loadYamlContent('./monitor/summaryrules.yaml')
module summaryRules './monitor/summaryrule.bicep' =  [ for (rule, i) in ruleDefinitions.summaryRules: {
  name: 'loganalytics-summaryrule-${i}'
  scope: logAnalyticsWorkspaceResourceGroup
  params: {
    location: logAnalyticsWorkspaceLocation  
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    summaryRuleName: rule.name
    description: rule.description
    query: rule.query
    binSize: rule.binSize // see choices at https://aka.ms/LogsSummaryRule#create-or-update-a-summary-rule
    destinationTable: rule.destinationTable
  }
} ]
