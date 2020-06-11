#### Making basic visual maps in sf

## Libraries
library(tidyverse)
library(sf)
library(tmap)
library(tmaptools)

## Set Up VHF sf points
setwd("C:/Users/luke/Dropbox/Black Rock/Data/Sightings")
VHFBase <- read.csv("Sightings Data.csv")
VHFBase <- mutate(VHFBase, vhf = as.character(vhf))
VHFBase <- filter(VHFBase, is.na(mN) == FALSE)
VHFBase <- filter(VHFBase, is.na(mE) == FALSE)
VHFPoints <- st_as_sf(VHFBase, coords = c("mE", "mN"),
                      crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", remove = TRUE)

## Make a sf object with lines representing VHF movements
## This uses st_cast from the sf package
## You might want to break up objects when there are large jumps in time (do this by calculating time distance between points and filter)
VHFLines <- VHFPoints %>% 
  mutate(id = 1) %>%
  arrange(desc(month), desc(day), desc(hour), desc(minute)) %>%
  dplyr::select(vhf, id, geometry)%>%
  group_by(vhf) %>% 
  summarize(m = mean(id), do_union = FALSE) %>%
  st_cast("LINESTRING") %>%
  dplyr::select(vhf, geometry)

## Make an sf object with polygons representing 100% MCP home ranges (TLoCoH is probably preferred)
VHFHulls <- VHFPoints %>%
  mutate(id = 1) %>%
  dplyr::select(vhf, id, geometry)%>%
  group_by(vhf) %>% 
  summarize(m = mean(id), do_union = FALSE) %>%
  st_cast("MULTIPOINT") %>%
  dplyr::select(vhf, geometry) %>%
  st_convex_hull()

## Do all of the same things for GPS points (this is including the code to remove outliers)
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
GPSPoints <- st_as_sf(GPSBase, coords = c("mE", "mN"),
                      crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", remove = TRUE)
GPSLines <- GPSPoints %>% 
  mutate(id = 1) %>%
  group_by(vhf) %>% 
  summarize(m = mean(id), do_union = FALSE) %>%
  st_cast("LINESTRING")
GPSHulls <- GPSPoints %>%
  mutate(id = 1) %>%
  group_by(vhf) %>% 
  summarize(m = mean(id), do_union = FALSE) %>%
  st_cast("MULTIPOINT") %>%
  dplyr::select(vhf, geometry) %>%
  st_convex_hull()

## Make subsets of which turtles you want to map! This example will use the Merrill Road turtles
Merrillgroup <- c(150.1, 150.221, 150.141, 150.181)
MVHFPoints <- filter(VHFPoints, vhf %in% Merrillgroup)
MVHFLines <- filter(VHFLines, vhf %in% Merrillgroup)
MVHFHulls <- filter(VHFHulls, vhf %in% Merrillgroup)
MGPSPoints <- filter(GPSPoints, vhf %in% Merrillgroup)
MGPSLines <- filter(GPSLines, vhf %in% Merrillgroup)
MGPSHulls <- filter(GPSHulls, vhf %in% Merrillgroup)

## Set tmap mode to interactive
tmap_mode('view')

## Make some maps!
## Here are some examples
## tmap has a lot of customisation, just explore with it

tm_shape(MVHFHulls) +
  tm_polygons(id = "vhf", col = as.character("vhf"), style = "pretty", size = .03, alpha = .5, legend.show = FALSE) +
  tm_shape(MVHFPoints) +
  tm_dots(id = "day", col = as.character("vhf"), style = "pretty", size = .05) +
  tm_basemap("Esri.WorldTopoMap") +
  tm_scale_bar(breaks = 4, width = 500)

tm_shape(MGPSLines) +
  tm_lines(id = "Day", col = as.character("vhf"), lwd = 2, legend.col.show = FALSE, lty = "dotted",
           palette = get_brewer_pal("Set2", n = 4, stretch = FALSE)) +
  tm_shape(MVHFLines) +
  tm_lines(id = "day", col = as.character("vhf"), lwd = 3,
           palette = get_brewer_pal("Set2", n = 4, stretch = FALSE),
           labels = c("Turtle A", "Turtle B", "Turtle C", "Turtle D"), title.col = "") +
  tm_basemap("Esri.WorldImagery") +
  tm_scale_bar(width = 300, position = c("right", "bottom"))
