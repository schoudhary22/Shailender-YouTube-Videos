# Parameters with default values
param (
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "xxxxxxx",  # Replace with your default resource group

    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "xxxxxxx",  # Replace with your default storage account

    [Parameter(Mandatory=$false)]
    [string]$ContainerName = "vhds"  # Replace with your default container or set null for all containers
)


# Get the storage account in the specified resource group
$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

if ($null -eq $storageAccount) {
    Write-Error "Storage account not found!"
    exit
}

# Get the storage account key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value

# Create a storage context using the account key
$context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey

# If a container name is provided, only scan that container
if ($ContainerName) {
    $containers = @(Get-AzStorageContainer -Context $context | Where-Object { $_.Name -eq $ContainerName })
} else {
    # If no container name is provided, scan all containers in the storage account
    $containers = Get-AzStorageContainer -Context $context
}

# Iterate through each container and look for unattached/unmanaged disks (VHD files)
foreach ($container in $containers) {
    Write-Output "Scanning container: $($container.Name)"
    
    # List all blobs (files) in the container
    $blobs = Get-AzStorageBlob -Container $container.Name -Context $context
    
    foreach ($blob in $blobs) {
        # Check if the blob is a VHD file (unmanaged disk)
        if ($blob.Name -like "*.vhd") {
            # Fetch the latest attributes to ensure we get the correct lease status
            $blob.ICloudBlob.FetchAttributes()

            # Get the lease status of the VHD
            $leaseStatus = $blob.ICloudBlob.Properties.LeaseState

            # If lease status is "unlocked", the VHD is unattached
            if ($leaseStatus -ne "Leased") {
                Write-Output "Disk Name: $($blob.Name)"
                Write-Output "Storage Account: $($storageAccountName)"
                Write-Output "Container: $($container.Name)"
                Write-Output "Lease Status: $leaseStatus"
                Write-Output "==================================="
            }
        }
    }
}
