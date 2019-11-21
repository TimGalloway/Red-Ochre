<#
Backup the IIS server
  Allow selective inetpub folders to be backedup
Backup the IIS config
Backup the SQL Server
Compress the files
Copy to DropBox Folder
  Allow only keep given number of days of backups

ToDo: Backup MySql databases
      

Need to run as Administrator
Need to have modules installed
  Install-Module -Name SqlServer

Parameters:
	backupaction = "Log" or "Database"
#>
# General Settings
$backuproot = "c:\backup"
$dropboxpath = "C:\Users\Tim\Google Drive\Projects\Red Ochre\Backup\Dropbox"
$numdays = "1"

# IIS Settings
$iispath = "C:\inetpub"
$inetpubdirs= "atomglobal.com.au","globalrio.redochre.cloud","wwwroot\aspnet_client"
#$inetpubdirs= "*"

# MSSQL Settings
$sqlServerInstance = "."

# MySQL Settings
$mysqlpath = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
$mysqlconfig = "C:\source\Red Ochre\Backup\my.cnf"
$mysqldatabases = "sakila", "world"




# End of user settings
$backuptype = $Args[0]
$backuptemp = "$backuproot\temp"
$zippath = "$backuproot\zips"
$backupfolder = "$(get-date -f dd-MM-yyyy_HH_mm_ss) - $backuptype"

if (Test-Path $backuptemp){
    # folder exists
    # remove folders older than number of given days
    Get-ChildItem -Path "$backuptemp" | Where CreationTime -lt (Get-Date).AddDays(-$numdays) | Remove-Item -Force -Recurse
}else{
    # file with path $path doesn't exist
    New-Item $backuptemp -ItemType Directory
}

if(Test-Path $zippath){
    # folder exists
    # remove folders older than number of given days
    Get-ChildItem -Path "$zippath" | Where CreationTime -lt (Get-Date).AddDays(-$numdays) | Remove-Item -Force -Recurse
}else{
    # file with path $path doesn't exist
    New-Item $zippath -ItemType Directory
}
Set-Location $backuptemp

New-Item $backupfolder -ItemType Directory
Set-Location $backupfolder

if ($backuptype -eq "Database"){
    # Backup the IIS files
    New-Item "iis" -ItemType Directory
    foreach ($dir in $inetpubdirs){
    	Copy-Item -Path $iispath\$dir -Destination $backuptemp\$backupfolder\iis\$dir -Recurse
    }

    # Backup the IIS config
    New-Item "config" -ItemType Directory
    Set-Location $backuptemp\$backupfolder\config
    Backup-WebConfiguration -Name $backupfolder
    Copy-Item -Path C:\WINDOWS\System32\inetsrv\backup\$backupfolder -Destination $backuptemp\$backupfolder\config -Recurse
}

<# Backup All Databases and give them all a file name which
    includes the name of the database & datetime stamp. #> 
Set-Location $backuptemp\$backupfolder
New-Item "db" -ItemType Directory
Set-Location $backuptemp\$backupfolder\db
Get-SqlDatabase -ServerInstance $sqlServerInstance | Where { $_.Name -ne 'tempdb' } | foreach{ Backup-SqlDatabase -DatabaseObject $_ -CompressionOption Off -BackupContainer "$backuptemp\$backupfolder\db" -BackupFile "$($_.NAME)_db.bak" -BackupAction $backuptype}

# Backup all noted MySQL databases
Set-Location $backuptemp\$backupfolder
New-Item "mysqldb" -ItemType Directory
Set-Location $mysqlpath
foreach ($mysqldb in $mysqldatabases){
    cmd /c mysqldump -h localhost -u root -ptl1000 $mysqldb > $backuptemp\$backupfolder\mysqldb\$mysqldb.sql
}

# Compress the folder
Compress-Archive -Path $backuptemp\$backupfolder -DestinationPath $zippath\$backupfolder.zip
Copy-Item -Path $zippath\$backupfolder.zip -Destination $dropboxpath\$backupfolder.zip

Set-Location $backuproot