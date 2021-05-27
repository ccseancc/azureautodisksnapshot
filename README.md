# azureautodisksnapshot
Backup azure disk snapshot by using azure automation

Azure Disk snapshot auto backup Setup

Aim: In Azure China, there’s no auto disk snapshot solution, and disk snapshot need to be taken manually, which is not fit for enterprise backup requirement. An auto disk snapshot backup and housekeeping solution is required, and its main purpose is to backup the disk that are used on AKS.

Setup procedure:

1.	Create resource group that own the resources that related to disk snapahot backup (Storage account, automation account, disk snapshot backup). 

2.	Create storage account that store azure storage table. And tags the storage account with ( aksSnapshotBackupDatabase : tableStorage )

3.	Create an automation account, that contains the create disk snapshot and housekeeping disk snapshot PowerShell runbook.

4.	In automation account, module gallery, seach following module and import it.
Az.account, Az.Compute, Az.Resources, Az.Storage, Aztable
After import, you should see them available in modules

5.	Create two powershell runbook, one for automate disk snapshot, another one is housekeeping disk snapshot, paste the powershell code in it, and publish it
two run books:
CreateDiskSnapshot
HousekeepDiskSnapshot
 
6.	Set schedule for both workbook

7.	For each disk that would like to backup by this snapshot schedule, please add below tag:
aksSnapshotBackupEnabled : true


