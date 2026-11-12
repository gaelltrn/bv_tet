# 11_comparaison_methodes.R -- Comparaison des délimitations du bassin de la Têt à Serdinya
#
# Méthodes comparées (même MNT RGE ALTI 5 m, même algorithme D8) :
# - WhiteboxTools : correction des cuvettes par brèches (scripts 02 à 04) ;
# - SAGA (Fill Sinks Wang & Liu + Upslope Area) : comblement des cuvettes.
#   Le raster Upslope Area (100 dans le bassin, 0 ailleurs) est exporté de SAGA
#   en GeoTIFF, puis vectorisé ici, avec le même outil que le bassin WhiteboxTools.
# Référence de comparaison : le bassin WhiteboxTools.

source("scripts/00_parametres.R")
library(terra)
library(sf)
library(ggplot2)
library(ggspatial)

surf_station <- 424   # km², fiche HydroPortail de la station Y0424010


# 1. Lecture des bassins ---------------------------------------------------

# Fonction de lecture vecteur
lire_vecteur_bv <- function(fichier) {
  b <- st_read(fichier, quiet = TRUE)
  if (is.na(st_crs(b))) st_crs(b) <- 2154
  st_sf(geometry = st_union(st_transform(b, 2154)))
}

# Fonction de lecture raster 
lire_raster_bv <- function(fichier, valeur) {
  r <- rast(fichier)
  if (crs(r) == "") crs(r) <- "EPSG:2154"
  r[r != valeur] <- NA
  b <- st_as_sf(as.polygons(r))
  st_sf(geometry = st_union(st_transform(b, 2154)))
}

bvs <- list(
  WhiteboxTools = lire_vecteur_bv("data/derived/bv_tet.gpkg"),
  SAGA          = lire_raster_bv("data/derived/saga_bv.tif", valeur = 100)
)
ref <- bvs$WhiteboxTools


# 2. Indicateurs -----------------------------------------------------------

# Surface sur l'ellipsoïde, en km² 
aire <- function(g) {
  g <- st_geometry(g)
  if (length(g) == 0 || all(st_is_empty(g))) return(0)
  sum(expanse(vect(st_sf(geometry = g)), unit = "km"))
}

comparaison <- do.call(rbind, lapply(names(bvs), function(m) {
  b     <- bvs[[m]]
  A     <- aire(b)
  A_ref <- aire(ref)
  inter <- aire(st_intersection(st_geometry(b), st_geometry(ref)))
  data.frame(
    methode            = m,
    surface_km2        = round(A, 2),
    ecart_station_pct  = round((A - surf_station) / surf_station * 100, 2),
    en_plus_km2        = round(A - inter, 2),       # dans b, hors de la référence
    en_moins_km2       = round(A_ref - inter, 2),   # dans la référence, hors de b
    jaccard            = round(inter / (A + A_ref - inter), 4),
    perimetre_lisse_km = round(perim(vect(st_simplify(b, dTolerance = taille_px))) / 1000, 1)
  )
}))
comparaison
write.csv(comparaison, "data/derived/comparaison_methodes.csv", row.names = FALSE)


# 3. Carte des contours ----------------------------------------------------

contours <- do.call(rbind, lapply(names(bvs), function(m)
  st_sf(methode = m, geometry = st_geometry(bvs[[m]]))))
contours$methode <- factor(contours$methode, levels = names(bvs))

exutoire <- st_read("data/derived/exutoire_snap.shp", quiet = TRUE)
if (is.na(st_crs(exutoire))) st_crs(exutoire) <- 2154

g_contours <- ggplot() +
  geom_sf(data = contours, aes(colour = methode), fill = NA, linewidth = 0.5) +
  geom_sf(data = exutoire, shape = 21, fill = "red", size = 2.5) +
  scale_colour_manual(values = c(WhiteboxTools = "black", SAGA = "#e66101"),
                      name = "Méthode") +
  annotation_scale(location = "bl") +
  coord_sf(datum = st_crs(2154)) +
  labs(title = "Délimitations du bassin de la Têt à Serdinya",
       caption = "RGE ALTI 5 m (IGN), algorithme D8. Point rouge : exutoire.") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.caption = element_text(colour = "grey40", hjust = 0))
g_contours
ggsave("figures/comparaison_contours.png", g_contours,
       width = 20, height = 15, units = "cm", dpi = 300)


# 4. Carte des désaccords --------------------------------------------------

desaccords <- rbind(
  st_sf(ecart = "Inclus par SAGA seulement",
        geometry = st_union(st_difference(st_geometry(bvs$SAGA), st_geometry(ref)))),
  st_sf(ecart = "Inclus par WhiteboxTools seulement",
        geometry = st_union(st_difference(st_geometry(ref), st_geometry(bvs$SAGA))))
)

g_desaccords <- ggplot() +
  geom_sf(data = ref, fill = "grey95", colour = "grey60", linewidth = 0.3) +
  geom_sf(data = desaccords, aes(fill = ecart), colour = NA) +
  scale_fill_manual(values = c("Inclus par SAGA seulement" = "#d7191c",
                               "Inclus par WhiteboxTools seulement" = "#2c7bb6"),
                    name = NULL) +
  coord_sf(datum = NA) +
  labs(title = "Zones de désaccord entre SAGA et WhiteboxTools") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
g_desaccords
ggsave("figures/comparaison_desaccords.png", g_desaccords,
       width = 18, height = 14, units = "cm", dpi = 300)

# nombre de pixels en désaccord
r_wbt  <- rast("data/derived/bv_raster.tif")
r_saga <- rast("data/derived/saga_bv.tif")

dans_wbt  <- !is.na(r_wbt)
dans_saga <- r_saga == 100

global(dans_wbt != dans_saga, "sum", na.rm = TRUE)