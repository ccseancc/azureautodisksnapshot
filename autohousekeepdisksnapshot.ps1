$connectionName = "AzureRunAsConnection"

#Getting the service principal connection "AzureRunAsConnection"
$connection = Get-AutomationConnection -name $connectionName
Connect-AzAccount -Environment AzureChinaCloud -ServicePrincipal -Tenant $connection.TenantID -ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()
$tzCST = [System.TimeZoneInfo]::FindSystemTimeZoneById("China Standard Time")
$CurrentTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($currentUTCtime, $tzCST)

#region function

# Variables
$StorageTableName = "akssnapshotbackup"

Write-Output "Search subscription for database store..."
$Database = Get-AzResource -TagName 'aksSnapshotBackupDatabase' -TagValue 'tableStorage'
if ($null -eq $Database) {
    Write-Error "No database store found."
    throw
}
if ($Database.length -gt 1) {
    Write-Error "More than one database store found."
    throw
}

Write-Output "Search subscription for tagged AKS Azure disks to backup..."
$Resources = Get-AzResource -TagName 'aksSnapshotBackupEnabled' -TagValue 'true'

Write-Output "Getting table storage context..."
$StorageContext = (Get-AzStorageAccount -ResourceGroupName $Database.ResourceGroupName -Name $Database.Name -ErrorAction Stop).Context

$Table = (Get-AzStorageTable -Name $StorageTableName -Context $StorageContext -ErrorAction SilentlyContinue).CloudTable
if ($null -eq $Table) {
    Write-Output "Initializing table $StorageTableName..."
    $Table = (New-AzStorageTable -Name $StorageTableName -Context $StorageContext -ErrorAction Stop).CloudTable
}

Write-Output "Removing old disk snapshots..."
$Entries = Get-AzTableRow -Table $Table -ErrorAction Stop
foreach ($Entry in $Entries) {
    $CheckRetentionTime = "-" + $Entry.retentionTime
    $CheckDate = (Get-Date $CurrentTime).AddDays($CheckRetentionTime)
    $CheckPartitionKey = [String]$CheckDate.Year + "-" + [String]$CheckDate.Month + "-" + [String]$CheckDate.Day
    if ($Entry.PartitionKey -eq $CheckPartitionKey) {
        Write-Output "Removing disk snapshot..."
        Remove-AzResource -ResourceId $Entry.azureSnapshotResourceId -Force -ErrorAction Continue
        Write-Output "Removing table storage entry..."
        $Entry | Remove-AzTableRow -Table $Table -ErrorAction Continue
    }
}

#endregion

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $CurrentTime"