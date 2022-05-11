

#connect-azaccount -WarningAction silentlyContinue | Out-Null


# Find all resources of a certain type where its properties match certain values.
# You can add as many Key:Value pairs to the variable $property as necessary.


#               # CHANGE THESE
# $resourceType = "Microsoft.Web/serverfarms"
# $property     = @{zoneRedundant = $false;
#                 }

$resourceType = "Microsoft.Web/sites"
$property = @{"privateEndpointConnections.properties.ipAddresses[0]" = "10.99.102.6"}


$list = New-Object -TypeName "System.Collections.ArrayList"
$subs = Get-AzSubscription 


foreach ($sub in $subs) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    Write-Host("`nSearching '$($sub.Name)' subscription...")
    $resources = Get-AzResource

    foreach ($resource in $resources) {   
        if ($resource.Resourcetype -eq $resourceType) {
            $resource = Get-AzResource -Name $resource.Name -ExpandProperties

            $bool = $true
            foreach ($item in $property.GetEnumerator()){
                if ($resource.properties.($item.Name) -ne $item.Value){
                    $bool = $false
                }
            }
            if ($bool){
                [void]$list.Add($resource)
                Write-Host("FOUND: $($resource.Name). Added to list...")
            }
        }
    }
}
