#===========================================================================
# PARAMETERS 
#===========================================================================

param(
	[Parameter(Mandatory=$true)]
   [string]$vcenter_url,
   [Parameter(Mandatory=$true)]
   [string]$vcenter_username,
   [Parameter(Mandatory=$true)]
   [string]$vcenter_password,
   [Parameter(Mandatory=$true)]
   [string]$vcloud_portal_name   
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

# CHECK FOR THE BACKUPS FOLDER AND CREATE IF IT DOES NOT EXIST
$test = Test-Path .\BACKUPS
if($test -eq $false){
   Write-Host "Creating backups folder...."
   New-Item -ItemType Directory -Name backups | Out-Null
}
else{
   Write-Host "Backups folder checked..."
}

# START SCRIPT TRANSCRIPTION
Write-Host "Starting transcript..."
Start-Transcript -Path $transcript_path | Out-Null


#===========================================================================
# DELETION 
#===========================================================================

# PROMPT TO CLOSE THE SHELL
Read-Host -Prompt "Press any key to exit..."
exit