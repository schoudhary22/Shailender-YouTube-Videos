Param
(
    [Parameter (Mandatory= $true)]
    [string]$VmResourceGroup,
    [Parameter (Mandatory= $true)]
    [string]$VmName
)

Connect-AzAccount -Identity
Set-AzContext -SubscriptionId "xxxx-xxxxxx-xxxxxx-xxxxx"




# Get VM
$vm = get-azvm -Name $VmName -ResourceGroupName $VmResourceGroup


$snapscreated = @()

#VM Snapshot
Write-Output "VM $($vm.name) OS Disk Snapshot Begin"
$snapshotdisk = $vm.StorageProfile

$OSDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $snapshotdisk.OsDisk.ManagedDisk.id -CreateOption Copy -Location australiaeast # -OsType Windows
$snapshotNameOS = "snap_$($snapshotdisk.OsDisk.Name)_snap_osdisk_$(Get-Date -Format ddMMyyhhmm)"

# OS Disk Snapshot

New-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameOS -Snapshot $OSDiskSnapshotConfig -ErrorAction Stop
$snapscreated += $snapshotNameOS

Write-Output "VM $($vm.name) OS Disk Snapshot End"
Write-Output "====================================="

# Data Disk Snapshots 
 
Write-Output "VM $($vm.name) Data Disk Snapshots Begin"
 
$dataDisks = ($snapshotdisk.DataDisks).name

foreach ($datadisk in $datadisks) {

    $dataDisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $datadisk

    Write-Output "VM $($vm.name) data Disk $($datadisk.Name) Snapshot Begin"

    $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location australiaeast
    $snapshotNameData = "snap_$($datadisk.name)_snap_datadisk_$(Get-Date -Format ddMMyyhhmm)"

    New-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameData -Snapshot $DataDiskSnapshotConfig -ErrorAction Stop

    $snapscreated += $snapshotNameData
    
    Write-Output "VM $($vm.name) data Disk $($datadisk.Name) Snapshot End"   
    Write-Output "====================================="
}

Write-Output "VM $($vm.name) Data Disk Snapshots End" 

#List created snaps

Write-Output "List of Snaps created for VM $($vm.name) : -"
$snapscreated
Write-Output "====================================="
