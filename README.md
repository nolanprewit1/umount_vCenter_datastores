
# Unmount vCenter Datastores

A simple command line program to check and then unmount datastores in a vCenter environment.

# Requirements

 - vCenter datastore name
 - vCenter device backing id 
	 - Example: naa.60003ff44dc75adcb64c7dbcbeadbf8e

# Script Parameters

 - vcenter_url - (required) - The fqdn or ip address of the vCenter
 - vcenter_username - (required) - vCenter username with appropriate permissions 
 - vcenter_password - (required) - vCenter password with appropriate permissions 

# Using the Script

 1. Run the script to generate the needed datastores.cv template file
 2. Compile the list of all datastores to be removed into the template file
 3. Run the script

**Option 1**

    .\unmount_vCenter_datastores.ps1 -vcenter_url "vCenter.example.local" -vcenter_username "testUser"-vcenter_password "secretPasswordHere"

**Option 2**
	

    .\unmount_vCenter_datastores.ps1

# Directory Structure
```
├── unmount_vCenter_datastores.ps1		# The primary powershell script
├── datastores.csv						# The dastores csv file template
└── README.md		
```