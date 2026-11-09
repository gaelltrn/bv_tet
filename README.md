
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

## Résultats

### Délimitation du bassin

Le bassin est délimité à partir du RGE ALTI agrégé à 5 m, après correction
des cuvettes, avec l'algorithme d'écoulement D8. L'exutoire est placé à la station hydrométrique
**Y0424010 (La Têt à Serdinya [Joncet])**, puis accroché au chenal simulé.

| Contrôle | Résultat |
|---|---|
| Surface calculée | 414,8 km² |
| Surface de référence de la station | 424 km² (écart de −2,2 %) |
| Distance d'accrochage de l'exutoire | 27 m |
| Surface du bassin hors enveloppe BD TOPAGE | 2,0 km² |

Le bassin calculé suit les limites de la BD TOPAGE le long des crêtes,
y compris dans le couloir étroit de la haute Têt, entre le Capcir (Aude)
et la Cerdagne (Sègre). Les écarts correspondent à la partie aval de la
zone BD TOPAGE de Serdinya, située après l'exutoire, et à un petit secteur
au sud-ouest du lobe des sources (replat probable vers Mont-Louis).

### Morphométrie

**Choix du MNT :** le bassin est délimité sur le MNT corrigé, mais toutes
les mesures d'altitude et de pente portent sur le MNT d'origine.

![Planche de morphométrie](figures/planche_morphometrie.png)

*A : courbe hypsométrique. B : surface et pente moyenne par tranche
d'altitude de 100 m. C : distribution des pentes.*

| Indicateur | Valeur |
|---|---|
| Périmètre (contour lissé) | 144,5 km |
| Coefficient de Gravelius (contour lissé) | 2,00 |
| Longueur (plus long chemin d'écoulement) | 57,0 km |
| Rapport d'allongement de Schumm | 0,40 |
| Altitudes min / max | 516 m / 2 881 m |
| Altitudes moyenne / médiane | 1 743 m / 1 752 m |
| Dénivelé | 2 364 m |
| Intégrale hypsométrique | 0,52 |
| Pentes moyenne / médiane | 25,1° / 25,9° |

| Classe de pente | Part de la surface |
|---|---|
| 0–5° | 5,0 % |
| 5–15° | 18,5 % |
| 15–30° | 38,9 % |
| 30–45° | 33,3 % |
| > 45° | 4,3 % |

### Interprétation

- **Un bassin très allongé.** Le coefficient de Gravelius (2,0) et le
  rapport d'allongement (0,40) traduisent la forme du bassin : un grand
  lobe compact, prolongé par le long couloir de la haute Têt jusqu'au
  secteur des sources.
- **Trois étages de relief.** Les pentes sont fortes entre 1 000 et
  1 400 m (gorges de la Têt), douces entre 1 600 et 2 300 m (replats
  de la haute vallée), puis de nouveau
  fortes au-dessus de 2 500 m (parois et crêtes). La bande des replats
  concentre une grande part de la surface, ce qui explique la forme
  en S de la courbe hypsométrique.
- **Un bassin raide.** Plus d'un tiers de la surface (37,6 %) dépasse
  30°. La distribution des pentes chute nettement au-delà de 37°,
  ce qui évoque des pentes seuils, au-delà desquelles les versants
  meubles deviennent instables.

### Carte du bassin

![Carte du bassin de la Têt](figures/carte_bassin_tet.png)

Le réseau hydrographique est extrait de l'accumulation des écoulements,
avec un seuil de 0,5 km² drainés, puis hiérarchisé selon l'ordre de
Strahler. La Têt atteint l'ordre 5 à l'exutoire.

### Profil en long de la Têt

![Profil en long de la Têt](figures/profil_long_tet.png)

*A : profil en long, avec une exagération verticale de 10. Les bandes
rappellent les étages de pente des versants. B : pente du lit, calculée
sur des tronçons de 500 m.*

Le profil suit le plus long chemin d'écoulement, à partir de la tête du
chenal (0,5 km² drainés), avec les altitudes du MNT d'origine.

- **L'amont est en escalier.** Deux longs paliers, vers 2 000 m et vers
  1 700 m, alternent avec des ressauts. Le premier palier correspond en
  partie à la surface du lac des Bouillouses. Les deux paliers se situent
  dans l'étage des replats mis en évidence par la morphométrie.
- **Une rupture de pente nette marque l'entrée dans les gorges**, à la
  sortie de l'étage des replats : la pente du lit y remonte à environ 15 %.
- **L'aval est concave et régulier**, avec une pente qui décroît jusqu'à
  2-3 % à l'exutoire.

Cette succession de paliers et de ressauts évoque le profil d'une vallée
façonnée par les glaciers (ombilics et verrous), alors que la partie aval
présente un profil de type fluvial. Cette hypothèse reste à confirmer par
la cartographie des formes glaciaires et la littérature régionale.


### Limites

- Le périmètre dépend de la résolution : le contour brut, en marches
  d'escalier, est 19 % plus long que le contour lissé. Le coefficient
  de Gravelius est donc donné pour le contour lissé (tolérance de 5 m).
- L'agrégation à 5 m par la moyenne arrondit légèrement les sommets,
  et l'altitude maximale peut être un peu sous-estimée.
- Le rapport de Melton (0,12) est calculé, mais il n'est pas interprété :
  ses seuils ont été établis pour de petits bassins torrentiels, et ne
  s'appliquent pas à un bassin de 415 km².
  - Le réseau et l'ordre de Strahler dépendent du seuil d'accumulation
  (0,5 km²) : un seuil plus bas densifie le réseau et peut augmenter
  l'ordre maximal.
- Les surfaces de lac apparaissent comme des paliers parfaitement plats
  sur le profil en long : la pente nulle y traduit le plan d'eau, et non
  la pente du fond.

## Packages

terra, sf, whitebox, ggplot2

