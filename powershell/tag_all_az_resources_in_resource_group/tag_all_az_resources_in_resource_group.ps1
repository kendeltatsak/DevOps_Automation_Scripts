
Function Merge-Hashtables {
    $Output = @{}
    ForEach ($Hashtable in ($Input + $Args)) {
        If ($Hashtable -is [Hashtable]) {
            ForEach ($Key in $Hashtable.Keys) {$Output.$Key = $Hashtable.$Key}
        }
    }
    $Output
}


# Default Tags. DO NOT CHANGE
$default_tags = @{
    "WorkloadName"       = "tbd";        # Name of the workload the resource supports. Ex. OneConnect
    "DataClassification" = "dc2";        # Sensitivity of data hosted by this resource. Ex. Non-business, Public, General, Confidential, Highly Confidential
    "Criticality"        = "low";        # Business impact of the resource or supported workload. Ex. Low, Med, High,Business Unit-Critical, Mission-Critical
    "Approver"           = "tbd";        # Person Responsible for approving costs related to this resource. Ex. CIO, CFO, Vice President of Physician Services
    "CostCenter"         = "0000";       # Accounting cost center associated with this resource. This could be used for finance to associate departments with cost.
    "Env"                = "dev";        # Deployment environment of application, workload, or service. Ex. prod|test|dev|poc
    "Owner"              = "kendel.tatsak@spectrumhcp.com";  # Owner of the application, workload, or service. Ex. Phil, Greg, John, Chad
    "OpsTeam"            = "devops";     # Team accountable for day-to-day operations. Ex. Service Desk, System Admins, Cloud Operations, Application Development
    "OpsCommitment"      = "baseline";   # Level of operations support provided for this workload or resource. Ex. Baseline Only, Platform Operations, Workload Operations (SLA)
    "BusinessUnit"       = "central.services"; # Top-level division of your company that owns the subscription or workload that the resource belongs to. In smaller organizations this tag might represent a single corporate or shared top-level organizational element. Ex. Finance, IT, Corp, Shared
}


# Tags to merge into default tags. UPDATE/OVERWRITE TAGS HERE
$merged_tags = @{

 }
 
 $merged_tags = Merge-Hashtables $default_tags $merged_tags

# COST CENTER CODES
# "department" = "0000"     // Department wide, i.e. all of marketing 25-0000
# "anes_central" = "1001"   // Anesthesiology Central
# "anes_south" = "1002"     // Anesthesiology South
# "nir" = "1003"            // Neurointerventional Radiology
# "ortho" = "1006"          // Orthopaedics
# "path" = "1008"           // Pathology
# "path_penbay" = "1009"    // PenBay Pathology
# "rad_north" = "1010"      // Radiology North
# "rad_onc" = "1011"        // Radiation Oncology
# "rad_south" = "1012"      // Radiology South
# "vir" = "1013"            // Vascular Interventional Radiology (VIR)
# "cal" = "2000"            // CMO ASC, LLC (CAL)

# CENTRAL SERVICES CODES
# "admin" = "21"      // Administrative & Executive
# "finance" = "22"    // Finance 
# "hr" = "23"         // Human Resources
# "it" = "24"         // Information Technology
# "marketing" = "25"  // Marketing
# "mss" = "26"        // Medical Staff Services
# "occupancy" = "27"  // Occupancy
# "qi" = "28"         // Quality Improvement
# "rc" = "29"         // Revenue Cycle

connect-azaccount -WarningAction silentlyContinue | Out-Null

while ($true) {


    # Get subscriptions and print them to the screen
    $subs = get-azsubscription
    $i = 0
    foreach ($sub in $subs) {
        $i++
        Write-Output -InputObject "$i. $($sub.Name)"
    }


    # Get input for subscription selection and validate input
    [int]$answer = Read-Host -Prompt "`r`n Select a Subscription from above. (Type an integer between 1 and $i)"
    while ($answer -lt 1 -or $answer -gt $i) {
        Write-Output -InputObject "Invalid input. Type an integer between 1 and $i"
        [int]$answer = Read-Host -Prompt "Select a Subscription from above"
    }


    # Select and print working subscription name
    $sub_selection = $subs[$answer - 1]
    Set-AzContext -SubscriptionId $sub_selection.Id | Out-Null
    Write-Output -InputObject "`r`n Working with $($sub_selection.Name) `r`n"

    
    # Get all Resource Groups in subscription and print them to the screen
    $rgs = Get-AzResourceGroup
    $i = 0
    foreach ($rg in $rgs) {
        $i++
        Write-Output -InputObject "$i. $($rg.ResourceGroupName)"
    }


    # Get input for RG selection and validate input
    [int]$answer = Read-Host "`r`n Select a resource group to apply new tags to (including all nested resources)"
    while ($answer -lt 1 -or $answer -gt $i) {
        Write-Output -InputObject "Invalid input. Type an integer between 1 and $i"
        [int]$answer = Read-Host -Prompt "`r`n Select a resource group from above"
    }


    # Select and print working RG name
    $rg_selection = Get-AzResourceGroup -Name $rgs[$answer - 1].ResourceGroupName
    Write-Output -InputObject "`r`n Working with $($rg_selection.ResourceGroupName) `r`n"
    

    # Print updated tags to the screen after apply. Print all resource Names and resource types in RG that will get the new tags
    Write-Host "Tags after apply:"
    $merged_tags | Out-String | Write-Host
    $resources = Get-AzResource -ResourceGroupName $rg_selection.ResourceGroupName
    Write-Host "Affected resources in Resource Group:"
    Write-Host "Name                    ResourceType"
    Write-Host "----                    ------------"
    foreach($resource in $resources) {
        Write-Host "$($resource.Name), $($resource.ResourceType)"
    }


    # Confirm action of setting new tags
    $prompt = "`r`nSet new tags on resource group and all nested resources?"
    $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
    $default = 1
    $Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)
    switch($Choice){
        0 { $answer = 0}
        1 { $answer = 1}
    }


    # Set tags on each resource in RG
    if ($answer -eq 0) {
        Set-AzResourceGroup -Name $rg_selection.ResourceGroupName -Tag $merged_tags | Out-Null
        foreach($resource in $resources) {
            Write-Host "Setting tags on $($resource.Name)..."
            New-AzTag -ResourceID $resource.Id -Tag $merged_tags | Out-Null
        }
        Write-Host "Done."
    } 
    else {
        Write-Host "No selected..."
    }


    # prompt to go to the begining of the loop
    $prompt = "Do you want to start over?"
    $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
    $default = 1
    $Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)

    switch($Choice){
        0 { $answer = 0}
        1 { $answer = 1}
    }

    if ($answer -eq 1){
        Write-Host "Goodbye... closing program in 5 seconds"
        Start-Sleep -seconds 5
        break
    }
}
