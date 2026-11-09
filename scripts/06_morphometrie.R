# 06_morphometrie.R -- Forme, relief, hypsométrie et pentes du bassin de la Têt
#
# Choix du MNT :
# - le bassin a été délimité sur le MNT CORRIGÉ (mnt_5m_breach.tif), nécessaire
#   pour faire circuler l'eau ;
# - toutes les mesures d'altitude et de pente portent sur le MNT D'ORIGINE
#   (mnt_5m.tif), car brèches et comblements faussent localement le relief ;
# - seule exception : le plus long chemin d'écoulement, qui suit les écoulements
#   et utilise donc le MNT corrigé.

library(terra)
library(sf)
library(ggplot2)
library(patchwork)
library(whitebox)

mnt <- rast("data/derived/mnt_5m.tif")
bv  <- st_read("data/derived/bv_tet.gpkg", quiet = TRUE)
v   <- vect(bv)

# Thème commun à toutes les figures
theme_tet <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(colour = "grey40", hjust = 0))



# 1. Préparation ----------------------------------------------------------

mnt_crop <- crop(mnt, v)
mnt_bv   <- mask(mnt_crop, v)

# Pente calculée AVANT le masquage, pour éviter les effets de bord
pente_bv <- mask(terrain(mnt_crop, v = "slope", unit = "degrees"), v)


# 2. Forme ----------------------------------------------------------------

A <- expanse(v, unit = "km")          # surface, km²
source_mnt <- paste0("Source : RGE ALTI 5 m (IGN). Bassin de la Têt à Serdinya (",
                     round(A, 1), " km²).")
P <- perim(v) / 1000                   # périmètre, km

# Le contour issu du raster est en marches d'escalier, ce qui gonfle le
# périmètre : version lissée (tolérance d'un pixel) pour comparaison
P_lisse <- perim(vect(st_simplify(bv, dTolerance = 5))) / 1000

Kc       <- P       / (2 * sqrt(pi * A))   # coefficient de Gravelius
Kc_lisse <- P_lisse / (2 * sqrt(pi * A))

# Longueur du bassin : plus long chemin d'écoulement (MNT corrigé)
wbt_longest_flowpath(
  dem    = "data/derived/mnt_5m_breach.tif",
  basins = "data/derived/bv_raster.tif",
  output = "data/derived/plus_long_chemin.shp"
)
chemin <- st_read("data/derived/plus_long_chemin.shp", quiet = TRUE)
L  <- as.numeric(max(st_length(chemin))) / 1000   # km
Re <- 2 * sqrt(A / pi) / L                        # rapport d'allongement de Schumm


# 3. Relief et hypsométrie ------------------------------------------------

z <- as.vector(values(mnt_bv, na.rm = TRUE))
zmin <- min(z); zmax <- max(z); zmoy <- mean(z); zmed <- median(z)
H      <- zmax - zmin                       # dénivelé, m
melton <- (H / 1000) / sqrt(A)              # rapport de Melton (km / km)
HI     <- (zmoy - zmin) / (zmax - zmin)     # intégrale hypsométrique

h_rel <- seq(0, 1, by = 0.01)
a_rel <- sapply(h_rel, function(h) mean((z - zmin) / H >= h))
hypso <- data.frame(a = a_rel, h = h_rel)

g_hypso <- ggplot(hypso, aes(x = a, y = h)) +
  geom_area(fill = "#4575b4", alpha = 0.15) +
  geom_abline(slope = -1, intercept = 1, linetype = "dashed", colour = "grey50") +
  geom_line(linewidth = 0.9, colour = "#4575b4") +
  scale_y_continuous(sec.axis = sec_axis(~ . * H + zmin, name = "Altitude (m)")) +
  coord_fixed(expand = FALSE) +
  labs(x = "Surface relative (a/A)", y = "Altitude relative (h/H)",
       title = "Courbe hypsométrique", caption = source_mnt,
       subtitle = paste0("Intégrale hypsométrique : ", round(HI, 2))) +
  theme_tet
g_hypso
ggsave("figures/courbe_hypsometrique.png", g_hypso,
       width = 15, height = 14, units = "cm", dpi = 300)


# 4. Pentes ---------------------------------------------------------------

p <- as.vector(values(pente_bv, na.rm = TRUE))   # toutes les pentes du bassin
pente_moy <- mean(p)
pente_med <- median(p)

breaks_cl <- c(0, 5, 15, 30, 45, 90)
labels_cl <- c("0-5°", "5-15°", "15-30°", "30-45°", "> 45°")

# Part de la surface par classe, calculée sur TOUS les pixels
part_classes <- round(prop.table(table(cut(p, breaks = breaks_cl, labels = labels_cl,
                                           include.lowest = TRUE))) * 100, 1)
part_classes

# Histogramme : échantillon de 200 000 pixels, suffisant pour la forme
ech <- spatSample(pente_bv, size = 200000, na.rm = TRUE)
names(ech) <- "pente"
ech$classe <- cut(ech$pente, breaks = breaks_cl, labels = labels_cl,
                  include.lowest = TRUE)

g_pente <- ggplot(ech, aes(x = pente, fill = classe)) +
  geom_histogram(aes(y = after_stat(count / sum(count) * 100)),
                 binwidth = 2.5, boundary = 0) +
  geom_vline(xintercept = pente_med, linetype = "dashed") +
  annotate("text", x = pente_med + 1, y = Inf, vjust = 1.5, hjust = 0, size = 3,
           label = paste0("médiane = ", round(pente_med, 1), "°")) +
  scale_fill_manual(values = c("#fee5d9", "#fcae91", "#fb6a4a", "#de2d26", "#a50f15"),
                    name = "Classe") +
  scale_x_continuous(limits = c(0, 80), breaks = seq(0, 80, 10)) +
  labs(x = "Pente (°)", y = "Part de la surface (%)",
       title = "Distribution des pentes", caption = source_mnt) +
  theme_tet
g_pente
ggsave("figures/distribution_pentes.png", g_pente,
       width = 16, height = 10, units = "cm", dpi = 300)

# Surface et pente moyenne par tranche d'altitude de 100 m
tranches  <- floor(mnt_bv / 100) * 100
pente_alt <- zonal(pente_bv, tranches, fun = "mean", na.rm = TRUE)
names(pente_alt) <- c("altitude", "pente_moy")

surf_tr <- freq(tranches)
pente_alt$surface_km2 <- surf_tr$count[match(pente_alt$altitude, surf_tr$value)] * 25 / 1e6

g_pa <- ggplot(pente_alt, aes(x = surface_km2, y = altitude + 50, fill = pente_moy)) +
  geom_col(orientation = "y", width = 90) +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "Pente\nmoyenne (°)") +
  labs(x = "Surface (km²)", y = "Altitude (m)",
       title = "Surfaces et pentes par altitude",
       caption = source_mnt) +
  theme_tet +
  theme(legend.position = "bottom") +
  guides(fill = guide_colourbar(title.position = "top", barwidth = unit(4, "cm")))
g_pa
ggsave("figures/pente_par_altitude.png", g_pa,
       width = 15, height = 16, units = "cm", dpi = 300)


# 5. Planche de synthèse --------------------------------------------------

# Copie de g_pa avec la légende sous le graphique, plus adaptée à la planche
g_pa_pl <- g_pa +
  theme(legend.position = "right") +
  guides(fill = guide_colourbar(barheight = unit(3, "cm")))

# Assemblage : deux graphiques en haut, un en bas, ligne du haut plus haute
planche <- ((g_hypso | g_pa_pl) / g_pente) +
  plot_layout(heights = c(1.2, 1))

# Retrait des sources individuelles (& : appliqué à tous les graphiques)
planche <- planche &
  labs(caption = NULL, title = NULL) &
  theme(text = element_text(size = 9))

# Lettres A, B, C et source unique sous l'ensemble
planche <- planche +
  plot_annotation(tag_levels = "A",
                  caption = source_mnt,
                  theme = theme(plot.caption = element_text(colour = "grey40", hjust = 0)))

planche
ggsave("figures/planche_morphometrie.png", planche,
       width = 26, height = 24, units = "cm", dpi = 300)


# 6. Tableau de synthèse --------------------------------------------------

morpho <- data.frame(
  indicateur = c("Surface", "Périmètre (brut)", "Périmètre (lissé)",
                 "Gravelius (brut)", "Gravelius (lissé)",
                 "Longueur (plus long chemin)", "Rapport d'allongement",
                 "Altitude min", "Altitude max", "Altitude moyenne",
                 "Altitude médiane", "Dénivelé", "Rapport de Melton",
                 "Intégrale hypsométrique", "Pente moyenne", "Pente médiane"),
  valeur = round(c(A, P, P_lisse, Kc, Kc_lisse, L, Re, zmin, zmax, zmoy,
                   zmed, H, melton, HI, pente_moy, pente_med), 2),
  unite = c("km²", "km", "km", "-", "-", "km", "-", "m", "m", "m",
            "m", "m", "-", "-", "°", "°")
)
morpho
write.csv(morpho, "data/derived/morphometrie.csv", row.names = FALSE)
write.csv(as.data.frame(part_classes), "data/derived/classes_pentes.csv", row.names = FALSE)