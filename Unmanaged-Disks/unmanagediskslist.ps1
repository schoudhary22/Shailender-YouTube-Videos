
# Get all storage accounts in the subscription
$storageAccounts = Get-AzStorageAccount

# Iterate through each storage account
foreach ($storageAccount in $storageAccounts) {
    
    # Get the resource group and storage account name
    $resourceGroupName = $storageAccount.ResourceGroupName
    $storageAccountName = $storageAccount.StorageAccountName

    # Get the storage account key
    $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value

    # Create a storage context using the account key
    $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

    # Get all containers in the storage account
    $containers = Get-AzStorageContainer -Context $context

    # Iterate through each container and look for unattached/unmanaged disks (VHD files)
    foreach ($container in $containers) {
        Write-Output "Scanning container: $($container.Name) in storage account: $($storageAccountName)"

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
}
