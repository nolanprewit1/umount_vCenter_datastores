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


#===========================================================================
# DELETION 
#===========================================================================

# PROMPT TO CLOSE THE SHELL
Read-Host -Prompt "Press any key to exit..."
exit
