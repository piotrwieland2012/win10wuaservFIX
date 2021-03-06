##
## Windows 10 cleanup script.
## Remove dodgy tracking settings, unneeded services, all apps, and optional features that come with Windows 10. Make it more like Windows 7.
## NOTE: this was tested on Creators Update (1703) and Fall Creators Update (1709). Some of this may not work as expected on newer versions.
##
## Instructions
##  1. Run this script (under Powershell as Administrator):
##     powershell -ExectionPolicy Bypass .\cleanup-win10.ps1
##  2. Let it run through, you may see a few errors, this is normal
##  3. Reboot
##     shutdown /r /t 0
##  5. Done!
##
## After using this script, I would recommend running O&O Shutup.
## You can find it here: https://www.oo-software.com/en/shutup10
##

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

Write-Host 'Updating registry settings...'

# Disable some of the "new" features of Windows 10, such as forcibly installing apps you don't want, and the new annoying animation for first time login.
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\' -Name 'CloudContent'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -PropertyType DWord -Value '1' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -PropertyType DWord -Value '1' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableFirstLogonAnimation' -PropertyType DWord -Value '0' -Force

# Set some commonly changed settings for the current user. The interesting one here is "NoTileApplicationNotification" which disables a bunch of start menu tiles.
New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\' -Name 'PushNotifications'
New-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'NoTileApplicationNotification' -PropertyType DWord -Value '1' -Force
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\' -Name 'CabinetState'
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState' -Name 'FullPath' -PropertyType DWord -Value '1' -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -PropertyType DWord -Value '0' -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -PropertyType DWord -Value '1' -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -PropertyType DWord -Value '0' -Force

# Remove all Windows 10 apps, except the Windows Store
Get-AppxProvisionedPackage –Online | Where-Object {$_.packagename –NotLike "*store*"} | Remove-AppxProvisionedPackage -Online 
Get-AppxPackage -AllUsers | Where-Object {$_.name –NotLike "*store*"} | Remove-AppxPackage

# Disable Cortana, and disable any kind of web search or location settings.
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\' -Name 'Windows Search'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -PropertyType DWord -Value '0' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowSearchToUseLocation' -PropertyType DWord -Value '0' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableWebSearch' -PropertyType DWord -Value '1' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWeb' -PropertyType DWord -Value '0' -Force

# Remove OneDrive, and stop it from showing in Explorer side menu.
C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall
Remove-Item -Path 'HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Recurse
Remove-Item -Path 'HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Recurse

# Disable data collection and telemetry settings.
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'SmartScreenEnabled' -PropertyType String -Value 'Off' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -PropertyType DWord -Value '0' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -PropertyType DWord -Value '0' -Force

# Disable Windows Defender submission of samples and reporting.
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\' -Name 'Spynet'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -Name 'SpynetReporting' -PropertyType DWord -Value '0' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -Name 'SubmitSamplesConsent' -PropertyType DWord -Value '2' -Force

# Ensure updates are downloaded from Microsoft instead of other computers on the internet.
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\' -Name 'DeliveryOptimization'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -PropertyType DWord -Value '0' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'SystemSettingsDownloadMode' -PropertyType DWord -Value '0' -Force
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\' -Name 'Config'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -PropertyType DWord -Value '0' -Force

Write-Host 'Disabling services...'
$services = @(
    # See https://virtualfeller.com/2017/04/25/optimize-vdi-windows-10-services-original-anniversary-and-creator-updates/

    # Connected User Experiences and Telemetry
    'DiagTrack',

    # Data Usage service
    'DusmSvc',

    # Peer-to-peer updates
    'DoSvc',

    # AllJoyn Router Service (IoT)
    'AJRouter',

    # SSDP Discovery (UPnP)
    'SSDPSRV',
    'upnphost',

    # Superfetch
    'SysMain',

    # http://www.csoonline.com/article/3106076/data-protection/disable-wpad-now-or-have-your-accounts-and-private-data-compromised.html
    'iphlpsvc',
    'WinHttpAutoProxySvc',

    # Black Viper 'Safe for DESKTOP' services.
    # See http://www.blackviper.com/service-configurations/black-vipers-windows-10-service-configurations/
    'tzautoupdate',
    'AppVClient',
    'RemoteRegistry',
    'RemoteAccess',
    'shpamsvc',
    'SCardSvr',
    'UevAgentService',
    'ALG',
    'PeerDistSvc',
    'NfsClnt',
    'dmwappushservice',
    'MapsBroker',
    'lfsvc',
    'HvHost',
    'vmickvpexchange',
    'vmicguestinterface',
    'vmicshutdown',
    'vmicheartbeat',
    'vmicvmsession',
    'vmicrdv',
    'vmictimesync',
    'vmicvss',
    'irmon',
    'SharedAccess',
    'MSiSCSI',
    'SmsRouter',
    'CscService',
    'SEMgrSvc',
    'PhoneSvc',
    'RpcLocator',
    'RetailDemo',
    'SensorDataService',
    'SensrSvc',
    'SensorService',
    'ScDeviceEnum',
    'SCPolicySvc',
    'SNMPTRAP',
    'TabletInputService',
    'WFDSConSvc',
    'FrameServer',
    'wisvc',
    'icssvc',
    'WinRM',
    'WwanSvc',
    'XblAuthManager',
    'XblGameSave',
    'XboxNetApiSvc'
)
foreach ($service in $services) {
    Set-Service $service -StartupType Disabled
}

Write-Host 'Disabling hibernate...'
powercfg -h off

# Disables all of the known enabled-by-default optional features. There are some particulary bad defaults like SMB1. Sigh.
Write-Host 'Disabling optional features...'
$features = @(
    'MediaPlayback',
    'SMB1Protocol',
    'Xps-Foundation-Xps-Viewer',
    'WorkFolders-Client',
    'WCF-Services45',
    'NetFx4-AdvSrvs',
    'Printing-Foundation-Features',
    'Printing-PrintToPDFServices-Features',
    'Printing-XPSServices-Features',
    'MSRDC-Infrastructure',
    'MicrosoftWindowsPowerShellV2Root',
    'Internet-Explorer-Optional-amd64'
)
foreach ($feature in $features) {
    Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
}
# SIG # Begin signature block
# MIIDygYJKoZIhvcNAQcCoIIDuzCCA7cCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYY3tJ3g5e98lyOKSnvpTXoVH
# suGgggHxMIIB7TCCAVagAwIBAgIQG9tKcwAcsadHfRooy+0DhTANBgkqhkiG9w0B
# AQsFADA1MTMwMQYDVQQDHioARABFAFMASwBUAE8AUAAtADYASgBKAEIAOAA5ADEA
# XABwAGkAbwB0AHIwHhcNMjAwOTIxMTYxOTMxWhcNMjEwOTIxMjIxOTMxWjA1MTMw
# MQYDVQQDHioARABFAFMASwBUAE8AUAAtADYASgBKAEIAOAA5ADEAXABwAGkAbwB0
# AHIwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAJhb2T11WUdI2LeFU2CZaDud
# PJJwuxE95BmPCZFzHHYBsSCHHLyPZ/duQL8+qg0DjecniQAQ/ZJ6dPnULh1ALkaH
# S+6DEbecV42COcWKVJ+79dR+2H2rArs5qKxPxNXWCIBD4aiQFAt0L3u18thJnJkl
# A0x/jOCtiNuvz7z3LZyxAgMBAAEwDQYJKoZIhvcNAQELBQADgYEAIRZwRMmFmUYB
# uHYpk288ekNXSI5PQ3Sib6JNN3aa1xkaEARO1eq89NDkvHuJFOgU9A1m5FUxdkWK
# pgpUVsaqlBdDNmmje+V8ZB3Iwks1Y9awa99UATZDZsNfrPZZapGuNM3PO8CqZmYu
# nIKM+N8gVEvqaXUUkGUNY6ZBcyJFASoxggFDMIIBPwIBATBJMDUxMzAxBgNVBAMe
# KgBEAEUAUwBLAFQATwBQAC0ANgBKAEoAQgA4ADkAMQBcAHAAaQBvAHQAcgIQG9tK
# cwAcsadHfRooy+0DhTAJBgUrDgMCGgUAoFIwEAYKKwYBBAGCNwIBDDECMAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwIwYJKoZIhvcNAQkEMRYEFCEoixFSkATI
# BKVE8O3d8+eo3ynFMA0GCSqGSIb3DQEBAQUABIGABP/MpOB9t8iv2wqjRQfv3xGE
# 8TG7Gy2LGOvxWjHpRqucVjvTH8VmQ6kvA0CaRFWGei/szhHAVxhNO62MqdFrnG1L
# 2nTaKbFl7lFHR53j2LMJenGSHf8HEJrWiiK53nSDYLOrh2lWdGObLg8eT+WNriPH
# QGBTw8tbEx1Zy8xe/ms=
# SIG # End signature block
