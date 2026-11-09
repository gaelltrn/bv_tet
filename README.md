
# bv_tet

<!-- badges: start -->
<!-- badges: end -->

# Analyse hydrologique réalisée dans le cadre du cours "Hydrosystème de Montagne" du M1 GAED, parcours GEOÏDES

Analyse de la forme, de l'hypsométrie et des pentes du bassin versant
de la Têt (Pyrénées-Orientales), sur le troncon dont l'exutoire est situé à Serdinya. Projet réalisé avec R (terra, sf, whitebox).

## Données utilisées

- **RGE ALTI 1 m, département 66** (IGN, Licence Ouverte Etalab 2.0) :
  archive `RGEALTI_MNT_5M_..._D066_.
- **BD TOPO, réseau hydrographique** (IGN).
- **BD TOPAGE, bassins versants topographiques** (Sandre / OFB / IGN).

L'exutoire, placé manuellement, est fourni dans `data/digitalisation/`.

## Exécution du script 

01_import_mnt.R        mosaïque, CRS, découpage avec marge
02_correction_cuvettes.R   correction des dépressions
03_ecoulement.R        direction D8, accumulation
04_bassin.R            accrochage de l'exutoire, délimitation, polygone
05_validation.R        comparaison avec la BD TOPO et la BD TOPAGE
06_morphometrie.R      forme, hypsométrie, pentes
07_cartes.R            figures et cartes

## Packages

terra, sf, whitebox, ggplot2

