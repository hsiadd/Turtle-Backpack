###### This code allows you to read in all the data from the GPS Backpacks (saved in non-UTF8 .csv files and all formatted with the same columns) ...
## ... into an sf object.

### You will need sf and a few tidyverse packages - if you don't have them, install them using the following commented out commands
# install.packages("tidyverse")
# install.packages("sf")
# install.packages("data.table")

### This just loads the packages
library(tidyverse)
library(sf)
library(data.table)

## Set your working directory to wherever all the GPS Backpack .csv files are
setwd("C:/Users/luke/Dropbox/Black Rock/Data/GPS Backpacks")

## This creates a vector which includes the names of all the GPS .csv files
file_names <- dir("C:/Users/luke/Dropbox/Black Rock/Data/GPS Backpacks")

## This applies the function "rbind" to all the files in the previous vector, creating a data.frame with all the data!
GPS <- do.call("rbind", lapply(file_names, read.csv))

## This filters out locations that are blatantly wrong (not anywhere near Black Rock) and also data points without any location recorded
## This code relies upon the "filter" function from the dplyr package
GPS <- GPS %>%
  filter(Lat > 40) %>%
  filter(Lat < 42) %>%
  filter(Lon < -73) %>%
  filter(Lon > -75)

## This removes unsuccesful fixes from the data.frame (consecutive data points with the exact same location)
## This code uses the "rleidv" function from the data.table package and the "mutate" function to generate a new variable...
## ... which increases by 1 each time the location changes. The "distinct" function from dplyr is then used to removed duplicates.
GPS <- GPS %>%
  mutate(run = rleidv(GPS, cols = seq_along(c("Lon", "Lat")))) %>%
  distinct(run, .keep_all = TRUE)

## This convert the GPS data into an sf object for use in spatial analysis / mapping. The geometries are sfc_POINT and the locations...
## are unprojected (in WGS84 lat-lon).
GPSPoints <- st_as_sf(GPS, coords = c("Lon", "Lat"),
                      crs = "+proj=longlat +datum=WGS84", remove = TRUE)

## This projects the data into UTM 18 North (New York State)
GPSPoints <- st_transform(GPSPoints, crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")

## This converts the sf back to a data.frame
GPSPoints_df <- cbind(st_drop_geometry(GPSPoints), as.data.frame(st_coordinates(GPSPoints)))

## This saves your data.frame as a .csv, which you can now load into ArcGIS! (Hi Devon!!)
# FIRST CHANGE THE WORKING DIRECTORY TO THE FOLDER WHERE YOU WANT IT - DONT PUT IT IN THE BLACK ROCK GPS FILES FOLDER
setwd("C:/Users/luke/Desktop")
write.csv(GPSPoints_df, "GPSBackpacks_UTM18N.csv")

