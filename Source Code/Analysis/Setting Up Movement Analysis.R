#### Framework for beginning movement analysis
## This just allows you to generate a dataframe with information on turtle movement as collected through the GPS logger
## This data can then be used for analysis in any way

## Libraries
library(tidyverse)
library(sf)
library(data.table)

## Set up the dataframe, including filtering out outliers
setwd("C:/Users/luke/Dropbox/Black Rock/Data/GPS Backpacks")
file_names <- dir("C:/Users/luke/Dropbox/Black Rock/Data/GPS Backpacks")
GPSBase <- do.call("rbind", lapply(file_names, read.csv))
GPSBase <- GPSBase %>%
  filter(Lat > 40) %>%
  filter(Lat < 42) %>%
  filter(Lon < -73) %>%
  filter(Lon > -75)
GPSBase <- filter(GPSBase, Lon != 0)
GPSBase <- mutate(GPSBase, tottime = (Month - 6) * 30 * 24 * 60 + Day * 24 * 60 + Hour * 60 + Minute)
GPSBase <- GPSBase %>%
  mutate(run = rleidv(GPSBase, cols = seq_along(c("Lon", "Lat")))) %>%
  distinct(run, .keep_all = TRUE)
GPSBase <- mutate(GPSBase, vhf = as.character(vhf))
GPSBase <- mutate(GPSBase, tothours = (Month - 6) * 30 * 24 + Day * 24 + Hour + Minute / 60)
GPSPoints <- st_as_sf(GPSBase, coords = c("Lon", "Lat"),
                      crs = "+proj=longlat +datum=WGS84", remove = TRUE)
GPSPoints <- st_transform(GPSPoints, crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
pythag <- function(a, b){
  dist <- sqrt(a^2 + b^2)
  return(dist)
}
GPSPointsCoords <- st_coordinates(GPSPoints)
GPSBase <- GPSBase %>%
  mutate(mN = GPSPointsCoords[,2]) %>%
  mutate(mE = GPSPointsCoords[,1]) 
GPSBase <- GPSBase %>%
  group_by(vhf) %>%
  arrange(tothours) %>%
  mutate(mdiff = pythag(mN - lag(mN), mE - lag(mE))) %>%
  mutate(m2diff = pythag(lead(mN) - lag(mN), lead(mE) - lag(mE)))
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
GPSBase <- GPSBase %>%
  mutate(outlier = ifelse(mdiff > 150 & mdiff / m2diff > 2.5| mdiff > 100 & mdiff / m2diff > 3 |
                            mdiff > 50 & mdiff /m2diff > 3.5 | mdiff > 150 & hourdiff < 1.5 & 
                            is.na(m2diff) == TRUE,
                          "yes",
                          "no"))
GPSBase <- GPSBase %>%
  filter(outlier == "no" | is.na(outlier) == TRUE)

## Calculate movement speed for intervals (meters per hour)
#### This is already filtering out significant jumps in time (>6 hours) due to the conditions when creating mdiff
GPSBase <- mutate(GPSBase, mph = mdiff / hourdiff)

## Determine if turtle is moving at a given point (defined as movement over 25 meters)
GPSBase <- mutate(GPSBase, moving = ifelse(mph > 25,
                                                 1,
                                                 0))
GPSBase <- mutate(GPSBase, moving = ifelse(is.na(mph) == TRUE,
                                                 NA,
                                                 moving))

## Calculate the time of day at the middle of the interval for each samplin point
#### This can be used to explore daily activity patterns
GPSBase <- GPSBase %>%
  group_by(vhf) %>%
  arrange(tothours) %>%
  mutate(inthourav = ifelse(Day - lag(Day, default = first(Day)) == 0,
                            (Hour + lag(Hour, default = first(Hour))) / 2,
                            (Hour + 24 + lag(Hour, default = first(Hour))) / 2)) %>%
  mutate(inthourav = ifelse(inthourav > 24,
                            inthourav - 24,
                            inthourav))

## Add a variable to indicate nocturnal movement
### This could optimized using a dataframe containing daily sunset/sunrise for more long term projects
### ^Shouldn't be too hard, just the dataframes based on the date then mutate by comparing the two variables
GPSBase <- mutate(GPSBase, period = ifelse(inthourav >= 21 | inthourav <= 6,
                                                 "night",
                                                 "day"))

## Create a new dataframe with information on turtle "trips" (periods of sustained movement)
#### This is essentially done by using the alternating movement variable to create unique trip ids
#### Trips are then summarized by total movement, time, and differences in start and end position
#### Critical here is the difference between distance (total movement between points throughout trip) and displacement (start location to end location)
#### Split into two dataframes, one representing movement periods and one representing rest periods
GPSBase <- GPSBase %>%
  ungroup() %>%
  arrange(vhf, tothours) %>%
  mutate(tripnum = rleidv(moving))
GPSBase <- GPSBase %>%
  group_by(tripnum) %>%
  mutate(trippoints = sum(tripnum) / max(tripnum)) %>%
  mutate(triptime = sum(hourdiff)) %>%
  mutate(tripdistance = sum(mdiff)) 
GPSBase <- GPSBase %>%
  group_by(tripnum) %>%
  mutate(final_mN = last(mN)) %>%
  mutate(final_mE = last(mE)) %>%
  mutate(first_mN = first(mN)) %>%
  mutate(first_mE = first(mE)) %>%
  mutate(withindisplace = ((((final_mN - first_mN) ** 2 + 
                               (final_mE - first_mE) ** 2) ** .5)))
GPSTrips <- GPSBase %>%
  dplyr::select(vhf, moving, tripnum, triptime, trippoints,tripdistance, final_mN, final_mE,
                withindisplace) %>%
  distinct()
GPSTrips <- GPSTrips %>%
  group_by(vhf) %>%
  mutate(tripdisplace = ((((final_mN - lag(final_mN, default = first(final_mN))) ** 2 + 
                             (final_mE - lag(final_mE, default = first(final_mE))) ** 2) ** .5))) %>%
  mutate(tripdisplace = ifelse(tripdisplace > 0,
                               tripdisplace,
                               withindisplace))
GPSTrips <- mutate(GPSTrips, triplinearity = tripdisplace / tripdistance)
GPSMoving <- filter(GPSTrips, moving == 1)
GPSRest <- filter(GPSTrips, moving == 0)