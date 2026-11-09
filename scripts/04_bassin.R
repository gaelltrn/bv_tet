# 04_bassin.R -- Accrochage de l'exutoire et délimitation du bassin
library(terra)
library(sf)
library(whitebox)
wbt_verbose(TRUE)

x <- 643750   
y <- 6163187   

exutoire <- st_sf(station = "Y0424010",
                  geometry = st_sfc(st_point(c(x, y)), crs = 2154))
st_write(exutoire, "data/digitalisation/exutoire.gpkg", delete_dsn = TRUE)

exutoire <- st_read("data/digitalisation/exutoire.gpkg")
stopifnot(nrow(exutoire) == 1)
st_write(exutoire, "data/derived/exutoire.shp", delete_dsn = TRUE)

# Accrochage au pixel d'accumulation maximale dans un rayon de 50 m
wbt_snap_pour_points(
  pour_pts   = "data/derived/exutoire.shp",
  flow_accum = "data/derived/accumulation.tif",
  output     = "data/derived/exutoire_snap.shp",
  snap_dist  = 50
)

# Délimitation du bassin en amont de l'exutoire
wbt_watershed(
  d8_pntr  = "data/derived/d8_pointer.tif",
  pour_pts = "data/derived/exutoire_snap.shp",
  output   = "data/derived/bv_raster.tif"
)

# Conversion en polygone
bv_r  <- rast("data/derived/bv_raster.tif")
bv_tet <- st_as_sf(as.polygons(bv_r))
st_write(bv_tet, "data/derived/bv_tet.gpkg", delete_dsn = TRUE)

as.numeric(st_area(bv_tet)) / 1e6   # surface en km²