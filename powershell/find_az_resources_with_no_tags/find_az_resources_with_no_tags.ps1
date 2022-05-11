

$default_tags = @{
    "WorkloadName"       = "tbd";        # Name of the workload the resource supports. Ex. OneConnect
    "DataClassification" = "dc2";        # Sensitivity of data hosted by this resource. Ex. Non-business, Public, General, Confidential, Highly Confidential
    "Criticality"        = "low";        # Business impact of the resource or supported workload. Ex. Low, Med, High,Business Unit-Critical, Mission-Critical
    "Approver"           = "tbd";        # Person Responsible for approving costs related to this resource. Ex. CIO, CFO, Vice President of Physician Services
    "CostCenter"         = "0000";       # Accounting cost center associated with this resource. This could be used for finance to associate departments with cost.
    "Env"                = "dev", "test", "prod";        # Deployment environment of application, workload, or service. Ex. prod|test|dev|poc
    "Owner"              = "kendel.tatsak@spectrumhcp.com";  # Owner of the application, workload, or service. Ex. Phil, Greg, John, Chad
    "OpsTeam"            = "devops";     # Team accountable for day-to-day operations. Ex. Service Desk, System Admins, Cloud Operations, Application Development
    "OpsCommitment"      = "baseline";   # Level of operations support provided for this workload or resource. Ex. Baseline Only, Platform Operations, Workload Operations (SLA)
    "BusinessUnit"       = "central.services"; # Top-level division of your company that owns the subscription or workload that the resource belongs to. In smaller organizations this tag might represent a single corporate or shared top-level organizational element. Ex. Finance, IT, Corp, Shared
}

connect-azaccount -WarningAction silentlyContinue | Out-Null
$date = Get-Date -Format "yyyy_MM_dd"

$subs = Get-AzSubscription 
foreach ($sub in $subs) {
    Set-AzContext -Subscription $sub.Id 
    $resources = Get-AzResource 
    
    foreach ($resource in $resources) {
        $resource | Add-Member -MemberType NoteProperty -Name Subscription -value $sub.Name

        # Find resources with NO Tags and write into to csv
        if ($resource.Tags.Count -eq 0) {
            $resource | Select-Object -Property name,resourcegroupname,subscription | Export-Csv -Path (".\runs\$date" + "_resources_without_tags.csv") -Append
        } 

        # Find resources with Default Tags ONLY and write into a csv
        else {
            $bool = $true
            foreach ($value in $resource.Tags.Values.split()) {
                if ($default_tags.Values.split() -notcontains $value){
                    $bool = $false
                }
            }
            if ($bool -eq $true) {
                $resource | Select-Object -Property name,resourcegroupname,subscription | Export-Csv -Path (".\runs\$date" + "_resources_with_default_tags_only.csv") -Append
            }
        }
    }
}
