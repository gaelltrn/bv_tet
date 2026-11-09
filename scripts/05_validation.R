# 05_validation.R -- Validation de la délimitation du bassin de la Têt à Serdinya
#
# Résultats (novembre 2026) :
# - surface calculée : 416 km² pour 424 km² à la station Y0424010 (écart d'environ -2 %)
# - accrochage de l'exutoire : 27 m
# - très bon accord avec l'enveloppe BD TOPAGE, sauf :
#   * au nord-est : la partie aval de la zone de Serdinya, après l'exutoire 
#   * au sud-ouest du lobe des sources : petit secteur exclu, replat probable
#     vers Mont-Louis 

library(sf)
library(ggplot2)
library(ggspatial)

bv_tet   <- st_read("data/derived/bv_tet.gpkg", quiet = TRUE)
bv_env   <- st_read("data/derived/enveloppe_topage.gpkg", quiet = TRUE)
exutoire <- st_read("data/derived/exutoire.shp", quiet = TRUE)
snap     <- st_read("data/derived/exutoire_snap.shp", quiet = TRUE)

# 1. Surface : comparaison avec la station hydrométrique
surf_ref <- 424   # km², fiche HydroPortail de la station Y0424010 
surf_bv  <- as.numeric(st_area(bv_tet)) / 1e6
ecart    <- (surf_bv - surf_ref) / surf_ref * 100

# 2. Accrochage de l'exutoire au chenal simulé
d_snap <- as.numeric(st_distance(exutoire, snap))
stopifnot(d_snap < 50)

# 3. Concordance avec l'enveloppe BD TOPAGE, dans les deux sens
bv_hors_env <- as.numeric(sum(st_area(st_difference(bv_tet, bv_env)))) / 1e6
env_hors_bv <- as.numeric(sum(st_area(st_difference(bv_env, bv_tet)))) / 1e6

# 4. Tableau de synthèse
validation <- data.frame(
  indicateur = c("Surface calculée", "Surface de référence (station)",
                 "Écart à la référence", "Distance d'accrochage",
                 "Bassin hors enveloppe", "Enveloppe hors bassin"),
  valeur = round(c(surf_bv, surf_ref, ecart, d_snap,
                   bv_hors_env, env_hors_bv), 2),
  unite  = c("km²", "km²", "%", "m", "km²", "km²")
)
validation
write.csv(validation, "data/derived/validation.csv", row.names = FALSE)

# 5. Figure de contrôle
g <- ggplot() +
  geom_sf(data = bv_env, fill = NA, colour = "grey50", linewidth = 0.4) +
  geom_sf(data = bv_tet, fill = NA, colour = "red", linewidth = 0.5) +
  geom_sf(data = snap, colour = "blue", size = 2) +
  coord_sf(datum = st_crs(2154)) +
  labs(title = "Validation du bassin de la Têt à Serdinya",
       caption = "Gris : enveloppe BD TOPAGE. Rouge : bassin calculé (RGE ALTI 5 m, D8). Bleu : exutoire.") +
  theme_minimal()
g
ggsave("figures/validation_bv.png", g, width = 18, height = 14, units = "cm", dpi = 300)

morceaux <- st_cast(st_difference(bv_env, bv_tet), "POLYGON")
morceaux$surface_km2 <- as.numeric(st_area(morceaux)) / 1e6
morceaux <- morceaux[morceaux$surface_km2 > 0.5, ]
morceaux$surface_km2
plot(st_geometry(bv_env), border = "grey50")
plot(st_geometry(morceaux), col = "orange", add = TRUE)