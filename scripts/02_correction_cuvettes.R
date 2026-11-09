# 02_conditionnement.R -- Correction des dépressions du MNT
library(terra)
library(whitebox)

wbt_verbose(TRUE)

wbt_breach_depressions(
  dem       = "data/derived/mnt_5m.tif",
  output    = "data/derived/mnt_5m_breach.tif",
  fill_pits = TRUE
)
mnt5   <- rast("data/derived/mnt_5m.tif")
breach <- rast("data/derived/mnt_5m_breach.tif")

diff_breach <- breach - mnt5
plot(diff_breach)
global(diff_breach, c("min", "max"), na.rm = TRUE)

library(sf)
bv_env <- st_read("data/derived/enveloppe_topage.gpkg")

plot(abs(diff_breach) > 5, col = c("grey90", "red"), legend = FALSE)
plot(st_geometry(bv_env), add = TRUE)

global(abs(diff_breach) > 5, "sum", na.rm = TRUE)