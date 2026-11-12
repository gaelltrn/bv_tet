library(terra)

#création d'un raster avec le point d'exutoire pour SAGA
mnt <- rast("data/derived/mnt_5m.tif")

x <- 643771   # coordonnées du pixel bleu foncé relevées dans SAGA
y <- 6163185

cible <- rast(mnt)                    # même emprise et même résolution, sans valeurs
cible[cellFromXY(cible, cbind(x, y))] <- 1
writeRaster(cible, "data/derived/saga_cible.tif", overwrite = TRUE)

global(cible, "sum", na.rm = TRUE)    # doit valoir 1

#fichier de BV créé