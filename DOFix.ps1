#FIX ERROR "Delivery Optimization: Download of a file saw no progress within the defined period." - WUAHandler.log - Unexpected HRESULT for downloading complete: 0x80d02002

$logpath= (Get-ItemProperty("HKLM:\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties")).$("Local SMS Path")

if(Get-Content "$logpath\logs\WUAHandler.log" -Tail 40 | select-string -pattern "Unexpected HRESULT for downloading complete: 0x80d02002" -quiet){
Rename-Item -path "$logpath\logs\WUAHandler.log" -NewName "WUAHandler-old.log" -force

# Percorso della chiave di registro
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
# Nome del valore REG_SZ
$valueName = "UpdateServiceUrlAlternate"
# Valore atteso
$expectedValue = 'http://localhost:8005'
# Controlla e crea la chiave di registro se necessario
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}
# Crea o aggiorna il valore del registro
Set-ItemProperty -Path $registryPath -Name $valueName -Value $expectedValue -Type String
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization") -ne $true) {  New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -force -ea SilentlyContinue };
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
#pulisci cache
[__comobject]$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
$CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
ForEach ($CacheItem in $CacheInfo) {
    $null = $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))
}
Remove-Item $env:systemroot\SoftwareDistribution\Download  -ErrorAction SilentlyContinue -recurse -force;

#aggiorna posizione
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000024}')
#installa tutto
 ([wmiclass]'ROOT\ccm\ClientSDK:CCM_SoftwareUpdatesManager').InstallUpdates([System.Management.ManagementObject[]] (get-wmiobject -query 'SELECT * FROM CCM_SoftwareUpdate' -namespace 'ROOT\ccm\ClientSDK'))
 
    "RISOLUZIONE ERRORE"
}else{
#installa tutto
([wmiclass]'ROOT\ccm\ClientSDK:CCM_SoftwareUpdatesManager').InstallUpdates([System.Management.ManagementObject[]] (get-wmiobject -query 'SELECT * FROM CCM_SoftwareUpdate' -namespace 'ROOT\ccm\ClientSDK'))
    "ERRORE NON TROVATO"
}