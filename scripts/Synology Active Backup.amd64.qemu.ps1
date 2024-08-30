# This script is for building a Windows 11 PE environment
#
# Some modifications will be needed for different versions of
# windows.
param (
    [string] $PeDir = "C:\winpe"
)

function DownloadFile {
    param (
        [string] $Url,
        [string] $Hash,
        [string] $DestinationPath
    )

    Invoke-WebRequest $Url -OutFile $DestinationPath
    if ((Get-FileHash -Path $DestinationPath -Algorithm SHA256).Hash -ne $Hash) {
        Write-Error "$Url did not match previous hash`nPrevious: $Hash"
        Exit
    }
}

$MountDir = "$PeDir\mount\"
$ADKPath = "${Env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
$ADKPathPE = "$ADKPath\Windows Preinstallation Environment"
$CabNames = @(
    'Dot3Svc',
    'EnhancedStorage',
    'MDAC',
    'NetFx',
    'PowerShell',
    'Scripting',
    'SecureBootCmdlets',
    'WinPE-WMI',
    'StorageWMI',
    'PmemCmdlets',
    'DismCmdlets',
    'SecureStartup',
    'PlatformId'
)

if (-not (Test-Path -Path "$ADKPath" -PathType Container)) {
    Write-Error "ADK is missing! Install from https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install"
    Exit
}

if (-not (Test-Path -Path "$ADKPathPE" -PathType Container)) {
    Write-Error "ADK PE extension is missing! Install from https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install"
    Exit
}

DownloadFile -Url "https://global.synologydownload.com/download/Utility/ActiveBackupforRecoveryTool/2.7.0-3221/Windows/x86_64/Synology%20Recovery%20Tool-x64-2.7.0-3221.zip" `
 -Hash "FB7084D6BC6C4DDB19719EEE01DCAAAA419ADBB77D3E90FC8BFF1BE0E63840ED" `
 -DestinationPath "Synology Recovery Tool.zip"

DownloadFile -Url "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.262-2/virtio-win-0.1.262.iso" `
 -Hash "956405ECF9CE8BF604F931217F0F29988331AC71C5F830FFE93046BB7A7FAFE7" `
 -DestinationPath "virtio-win.iso"

# Copy the WinPE environment to $PeDir
cmd.exe /C "cd `"${Env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools`" && DandISetEnv.bat && copype.cmd amd64 $PeDir"

# Mount the Windows Image
Dism.exe /Mount-Wim /WimFile:"$PeDir\media\sources\boot.wim" /index:1 /MountDir:"$PeDir\mount"

# Set the timezone
Dism.exe /Image:"$PeDir\mount" /Set-TimeZone:"$(tzutil.exe /g)"

# Get Installed Features, this is handy if you're modifing it in the future
$InstallFeatures = Get-WindowsPackage -Path $MountDir | Where-Object { $_.PackageName -notmatch "en-US" }

# I'm not sure if this is required.
# Start Adding Features
foreach ($CabName in $CabNames){
    Write-Host "Starting $CabName" -ForegroundColor Green

    $Installed = $InstallFeatures | ? { $_.PackageName -match $CabName }

    if ($Installed.PackageState -eq "Installed") {
        Write-Output " Already Installed"
    } else {
        $WorkingCab = $null
        $WorkingCabEnUs = $null

        $WorkingCab = Get-ChildItem -Path "$ADKPathPE\AMD64\WinPE_OCs" -Filter *.cab `
          | Where-Object { $_.Name -match $CabName }
        
        if ($WorkingCab) {
            Add-WindowsPackage -Path $MountDir -PackagePath $WorkingCab.FullName -Verbose
        }
        
        $WorkingCabEnUs = Get-ChildItem -Path "$ADKPathPE\AMD64\WinPE_OCs\en-us" -Filter *.cab `
          | ? { $_.Name -match $CabName }

        if ($WorkingCabEnUs) {
            Add-WindowsPackage -Path $MountDir -PackagePath $workingcabenus.FullName -Verbose
        }
    }
}

# Mount virtio drivers
$VirtIoDisk = Mount-DiskImage virtio-win-0.1.262.iso -NoDriveLetter -PassThru
Get-ChildItem $VirtIoDisk.DevicePath -Recurse -Filter "w11" | % {
    Add-WindowsDriver -Path $PeDir\mount -Driver "$($_.FullName)\" -ForceUnsigned -Recurse
}
Dismount-DiskImage -DevicePath $VirtIoDisk.DevicePath

mkdir "$PeDir\mount\ActiveBackup"

## Extract files from Synology Recovery Tool to $PeDir\mount\ActiveBackup
Expand-Archive -Path 'Synology Recovery Tool.zip' -DestinationPath "$PeDir\mount\ActiveBackup"
"[LaunchApps]
%systemroot%\System32\wpeinit.exe
%systemdrive%\ActiveBackup\ui\recovery.exe" > "$PeDir\mount\Windows\system32\winpeshl.ini"

Dism.exe /Unmount-Wim /MountDir:"$PeDir\mount" /COMMIT

cmd.exe /C "cd `"${Env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools`" && DandISetEnv.bat && MakeWinPEMedia /ISO $PeDir $PeDir\synology_recovery_virtio_amd64-winpe.iso"

