# 00_parametres.R -- Paramètres communs à la chaîne de traitement
#
# Ce fichier est lu par les scripts qui en ont besoin, avec :
#   source("scripts/00_parametres.R")
# Modifier un paramètre ici le modifie partout.

# Résolution du MNT de travail (m)
taille_px <- 5

# Seuil d'accumulation pour définir le réseau hydrographique (en pixels).
# 30 000 pixels × 25 m² = 0,75 km². Basé sur la densité de drainage des
# tronçons BD TOPAGE 2024, canaux et conduites exclus :
# voir le script 09_calage_reseau.R.
seuil_px  <- 30000
seuil_km2 <- seuil_px * taille_px^2 / 1e6

# Version texte du seuil, avec virgule décimale, pour les légendes de figures
seuil_txt <- format(seuil_km2, decimal.mark = ",")