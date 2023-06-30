#####################################################
#                                                   #
#   Provider ESX pour Terrashell : Alpha 0.01       #
#                                                   #
#####################################################

#Arguments du scripts : Apply ou Destroy


Param(
    [Parameter(Mandatory=$false)]
    [bool] $Apply,
    [Parameter(Mandatory=$false)]
    [bool] $Destroy,
    [Parameter(Mandatory=$true)]
    [string] $TOMLcopy)

# Import du module PSToml
try {
  Import-Module -Name PSToml -Force   

}
catch {
  $_.Exception.Message
  Read-Host "Appuyez sur une touche pour quitter le script "
  exit 1

}


$convertToml = get-content $TOMLcopy | ConvertFrom-Toml 



#import du module PowerCli

try {
  Install-Module -Name "VMWare.VimAutomation.Core" -Confirm:$false -Force
  
}
catch {
    Write-Error "L'installation du module VMware.PowerCLI a échoué. "
    Write-Host $_.Exception.Message
    Read-Host "Appuyez sur une touche pour quitter le script "
    exit 2

}

#Acceptation des EULA

Set-PowerCLIConfiguration -ParticipateInCeip:$false -InvalidCertificateAction Ignore

#Connexion à l'ESX

$ESXHost = $convertToml.provider.esxi.esxi_hostname
$ESXRoot = $convertToml.provider.esxi.esxi_username
$ESXPasswd = $convertToml.provider.esxi.esxi_password | ConvertTo-SecureString -AsPlainText 
$ESXcred = New-Object System.Management.Automation.PSCredential ($ESXRoot, $ESXPasswd)

#Paramètres de la VM

$VMSource = $convertToml.resource.esxi_guest.ovf_source
$VMDatastore = $convertToml.resource.esxi_guest.disk_store
$VMName = $convertToml.resource.esxi_guest.guest_name
$VMNetwork = $convertToml.resource.esxi_guest.network_interfaces.virtual_network
$VMMemory = $convertToml.resource.esxi_guest.memsize
$VMCPU = $convertToml.resource.esxi_guest.numvcpus
$VMPower = $convertToml.resource.esxi_guest.power
$VMGuestOS = $convertToml.resource.esxi_guest.guestos



#Affichage des modifications



#Applications des modifications
#Bug de PowerCLI : 
#   - Format ova non prit en charge
#   - Barre de progression dans ESX : affichage de la progression variable (peut rester figée à 0%)

Connect-VIServer -Server $ESXHost -Credential $ESXcred 
Import-VApp -Name $VMName -Source $VMSource -VMHost (Get-VMHost -Name $ESXHost) -Datastore $VMDatastore -DiskStorageFormat Thin
Set-VM -VM (Get-VM -Name $VMName) -CoresPerSocket $VMCPU -GuestId $VMGuestOS -MemoryMB $VMMemory -Confirm:$false
Get-VM -Name $VMName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $VMNetwork -StartConnected:$true -Confirm:$false
Disconnect-VIServer -Server $ESXHost -Force
