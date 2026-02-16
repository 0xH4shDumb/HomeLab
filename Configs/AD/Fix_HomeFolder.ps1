# --- CONFIGURATION ---
$RacineAD = "OU=H4SH_ENTREPRISE,DC=h4sh,DC=local"  # Ton OU Racine
$ServeurFichiers = "C:\UTILISATEURS"               # Chemin LOCAL sur le serveur
$CheminReseau = "\\DC-H4SH-01\UTILISATEURS"        # Chemin RESEAU (UNC)

# Récupérer tous les utilisateurs (Sauf les admins et comptes spéciaux)
Write-Host "Recherche des utilisateurs dans $RacineAD..." -ForegroundColor Cyan
$Users = Get-ADUser -Filter * -SearchBase $RacineAD -Properties SamAccountName

ForEach ($User in $Users) {
    $Login = $User.SamAccountName
    $DossierUserLocal = "$ServeurFichiers\$Login"
    $DossierUserReseau = "$CheminReseau\$Login"

    Write-Host "Traitement de : $Login" -NoNewline

    # 1. Création du dossier physique s'il n'existe pas
    If (!(Test-Path $DossierUserLocal)) {
        New-Item -Path $DossierUserLocal -ItemType Directory -Force | Out-Null
        Write-Host " [Dossier Créé]" -ForegroundColor Yellow -NoNewline
    }

    # 2. Attribution des droits NTFS (L'utilisateur devient propriétaire + Contrôle Total)
    $Null = icacls $DossierUserLocal /grant "H4SH\$Login`:(OI)(CI)F" /T /Q
    Write-Host " [Droits OK]" -ForegroundColor Green -NoNewline

    # 3. Mise à jour du Profil AD (Lecteur P:)
    try {
        Set-ADUser -Identity $User `
                   -HomeDrive "P:" `
                   -HomeDirectory $DossierUserReseau `
                   -ErrorAction Stop
        Write-Host " [Profil AD OK]" -ForegroundColor Cyan
    }
    catch {
        Write-Host " [Erreur AD]" -ForegroundColor Red
    }
}

Write-Host "--- TERMINE ! Vérifier le dossier C:\UTILISATEURS ---" -ForegroundColor Magenta
