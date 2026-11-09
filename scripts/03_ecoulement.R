# 03_ecoulement.R -- Direction de flux D8 et accumulation des écoulements
library(terra)
library(whitebox)
wbt_verbose(TRUE)

wbt_d8_pointer(
  dem    = "data/derived/mnt_5m_breach.tif",
  output = "data/derived/d8_pointer.tif"
)

wbt_d8_flow_accumulation(
  input    = "data/derived/mnt_5m_breach.tif",
  output   = "data/derived/accumulation.tif",
  out_type = "cells"
)

acc <- rast("data/derived/accumulation.tif")
plot(log10(acc))
acc_vue <- aggregate(log10(acc), fact = 10, fun = "max")
plot(acc_vue)
