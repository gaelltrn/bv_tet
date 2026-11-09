# 08_carte.R -- Carte du bassin de la Têt à la station de Serdinya
library(terra)
library(sf)
library(ggplot2)
library(tidyterra)
library(ggnewscale)
library(ggspatial)
library(whitebox)

mnt <- rast("data/derived/mnt_5m.tif")
bv  <- st_read("data/derived/bv_tet.gpkg", quiet = TRUE)
exutoire <- st_read("data/derived/exutoire_snap.shp", quiet = TRUE)
if (is.na(st_crs(exutoire))) st_crs(exutoire) <- 2154


# 1. Ombrage et altitudes sur le bassin + 1 km -----------------------------

mnt_z <- crop(mnt, ext(vect(bv)) + 1000)
ombrage <- shade(terrain(mnt_z, "slope",  unit = "radians"),
                 terrain(mnt_z, "aspect", unit = "radians"),
                 angle = 45, direction = 315)
alt_bv <- mask(mnt_z, vect(bv))


# 2. Réseau hydrographique simulé, ordonné selon Strahler -----------------

wbt_extract_streams(
  flow_accum = "data/derived/accumulation.tif",
  output     = "data/derived/reseau.tif",
  threshold  = 20000            # 20 000 pixels × 25 m² = 0,5 km² drainés
)
wbt_strahler_stream_order(
  d8_pntr = "data/derived/d8_pointer.tif",
  streams = "data/derived/reseau.tif",
  output  = "data/derived/strahler.tif"
)
wbt_raster_streams_to_vector(
  streams = "data/derived/strahler.tif",
  d8_pntr = "data/derived/d8_pointer.tif",
  output  = "data/derived/reseau.shp"
)
reseau <- st_read("data/derived/reseau.shp", quiet = TRUE)
if (is.na(st_crs(reseau))) st_crs(reseau) <- 2154
reseau <- st_intersection(reseau, st_geometry(bv))   # réseau du bassin seulement


# 3. Carte ----------------------------------------------------------------

carte <- ggplot() +
  geom_spatraster(data = ombrage, show.legend = FALSE) +
  scale_fill_gradient(low = "black", high = "white", na.value = NA) +
  new_scale_fill() +
  geom_spatraster(data = alt_bv, alpha = 0.55) +
  scale_fill_hypso_c(palette = "dem_poster", name = "Altitude (m)", na.value = NA) +
  geom_sf(data = bv, fill = NA, colour = "black", linewidth = 0.6) +
  geom_sf(data = reseau, aes(linewidth = STRM_VAL), colour = "#1f4e79",
          key_glyph = "path") +
  scale_linewidth(range = c(0.15, 1.2), name = "Ordre de\nStrahler") +
  geom_sf(data = exutoire, shape = 21, fill = "red", colour = "black", size = 3) +
  annotation_scale(location = "bl") +
  annotation_north_arrow(location = "tr", style = north_arrow_minimal(),
                         height = unit(1, "cm"), width = unit(1, "cm")) +
  coord_sf(expand = FALSE, datum = st_crs(2154)) +
  labs(x = NULL, y = NULL,
       title = "Bassin de la Têt à la station de Serdinya",
       caption = paste0("Source : RGE ALTI 5 m (IGN). Réseau simulé (D8, seuil 0,5 km²).\n",
                        "Point rouge : station Y0424010.")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.caption = element_text(colour = "grey40", hjust = 0))
carte
ggsave("figures/carte_bassin_tet.png", carte,
       width = 24, height = 18, units = "cm", dpi = 300)