# 09_calage_reseau.R -- Calage du seuil d'accumulation sur la BD TOPAGE
#
# Principe : on cherche le seuil d'accumulation dont le réseau simulé a la même
# densité de drainage (km de cours d'eau par km² de bassin) que le réseau
# BD TOPAGE. Les longueurs sont mesurées sur le réseau VECTORISÉ : le comptage
# des pixels sous-estime la longueur d'environ 18 %, car un pas en diagonale
# mesure 7,1 m et non 5 m.
#
# Référence : tronçons BD TOPAGE 2024 (Sandre, couche
# sa:TronconHydrographique_FXX_Topage2024, flux WFS), extraits par
# intersection avec le bassin. Canaux et conduites exclus.
#
# Limite : le seuil reproduit la densité du réseau CARTOGRAPHIÉ, qui omet
# souvent les ravines éphémères de tête. Les têtes de chenal réelles peuvent
# se situer plus haut.

library(terra)
library(sf)
library(ggplot2)
library(whitebox)

bv <- st_read("data/derived/bv_tet.gpkg", quiet = TRUE)
A  <- expanse(vect(bv), unit = "km")


# 1. Densité de drainage de référence (BD TOPAGE) --------------------------

ref <- st_read("data/reference/troncons_topage.gpkg", quiet = TRUE)
ref <- st_transform(ref, 2154)

table(ref$natureth)

# Exclusion des écoulements artificiels (aménagements hydroélectriques).
# Conservés : écoulements naturels, tronçons de plans d'eau (le réseau simulé
# traverse aussi les lacs), nature inconnue (6 tronçons).
artificiels <- c("Canal", "Conduit buse", "Conduit forcé, aqueduc")
ref <- ref[!ref$natureth %in% artificiels, ]
stopifnot(nrow(ref) > 0)

ref <- st_intersection(ref, st_geometry(bv))
densite_ref <- as.numeric(sum(st_length(ref))) / 1000 / A   # km / km²
densite_ref


# 2. Densité du réseau simulé, pour chaque seuil ---------------------------

densite_exacte <- function(seuil) {
  wbt_extract_streams(flow_accum = "data/derived/accumulation.tif",
                      output     = "data/derived/reseau_test.tif",
                      threshold  = seuil)
  wbt_raster_streams_to_vector(streams = "data/derived/reseau_test.tif",
                               d8_pntr = "data/derived/d8_pointer.tif",
                               output  = "data/derived/reseau_test.shp")
  r <- st_read("data/derived/reseau_test.shp", quiet = TRUE)
  if (is.na(st_crs(r))) st_crs(r) <- 2154
  r <- st_intersection(r, st_geometry(bv))
  as.numeric(sum(st_length(r))) / 1000 / A
}

seuils <- c(5000, 10000, 20000, 25000, 30000, 35000, 40000, 50000)   # pixels de 25 m²

calage <- data.frame(
  seuil_px  = seuils,
  seuil_km2 = seuils * 25 / 1e6,
  densite   = sapply(seuils, densite_exacte)
)
calage$ecart_pct <- round((calage$densite - densite_ref) / densite_ref * 100, 1)
calage


# 3. Seuil retenu ----------------------------------------------------------

seuil_retenu <- calage$seuil_px[which.min(abs(calage$ecart_pct))]
cat("Seuil retenu :", seuil_retenu, "pixels, soit",
    seuil_retenu * 25 / 1e6, "km².\nÀ reporter dans scripts/00_parametres.R\n")


# 4. Figure et export ------------------------------------------------------

g_calage <- ggplot(calage, aes(x = seuil_km2, y = densite)) +
  geom_line() +
  geom_point() +
  geom_point(data = calage[calage$seuil_px == seuil_retenu, ],
             colour = "red", size = 3) +
  geom_hline(yintercept = densite_ref, linetype = "dashed", colour = "#1f78b4") +
  annotate("text", x = max(calage$seuil_km2), y = densite_ref,
           vjust = -0.5, hjust = 1, colour = "#1f78b4",
           label = "densité BD TOPAGE") +
  scale_x_log10() +
  labs(x = "Seuil d'accumulation (km², échelle logarithmique)",
       y = "Densité de drainage (km/km²)",
       title = "Calage du seuil de réseau",
       subtitle = "Point rouge : seuil retenu",
       caption = "Réseau simulé : D8 sur RGE ALTI 5 m, longueurs mesurées sur le réseau vectorisé.") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.caption = element_text(colour = "grey40", hjust = 0))
g_calage
ggsave("figures/calage_seuil.png", g_calage,
       width = 16, height = 11, units = "cm", dpi = 300)

write.csv(calage, "data/derived/calage_seuil.csv", row.names = FALSE)


# 5. Contrôle bonus : ordre des tronçons dans la BD TOPAGE ------------------

table(ref$strategieclassementnumeroordreth)
table(ref$numeroordreth)


# 6. Nettoyage des fichiers temporaires ------------------------------------

file.remove(list.files("data/derived", pattern = "^reseau_test", full.names = TRUE))