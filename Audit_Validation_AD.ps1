#========================================================================================
# Fabien POLLY
# Cr�ation le: 01/03/21
# But : Automatiser les demandes d'approbations/validations d'acc�s aupr�s des responsables de groupes AD
#========================================================================================
#
# Importation du module ActiveDirectory PowerShell 
Import-Module ActiveDirectory
#
# Variable pour contenir les noms des groupes AD � auditer.
# Definir comme ceci: "<GROUPNAME>," ... sans virgule  apr�s la derni�re entr�e
$GroupsToAudit =  @(
                "<GROUPNAME1>",
                "<GROUPNAME2>",
                "<GROUPNAME3>"
                    )
# Initialisation de la variable $SentTo
$SentTo = @() 
# Loop sur la variable des groupes AD
foreach ($Grp in $GroupsToAudit)
    {   # Variable pour contenir les noms des membres 
        $Identities = @()
        # Obtenir les membres des groupes AD 
        $GroupObj = Get-ADGroupMember $Grp
            # Ajoute les membres  � la variable.
            foreach($member in $GroupObj)
            {
                # Obtenir le nom du membre/PB
                $Identity = $member.name
                
                # Creer les variable des Noms et pr�noms et les concat�ner 
                $FirstName = ((Get-Aduser $Identity -Properties GivenName).GivenName)
                $LastName = ((Get-Aduser $Identity -Properties sn).sn)
                $FirstAndLast = $Firstname + " " + $LastName
                # Ajoute la concat�nation dans une nouvelle variable
                $Identities += $FirstAndLast
            }

        # Compte le nombre de compte dans la variable et formate pour en avoir un par ligne
        $count = $GroupObj.Count
        $ftIdentities = $Identities -join "`n"
    
        # Obtient l'adresse email du compte du responsable
        # Recherche par le nom d'objet "ManagedBy"
         $MgrDNObj = (get-adgroup $Grp -Properties managedby)
         # Stockage de la valeur  en temps que string
         $Mgr = $MgrDNObj.managedby
         # Recherche de l'adresse email avec le "distingiushed name"
         $MgrEmailObj = (Get-ADUser $Mgr -Properties EmailAddress)
         # Stockage de cette valeur en tant que string
         $MgrEmail = $MgrEmailObj.EmailAddress
         # Recherche du Nom et Pr�nom du responsable
         $MgrFirstName = ((Get-Aduser $Mgr -Properties GivenName).GivenName)
         $MgrLastName = ((Get-Aduser $Mgr -Properties sn).sn)
         # Garde une trace de qui a �t� notifi� par Email
         $SentTo += "$MgrFirstname $MgrLastName pour le groupe $Grp. Nombre de comptes utilisateurs = $count.`n"

         #########
         ## Envoie un email � chaque responsable
         ##########
             Send-MailMessage `
             -From "<Adresse>@<Definir>.com" `
             -To $MgrEmail `
             -Subject "Merci de valider les membre du groupe" `
             -SmtpServer "<NOM SERVEUR SMTP>" `
             -Body "Bonjour $MgrFirstName, `n
             En tant que responsable des membres de ce groupe $Grp,  Merci de v�rifier que les membres suivants doivent toujours appartenir � ce groupe. `n
             Le groupe $Grp contient $($count) utilisateurs. Voici leurs noms et pr�noms. `n$($ftIdentities) `n
             Merci de r�pondre et de confirmer si ces informations sont correct ou si il est n�c�ssaire de faire des corrections."
     }

 #########
 ## Envoie d'un email r�capitulatif pour le suivi
 ##########
 Send-MailMessage `
 -From "<Adresse>@<Definir>.com" `
 -To "<Adresse2>@<Definir>.com" `
 -Subject "E-mail de validation des membres des groupes envoy�" `
 -SmtpServer "<NOM SERVEUR SMTP>" `
 -Body "E-mail de validation envoy� aux responsables suivants. `n
 $SentTo"