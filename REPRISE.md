
## Choix fonctionnel / projet

- J'ai rejeté les codes REVENDEURS, ils sont pas integrés dans la BDD (j'aurais pu creer un nouveau code en base, mais pour moi si l'existant existe c'est pour une raison, débat possible)
- J'ai consideré que Inutilisable correspondait à !active
- J'ai consideré qu'un pays absent c'était NULL meme si c'etait la France. pour pas risquer de creer des fausses données. Du coup le code postal est pas bien corrigé pour ses lignes
- j'ai corrigé les telephones francais
- Emails qui ne respectent pas le regex ne sont pas importées (cependant la ligne oui)


## Choix techniques

- Forcer pour le moment le nom de l'onglet, pour eviter de lire les pages avec leur index.
- En ce qui concerne la casse, j'ai respecté la casse partout sauf les colonnes ou y'a pas d'interet et un risque d'erreur







