#===========================================================================
# PARAMETERS 
#===========================================================================

param(
	[Parameter(Mandatory=$true)]
   [string]$vcenter_url,
   [Parameter(Mandatory=$true)]
   [string]$vcenter_username,
   [Parameter(Mandatory=$true)]
   [string]$vcenter_password
)

#===========================================================================
# VARIABLES 
#===========================================================================

$current_date = Get-Date -Format ("MM-dd-yyyy_h.mm.ss")
$transcript_path = ".\transcripts\configure_vcloud" + $current_date + ".txt"

#===========================================================================
# VALIDATION 
#===========================================================================

# CHECK FOR TRANSCRIPTS FOLDER AND CREATE IF IT DOES NOT EXIST
$test = Test-Path .\transcripts
if($test -eq $false){
    Write-Host "Creating transcripts folder...."
    New-Item -ItemType Directory -Name transcripts | Out-Null
}
else{
    Write-Host "Transcripts folder checked..."
}

# START SCRIPT TRANSCRIPTION
Write-Host "Starting transcript..."
Start-Transcript -Path $transcript_path | Out-Null

# CHECK FOR .CSV FILE, CREATE TEMPLATE CSV FILE IF NONE EXISTS
$check = test-path .\datastores.csv
if($check){
   Write-Host "datastores.csv file exists..."
}
else{
   Write-Host "datastores.csv file does not exist..."
   Write-Host "Creating template file..."
   $template_content = @{
      datastore_name = 'datstore01'
      device_id = 'naa.60003ff44dc75adcb64c7dbcbeadbf8e'
   }
   New-Object psobject -Property $template_content | Export-Csv -Path .\datastores.csv -NoTypeInformation -NoClobber | Out-Null
   Write-Host "Use the provided csv file to list all datastores needing to be removed then rerun this application..." -ForegroundColor Yellow
   Read-Host -Prompt "Press any key to exit..."
   exit
}

# CHECK FOR POWERCLI MODULE 
if (Get-Module -ListAvailable -Name VMware.PowerCLI) {
   Write-Host "Powercli module exists..."
} 
else {
   Write-Host "Installing Powercli module..."
   Install-Module -Name VMware.PowerCLI -RequiredVersion 11.1.0.11289667 -Force
   Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
   Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
}

# CONNECT TO VCENTER
try {
   Write-Host "Connecting to vCenter..."
   Connect-VIServer $vcenter_url -User $vcenter_username -Password $vcenter_password -ErrorAction stop | out-null
}
catch {
   Write-Host "ERROR: Connecting to vCenter..."
   Write-Host $PSItem.exception.message -ForegroundColor RED
   Read-Host -Prompt "Press any key to exit..."
   exit
}

# CHECK DATSTORES FOR READINESS
Write-Host ""
Write-Host "################################"
Write-Host "CHECKING DATASTORES FOR REMOVAL REDINESS..."
Write-Host "################################"
Write-Host ""
$datastores = Import-Csv -Path .\datastores.csv
$error_count = 0
foreach($datastore in $datastores){
   # CHECK DATASTORE NAME EXISTS
   if(Get-Datastore -Name $datastore.datastore_name -ErrorAction SilentlyContinue){
      Write-Host "Datatore name" $datastore.datastore_name -NoNewline
      write-host "   PASSED" -ForegroundColor Green
   }
   else {
      Write-Host "Datatore name" $datastore.datastore_name -NoNewline
      write-host "   FAILED" -ForegroundColor Red
      $error_count += 1
   }

   # CHECK BACK DEVICE EXISTS
   if((Get-Datastore -Name $datastore.datastore_name -ErrorAction SilentlyContinue | Get-ScsiLun -ErrorAction SilentlyContinue).CanonicalName -eq $datastore.device_id){
      Write-Host "Datatore device id" $datastore.datastore_name -NoNewline
      write-host "   PASSED" -ForegroundColor Green
   }
   else {
      Write-Host "Datatore device id" $datastore.datastore_name -NoNewline
      write-host "   FAILED" -ForegroundColor Red
      $error_count += 1
   }

   #CHECK IF VMS EXIST ON DATASTORE
   if($null -eq (Get-Datastore -Name $datastore.datastore_name -ErrorAction SilentlyContinue | get-vm -ErrorAction SilentlyContinue)){
      Write-Host "No VMs on" $datastore.datastore_name -NoNewline
      write-host "   PASSED" -ForegroundColor Green
   }
   else {
      Write-Host "No VMs on" $datastore.datastore_name -NoNewline
      write-host "   FAILED" -ForegroundColor Red
      $error_count += 1
   }

   #CHECK IF TEMPLATES EXIST ON DATASTORE
   if($null -eq (Get-Datastore -Name $datastore.datastore_name -ErrorAction SilentlyContinue | Get-Template -ErrorAction SilentlyContinue)){
      Write-Host "No Template VMs" $datastore.datastore_name -NoNewline
      write-host "   PASSED" -ForegroundColor Green
   }
   else {
      Write-Host "No Template VMs" $datastore.datastore_name -NoNewline
      write-host "   FAILED" -ForegroundColor Red
      $error_count += 1
   }  
   
   #CHECK IF DATASTORE IS IN A DATASTORE CLUSTER
   if($null -eq (Get-DatastoreCluster -ErrorAction SilentlyContinue | Get-Datastore -Name $datastore.datastore_name -ErrorAction SilentlyContinue)){
      Write-Host $datastore.datastore_name "not a member of datastore cluster" -NoNewline
      write-host "   PASSED" -ForegroundColor Green
   }
   else {
      Write-Host $datastore.datastore_name "not a member of datastore cluster" -NoNewline
      write-host "   FAILED" -ForegroundColor Red
      $error_count += 1
   }   
   write-host ""
}

if($error_count -ne 0){
   Write-Host "Not all tests passed. Please correct errors and rerun..." -ForegroundColor RED
   Read-Host -Prompt "Press any key to exit..."
   exit
}

Write-Host "################################"
Write-Host "DATASTORES READY FOR REMOVAL..."
Write-Host "################################"
$datastores | Format-Table

$choice = Read-Host -Prompt "Do you want to proceed with removal? (y/N)"
if($choice.ToUpper() -ne "Y"){
   Read-Host -Prompt "Press any key to exit..."
   Exit
}
else{
   Write-Host "Changes Confirmed..."
   Start-Sleep -Seconds 3
}

#===========================================================================
# DELETION 
#===========================================================================

$esxi_hosts = Get-VMHost
foreach($esxi_host in $esxi_hosts){
   foreach($datastore in $datastores){
      if($null -ne ($esxi_host | Get-Datastore)){ 
         Write-Host "Gathering UUID info..."
         $vmfs_uuid = (Get-Datastore $datastore.datastore_name).ExtensionData.info.Vmfs.uuid
         $lun_uuid = (Get-Datastore $datastore.datastore_name | Get-ScsiLun).ExtensionData.uuid
         $host_storage_system = Get-View $esxi_host.Extensiondata.ConfigManager.StorageSystem

         Write-Host "Unmounting" $datastore.datastore_name "from host $esxi_host..."
         $host_storage_system.UnmountVmfsVolume($vmfs_uuid) | Out-Null

         Write-Host "Detatching" $datastore.datastore_name "from host $esxi_host..."
         $host_storage_system.DetachScsiLun($lun_uuid) | Out-Null

         Write-Host "Rescanning storage on host $esxi_host..."
         $esxi_host | Get-VMHostStorage -RescanAllHba -RescanVmfs | Out-Null
      }
   }   
}
write-host "Removals COMPLETE..."
write-host ""

# DISCONNECT FROM VCENTER
Write-Host "Disconnecting from vCenter..."
disconnect-viserver -Confirm:$false

# PROMPT TO CLOSE THE SHELL
Read-Host -Prompt "Press any key to exit..."
exit
