##########################################

#  Fix the Azure disks

##########################################

$RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
if ((get-itemproperty $runoncekey).NextRun -eq $PSCommandPath){
    set-itemproperty $RunOnceKey "NextRun" ("")
}


# set cd to B:
if (!test-path 'B:'){
    Set-WmiInstance -InputObject (Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'E:'") -Arguments @{DriveLetter='B:'} -ErrorAction SilentlyContinue
}

# set pagefile to c:

$CurrentPageFile = Get-WmiObject -Query 'select * from Win32_PageFileSetting'
if ($CurrentPageFile.name.split('/')[0] -eq 'D:'){
    $CurrentPageFile.delete()
    Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name='c:\pagefile.sys';InitialSize = 0; MaximumSize = 0}
    set-itemproperty $RunOnceKey "NextRun" ("C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionPolicy Unrestricted -File $PSCommandPath")
    restart-computer -Force -Confirm:$false
}else{
    Set-WmiInstance -InputObject (Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'D:'") -Arguments @{DriveLetter='T:'} -ErrorAction SilentlyContinue
    Get-Disk | Where-Object partitionstyle -eq 'raw' |`
        Initialize-Disk -PartitionStyle MBR -PassThru |`
        New-Partition -AssignDriveLetter -UseMaximumSize |`
        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'DATA' -Confirm:$false
    $CurrentPageFile.delete()
    Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name='t:\pagefile.sys';InitialSize = 0; MaximumSize = 0}
    restart-computer -Force -Confirm:$false
}

