# Configuration
$Domaine = "DC=h4sh,DC=local"
$RacineNom = "H4SH_ENTREPRISE"
$RacineOU = "OU=$RacineNom,$Domaine"
$Password = ConvertTo-SecureString "P@ssword2026!" -AsPlainText -Force
$CsvFile = "C:\Users\Administrateur\Documents\Scripts\utilisateurs.csv"

# 1. Création de la Racine si inexistante
if (!(Get-ADOrganizationalUnit -Filter "Name -eq '$RacineNom'")) {
    New-ADOrganizationalUnit -Name $RacineNom -Path $Domaine
}

# Importation
$Users = Import-Csv $CsvFile

ForEach ($User in $Users) {
    # Variables
    $Pays = $User.Pays
    $Ville = $User.Ville
    $Service = $User.Service
    $Prenom = $User.Prenom
    $Nom = $User.Nom
    $SamAccountName = ($Prenom.Substring(0,1) + $Nom).ToLower()
    $UPN = "$SamAccountName@h4sh.local"
    
    # --- GESTION DES OUs ---
    # Niveau 1 : Pays
    $OUPaysDN = "OU=$Pays,$RacineOU"
    if (!(Get-ADOrganizationalUnit -Filter "Name -eq '$Pays'" -SearchBase $RacineOU)) {
        New-ADOrganizationalUnit -Name $Pays -Path $RacineOU
        Write-Host " [+] Pays '$Pays' créé." -ForegroundColor Yellow
    }
    
    # Niveau 2 : Ville
    $OUVilleDN = "OU=$Ville,$OUPaysDN"
    if (!(Get-ADOrganizationalUnit -Filter "Name -eq '$Ville'" -SearchBase $OUPaysDN)) {
        New-ADOrganizationalUnit -Name $Ville -Path $OUPaysDN
        Write-Host "   [+] Ville '$Ville' créée." -ForegroundColor Yellow
    }
    
    # Niveau 3 : Service
    $OUServiceDN = "OU=$Service,$OUVilleDN"
    if (!(Get-ADOrganizationalUnit -Filter "Name -eq '$Service'" -SearchBase $OUVilleDN)) {
        New-ADOrganizationalUnit -Name $Service -Path $OUVilleDN
        Write-Host "     [+] Service '$Service' créé dans $Ville." -ForegroundColor Yellow
    }
    
    # --- GESTION DES GROUPES ---
    # Groupe Global (ex: GG_RH)
    $GroupGlobal = "GG_$Service"
    # Groupe Local (ex: GG_PARIS_RH)
    $GroupLocal = "GG_" + $Ville + "_" + $Service
    
    # Création des groupes s'ils n'existent pas
    if (!(Get-ADGroup -Filter "Name -eq '$GroupGlobal'")) {
        New-ADGroup -Name $GroupGlobal -GroupScope Global -Path $OUServiceDN
    }
    if (!(Get-ADGroup -Filter "Name -eq '$GroupLocal'")) {
        New-ADGroup -Name $GroupLocal -GroupScope Global -Path $OUServiceDN
    }
    
    # --- CRÉATION USER ---
    Try {
        # Vérif si user existe déjà
        if (!(Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'")) {
            New-ADUser -Name "$Prenom $Nom" `
                       -GivenName $Prenom `
                       -Surname $Nom `
                       -SamAccountName $SamAccountName `
                       -UserPrincipalName $UPN `
                       -Path $OUServiceDN `
                       -AccountPassword $Password `
                       -Enabled $true `
                       -ChangePasswordAtLogon $true `
                       -Description "$Service - $Ville ($Pays)"
            
            # Ajout aux groupes
            Add-ADGroupMember -Identity $GroupGlobal -Members $SamAccountName
            Add-ADGroupMember -Identity $GroupLocal -Members $SamAccountName
            Write-Host " [OK] $SamAccountName ($Ville) créé + ajouté aux groupes." -ForegroundColor Green
        }
        else {
            Write-Host " [!] $SamAccountName existe déjà." -ForegroundColor DarkGray
        }
    }
    Catch {
        Write-Host " [X] Erreur pour $SamAccountName : $_" -ForegroundColor Red
    }
}

Write-Host "`n=== IMPORT TERMINÉ ===" -ForegroundColor Cyan
