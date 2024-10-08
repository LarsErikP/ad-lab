# ad-lab
Ymse verktøy for å sette opp MS AD-lab

## Create-HomeShare.ps1
Scriptet oppretter en mappe for hjemmeområder, og setter korrekte rettigheter ([kilde](https://learn.microsoft.com/en-us/archive/blogs/migreene/ntfs-permissions-for-redirected-folders-or-home-directories)) for dette.
Kjøres typisk på filserveren. Filserveren må ha PowerShell-modulen for ActiveDirectory installert.

## Create-ADBaseStructure.ps1
Scriptet oppretter en grunnstruktur i AD som kan være et fint utgangspunkt for en lab. En filserver må være satt opp før man begynner, og det må være satt opp et share for hjemmeområder.
Dette sharet må ha rettigheter iht [denne guiden](https://learn.microsoft.com/en-us/archive/blogs/migreene/ntfs-permissions-for-redirected-folders-or-home-directories).
Hvis du har vært flink, så har du kjørt scriptet over først, og dette er dermed på plass :-)

Scriptet kjøres typisk på en domenekontroller.

Det opprettes en OU-struktur som følger:

* DOMENEROT
  * Brukere
    * Adminbrukere
    * Ansatte
      * HR
      * IT
      * Regnskap
      * Studieadm
    * Studenter
  * Grupper
  * Klienter
    * Ansatte
    * Studenter
  * Servere
    * DHCP
    * Fil
    * Print

I tillegg opprettes:
* En bunke brukere. Én per type ansatt, og to studenter. Med tilhørende hjemmeområde på filserver.
* En admin-konto og en klientadmin-konto
* En bunke grupper som korresponderer til type ansatt
* Grupper for hhv server-admin, klient-admin og filshare-admin
* En bunke grupper som er tiltenkt rettigheter til diverse filshare
* Fornuftige gruppemedlemskap på alle opprettede brukere

## Openstack Heat
Repoet inneholder også en Openstack HOT for å opprette VMene og nettverket som trengs for å lage en lab med to domenekontrollere, en filserver med tilhørende datavolum og to klienter.
Denne kan startes med
```
openstack stack create -t ad-lab.yaml -e <parameters>.yaml --wait ad-lab
```

Paramter-filen må inneholde minimum
```
---
parameters:
  keypair: NØKKELPARETMITT
  environment: "NOEFINT"
```
Hvor "NOEFINT" er et prefiks på alle ressurser. Typisk bruker man "lab", "demo", "test", "prod", "bacon" e.l her.
