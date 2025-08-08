# Parameter values for TEST environment
$subscriptionName         = ""
$projectName              = ""
$appResourceGroup         = ""
$dataResourceGroup        = ""
$monitoringResourceGroup  = ""
$regionAbbreviation       = ""
$sku                      = ""
$osType                   = ""
$runtimeStack             = ""
$runtimeVersion           = ""
$subnetAddressSpace       = ""
$subnetDescription        = ""
$Owner                    = ""
$CostCenter               = ""

# UNIQUE PARAM FILE NAME

# Generate date in yyyyMMdd format
$currentDate = Get-Date -Format "yyyyMMdd"

# Construct param file name
$paramFile = "main.$projectName-PROD-$currentDate.bicepparam"

# Template and param files
$templateFile = "main.bicep"

# Log setup
$timestamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$deploymentName = "DeployTest-${projectName}--$timestamp"

function Get-FullRegionName {
    param ([string]$abbr)

    switch ($abbr.ToLower()) {
        'swn' { return 'switzerlandnorth' }
        'usc' { return 'southcentralus' }
        'weu' { return 'westeurope' }
        'sea' { return 'southeastasia' }
        default {
            Write-Warning "Unknown region abbreviation '$abbr'. Returning input as-is."
            return $abbr
        }
    }
}

# Set subscription
az login
az account set --subscription $subscriptionName

#Get Subscription ID
$subscriptionId = az account list --query "[?name=='$subscriptionName'].id" -o tsv

# Discover VNet
$vnetInfo = az network vnet list `
  --query "[?starts_with(name, 'vnet-') && contains(name, '$regionAbbreviation') && starts_with(resourceGroup, 'rg-vnet-') && contains(resourceGroup, '$regionAbbreviation')]" `
  --output json | ConvertFrom-Json | Select-Object -First 1


$vNetName = $vnetInfo.name
$vNetRG = $vnetInfo.resourceGroup
$vNetAddressSpace = $vnetInfo.addressSpace.addressPrefixes[0]
$fullRegion = Get-FullRegionName -abbr $regionAbbreviation
$subnetInfo = az network vnet subnet list `
  --resource-group $vNetRG `
  --vnet-name $vNetName `
  --query "[?contains(name, 'pe') || contains(name, 'private')]" `
  --output json | ConvertFrom-Json | Select-Object -First 1


$peSubnetName = $subnetInfo.name

# Generate .bicepparam file dynamically
$bicepParamContent = @"
using './main.bicep'

param projectName = '$projectName'
param AppResourceGroup = '$appResourceGroup'
param DataResourceGroup = '$dataResourceGroup'
param MonitoringResourceGroup = '$monitoringResourceGroup'
param regionAbbreviation = '$regionAbbreviation'
param sku = '$sku'
param osType = '$osType'
param RuntimeStack = '$runtimeStack'
param RuntimeVersion = '$runtimeVersion'
param vNetName = '$vNetName'
param vNetRG = '$vNetRG'
param peSubnetName = '$peSubnetName'
param vNetAddressSpace = '$vNetAddressSpace'
param subnetAddressSpace = '$subnetAddressSpace'
param subnetDescription = '$subnetDescription'
param Owner = '$Owner'
param CostCenter = '$CostCenter'
param subscriptionId = '$subscriptionId'
"@

# Save .bicepparam
$bicepParamContent | Set-Content -Path $paramFile -Encoding UTF8

 # Validate Bicep
az deployment sub validate `
    --location $fullRegion `
    --template-file $templateFile `
    --parameters $paramFile `
   2>&1
 

# Deploy
az deployment sub create `
  --name $deploymentName `
  --location $fullRegion `
  --template-file $templateFile `
  --parameters $paramFile `
  --debug 2>&1
