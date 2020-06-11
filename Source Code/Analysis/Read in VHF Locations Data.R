##### This code allows you to read in all the VHF relocation data and convert it into an sf object for mapping

### You will need sf and a few tidyverse packages - if you don't have them, install them using the following commented out commands
# install.packages("tidyverse")
# install.packages("sf")

### This just loads the packages
library(tidyverse)
library(sf)

## Set your working directory to wherever the sightings file is
setwd("C:/Users/luke/Dropbox/Black Rock/Data/Sightings")

## Load the points into a data.frame
VHFBase <- read.csv("Sightings Data.csv", fileEncoding="UTF-8-BOM")

## Filter out incomplete points
VHFBase <- filter(VHFBase, is.na(mN) == FALSE)
VHFBase <- filter(VHFBase, is.na(mE) == FALSE)

## This convert the VHF data into an sf object for use in spatial analysis / mapping. The geometries are sfc_POINT and the locations...
## are projected in UTM 18-North
VHFPoints <- st_as_sf(VHFBase, coords = c("mE", "mN"),
                   crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", remove = TRUE)

