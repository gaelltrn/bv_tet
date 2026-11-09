# 07_profil_long.R -- Profil en long de la Têt, de la tête du chenal à la station de Serdinya
#
# Tracé : plus long chemin d'écoulement (script 06), qui suit le talweg du MNT.
# Début : tête du chenal (accumulation > 0,5 km²), pour exclure le tronçon de versant.
# Altitudes : MNT D'ORIGINE, comme pour toute la morphométrie.

library(terra)
library(sf)
library(ggplot2)
library(patchwork)

mnt    <- rast("data/derived/mnt_5m.tif")
acc    <- rast("data/derived/accumulation.tif")
bv     <- st_read("data/derived/bv_tet.gpkg", quiet = TRUE)
chemin <- st_read("data/derived/plus_long_chemin.shp", quiet = TRUE)
if (is.na(st_crs(chemin))) st_crs(chemin) <- 2154

# Une seule ligne continue, la plus longue (fusion seulement si nécessaire)
geom <- st_union(st_geometry(chemin))
if (inherits(geom, "sfc_MULTILINESTRING")) geom <- st_line_merge(geom)
chemin <- st_cast(geom, "LINESTRING")
chemin <- chemin[which.max(st_length(chemin))]

# Contrôle : le chemin doit suivre la Têt depuis le lobe des sources
plot(st_geometry(bv))
plot(chemin, col = "blue", lwd = 2, add = TRUE)


# 1. Échantillonnage tous les 5 m ----------------------------------------

pts <- st_cast(st_line_sample(chemin, density = 1/5), "POINT")
alt <- extract(mnt, vect(pts))[, 2]

# Le profil doit aller de l'amont vers l'aval
if (alt[1] < alt[length(alt)]) {
  pts <- pts[length(pts):1]
  alt <- rev(alt)
}

# Début à la tête du chenal (même seuil que le réseau de la carte)
acc_pts <- extract(acc, vect(pts))[, 2]
debut <- which(acc_pts > 20000)[1]
pts <- pts[debut:length(pts)]
alt <- alt[debut:length(alt)]

ecarts <- as.numeric(st_distance(pts[-length(pts)], pts[-1], by_element = TRUE))
prof <- data.frame(distance_m = c(0, cumsum(ecarts)), altitude = alt)
prof$distance_km <- prof$distance_m / 1000


# 2. Pente du lit sur des tronçons de 500 m -------------------------------

k <- 100   # 100 points × 5 m = 500 m
pente_lit <- data.frame(
  distance_km = (head(prof$distance_m, -k) + diff(prof$distance_m, lag = k) / 2) / 1000,
  pente_pct   = -diff(prof$altitude, lag = k) / diff(prof$distance_m, lag = k) * 100
)


# 3. Figures --------------------------------------------------------------

theme_tet <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(colour = "grey40", hjust = 0))

g_prof <- ggplot(prof, aes(x = distance_km, y = altitude)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1000, ymax = 1400,
           fill = "#3b0f70", alpha = 0.10) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1600, ymax = 2300,
           fill = "#fe9f6d", alpha = 0.15) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 2500, ymax = Inf,
           fill = "#3b0f70", alpha = 0.10) +
  geom_line(linewidth = 0.7, colour = "#1f78b4") +
  coord_fixed(ratio = 10 / 1000) +
  labs(x = "Distance depuis la tête du chenal (km)", y = "Altitude (m)",
       title = "Profil en long de la Têt",
       subtitle = paste0("Exagération verticale × 10. Bandes : étages de pente des versants ",
                         "(sombre : fortes pentes ; clair : replats).")) +
  theme_tet

g_lit <- ggplot(pente_lit, aes(x = distance_km, y = pente_pct)) +
  geom_area(fill = "#1f78b4", alpha = 0.3) +
  geom_line(colour = "#1f78b4") +
  labs(x = "Distance depuis la tête du chenal (km)", y = "Pente du lit (%)",
       title = "Pente du lit (tronçons de 500 m)") +
  theme_tet

profil_long <- (g_prof / g_lit) +
  plot_layout(heights = c(1.4, 1)) +
  plot_annotation(
    tag_levels = "A",
    caption = paste0("Source : RGE ALTI 5 m (IGN). Tracé : plus long chemin d'écoulement (D8), ",
                     "à partir de la tête du chenal (0,5 km² drainés)."),
    theme = theme(plot.caption = element_text(colour = "grey40", hjust = 0))
  )
profil_long
ggsave("figures/profil_long_tet.png", profil_long,
       width = 22, height = 16, units = "cm", dpi = 300)