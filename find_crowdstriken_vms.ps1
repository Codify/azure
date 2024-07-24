$subscriptionIds = @(
    "UPDATE"
)

# Get the current time and subtract one hour
$timeWindowInHours = 12
$window = (Get-Date).AddHours(-$timeWindowInHours)

$hashSet = [System.Collections.Generic.HashSet[string]]::new()


# Function to convert a date string to a DateTime object
function ConvertTo-DateTime($dateString) {
    return [datetime]::Parse($dateString)
}

foreach ($subscriptionId in $subscriptionIds) {

    # Get all VMs in the current subscription
    $vms = az vm list --subscription $subscriptionId --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json | ConvertFrom-Json
    
    foreach ($vm in $vms) {
        # Get the resource health events of the VM
        $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$($vm.ResourceGroup)/providers/Microsoft.Compute/virtualMachines/$($vm.Name)"
        $healthEvents = az rest --method get --uri "https://management.azure.com$resourceId/providers/Microsoft.ResourceHealth/events?api-version=2024-02-01" --output json | ConvertFrom-Json
        
        # Iterate through the health events
        foreach ($event in $healthEvents.value) {
            $impactStartTime = ConvertTo-DateTime $event.properties.impactStartTime
            $platformInitiated = $event.properties.platformInitiated
            $reason = $event.properties.reason
            
            # Write-Output "Tenant: $tenantId, Subscription: $subscriptionId, VM Name: $($vm.Name):"
            # Write-Output "    impactStartTime: $impactStartTime"
            # Write-Output "    platformInitiated: $platformInitiated"
            # Write-Output "    reason: $reason"
            

            # Parse the date string into a DateTime object
            $dateTime = [DateTime]::ParseExact($impactStartTime, 'MM/dd/yyyy HH:mm:ss', $null)


            $withinLastHour = $dateTime -gt $window
            # Write-Output "    Within last hour: $withinLastHour"


            # Check the conditions
            if ($withinLastHour -and -not $platformInitiated -and $reason -eq "VirtualMachineRestarted") {
                Write-Output "Tenant: $tenantId, Subscription: $subscriptionId, VM Name: $($vm.Name) is affected"
                $hashSet.Add($vm.Name)
            } else {
                Write-Output "Tenant: $tenantId, Subscription: $subscriptionId, VM Name: $($vm.Name) is ok"
            }

        }
    }
}

Write-Output "Affected VMs:"
$hashSet | ForEach-Object { Write-Output $_ }
