# 01_import_mnt.R -- Mosaïque virutelle du RGE ALTI 5 m (département 66)
library(sf)
library(terra)

# 01_import_mnt.R -- MNT RGE ALTI 1 m (D066), découpé sur le bassin et agrégé à 5 m
library(terra)
library(sf)

# 1. Mosaïque du MNT
dalles <- list.files("data/raw", pattern = "\\.(asc|tif)$",
                     full.names = TRUE, recursive = TRUE)
dalles <- dalles[grepl("MNT", dalles)]
mnt <- vrt(dalles)
crs(mnt) <- "EPSG:2154"

# 2. Enveloppe du bassin à partir de la BD TOPAGE 2024
# Zones retenues : la Têt de sa source au ravin de Torrens,
# + 2 zones aval jusqu'à Serdinya. Zones voisines vérifiées dans QGIS :
# rattachées à l'Aude (Capcir) ou au Sègre (Cerdagne), donc hors bassin.
bv_ref <- st_read("data/reference/BassinVersantTopographique_FXX.gpkg",
                  layer = "BassinVersantTopographique_FXX")
codes_tet <- c("06B0000002150459940",
               "06B0000002150455490",
               "06B0000002150459936")
sel <- bv_ref[bv_ref$CdOH %in% codes_tet, ]
stopifnot(nrow(sel) == 3)

bv_env <- st_union(sel)
st_write(bv_env, "data/derived/enveloppe_topage.gpkg", delete_dsn = TRUE)

# 3. Découpage avec une marge de 1 km, puis agrégation à 5 m
zone <- vect(st_buffer(bv_env, 1000))
mnt_zone <- crop(mnt, zone)
mnt5 <- aggregate(mnt_zone, fact = 5, fun = "mean",
                  filename = "data/derived/mnt_5m.tif", overwrite = TRUE)

# 4. Contrôle
mnt5
plot(mnt5)
plot(st_geometry(bv_env), add = TRUE)