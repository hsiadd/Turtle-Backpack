### Filtering out GPS outlier points (errors)

## Libraries
library(tidyverse)
library(sf)

## Set Up GPS sf Objects (see other file for more explanation)
setwd("C:/Users/luke/Dropbox/Black Rock/Data/GPS Backpacks")
file_names <- dir("C:/Users/luke/Dropbox/Black Rock/Data/GPS Backpacks")
GPSBase <- do.call("rbind", lapply(file_names, read.csv))
GPSBase <- GPSBase %>%
  filter(Lat > 40) %>%
  filter(Lat < 42) %>%
  filter(Lon < -73) %>%
  filter(Lon > -75)
GPSBase <- plyr::join(GPSBase, rename)
GPSBase <- filter(GPSBase, Lon != 0)
GPSBase <- GPSBase %>%
  mutate(run = rleidv(GPSBase, cols = seq_along(c("Lon", "Lat")))) %>%
  distinct(run, .keep_all = TRUE)
GPSBase <- mutate(GPSBase, vhf = as.character(vhf))
GPSBase <- mutate(GPSBase, tothours = (Month - 6) * 30 * 24 + Day * 24 + Hour + Minute / 60)
GPSPoints <- st_as_sf(GPSBase, coords = c("Lon", "Lat"),
                      crs = "+proj=longlat +datum=WGS84", remove = TRUE)
GPSPoints <- st_transform(GPSPoints, crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")

## Make a pythagorean function
pythag <- function(a, b){
  dist <- sqrt(a^2 + b^2)
  return(dist)
}

##### Filtering out errors
### Essentially this works by filtering out one hour spikes of movement in a random direction with immediate returns to original position
### This should be much less neccessary with gen3 backpacks

## Return projected coordinates into original dataframe
GPSPointsCoords <- st_coordinates(GPSPoints)
GPSBase <- GPSBase %>%
  mutate(mN = GPSPointsCoords[,2]) %>%
  mutate(mE = GPSPointsCoords[,1]) 

## Take the straight-line distance between each point collected and the prior point (grouped by turtle ID)
## AND the straight-line distance between the next point and the prior point
GPSBase <- GPSBase %>%
  group_by(vhf) %>%
  arrange(tothours) %>%
  mutate(mdiff = pythag(mN - lag(mN), mE - lag(mE))) %>%
  mutate(m2diff = pythag(lead(mN) - lag(mN), lead(mE) - lag(mE)))

## Calculate the time gap between points collected, and ignore points with a gap greater than six hours
GPSBase <- GPSBase %>%
  group_by(vhf) %>%
  arrange(tothours) %>%
  mutate(hourdiff = tothours - lag(tothours, default = first(tothours))) %>%
  mutate(mdiff = ifelse(hourdiff > 6,
                        NA,
                        mdiff))
GPSBase <- GPSBase %>%
  group_by(vhf) %>%
  arrange(tothours) %>%
  mutate(hour2diff = tothours - lead(tothours, default = first(tothours))) %>%
  mutate(m2diff = ifelse(hour2diff < -6,
                         NA,
                         m2diff))

## Determine if the point is an outlier
#### This is determined by the total distance covered and the "spikiness" of the movement (ratio between mdiff and m2diff)
#### This values in the ifelse statement can be altered to change threshold for an "outlier"
GPSBase <- GPSBase %>%
  mutate(outlier = ifelse(mdiff > 150 & mdiff / m2diff > 2.5| mdiff > 100 & mdiff / m2diff > 3 |
                            mdiff > 50 & mdiff /m2diff > 3.5 | mdiff > 150 & hourdiff < 1.5 & 
                            is.na(m2diff) == TRUE,
                          "yes",
                          "no"))

## Filter out outliers and return to an sf object
GPSBase <- GPSBase %>%
  filter(outlier == "no" | is.na(outlier) == TRUE)
GPSPoints <- st_as_sf(GPSBase, coords = c("mE", "mN"),
                      crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", remove = TRUE)