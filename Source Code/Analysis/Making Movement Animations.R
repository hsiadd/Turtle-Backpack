### Animating wildlife movements
## One example with a single turtle's VHF and GPS tracking movements overlaid

### NOTE: gganimate has been updated a lot and is very tricky to get working
## There are likely to be issues with permissions and rendering on your computer
## It is also possible that parts of this code will no longer work due to updates
## Reach out if trying to do this and I can help some more

## Libraries
library(tidyverse)
library(sf)
library(data.table)
library(ggmap)
library(gganimate)
library(RgoogleMaps)
library(zoo)

## Set Up GPS sf Objects
## Including filtering outliers and reducing to just one turtle
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
  mutate(outlier = ifelse(mdiff > 50 & mdiff / m2diff > 3,
                          "yes",
                          "no")) %>%
  filter(outlier == "no")
GPSBase100 <- filter(GPSBase, vhf == 150.100)
GPSBase100 <- filter(GPSBase100, Month == 7)
GPSBase100 <- mutate(GPSBase100, hournum = Day * 24 + Hour)
GPSPoints100 <- st_as_sf(GPSBase100, coords = c("mE", "mN"),
                         crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", remove = TRUE)

GPSPoints100 <- st_transform(GPSPoints100, crs = 4326)
GPSBase100$Lon <- st_coordinates(GPSPoints100)[,1]
GPSBase100$Lat <- st_coordinates(GPSPoints100)[,2]
GPSStrip100 <- dplyr::select(GPSBase100, hournum, tottime, Lon, Lat)

## Set Up VHF sf Object
setwd("C:/Users/luke/Dropbox/Black Rock/Data/Sightings")
VHFBase <- read.csv("Sightings Data.csv", fileEncoding="UTF-8-BOM")
VHFBase <- mutate(VHFBase, tottime = (month - 6) * 30 * 24 * 60 + day * 24 * 60 + hour * 60 + minute)
VHFBase100 <- filter(VHFBase, vhf == 150.100)
VHFBase100 <- mutate(VHFBase100, vhf = as.character(vhf))
VHFBase100 <- mutate(VHFBase100, daynum = day + (month - 6) * 30 - 9)
VHFBase100 <- filter(VHFBase100, is.na(mN) == FALSE)
VHFBase100 <- filter(VHFBase100, is.na(mE) == FALSE)
VHFBase100July <- filter(VHFBase100, daynum > 30)
VHFPoints100July <- st_as_sf(VHFBase100July, coords = c("mE", "mN"),
                             crs = "+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs", remove = TRUE)
VHFPoints100July <- st_transform(VHFPoints100July, crs = 4326)
VHFBase100July$x <- st_coordinates(VHFPoints100July)[,1]
VHFBase100July$y <- st_coordinates(VHFPoints100July)[,2]

## Combine the two dataframes
## Now this dataframe contains seperate coordinates for the recorded VHF and GPS location at every hour which a GPS location was taken
## The VHF coordinates remain the same until a new point is updated
VHFBase100July <- mutate(VHFBase100July, hournum = day * 24 + hour)
VHFBase100July <- mutate(VHFBase100July, hournum = ifelse(hournum == 256,
                                                          261,
                                                          hournum))
VHFStrip100July <- dplyr::select(VHFBase100July, hournum, x, y)
Base100July <- merge(GPSStrip100, VHFStrip100July, all.x = TRUE)
Base100July <- Base100July %>%
  mutate(x = na.locf(x)) %>%
  mutate(y = na.locf(y))

## Download a basemap using ggmap
Mbase <- get_map(location = c(lon = -74.056, lat = 41.387),
                 zoom = 16, maptype = "satellite")

## Manuallly add in a progress bar 
## I did this SUPER messy. Could be much more elegant
## Esentially is creating a square which is fitted to the map
## Honestly, this whole animation code is very messy. 
Base100July <- Base100July %>%
  mutate(progress = -74.0605 + .003666* 
           (tottime - min(tottime)) / (max(tottime) - min(tottime))) %>%
  mutate(xmin = -74.0605) %>%
  mutate(ymin = 41.38886) %>%
  mutate(ymax = 41.389)

## Generate animation
## This uses the gganimate package
## This is essentially creating a ggplot on top of a ggmap
## Coordinates are being graphed as numeric points rather than spatial objects
## geom_rect creates the progress bar
## transition_time() is the key to the animation here, it's what tweens between the different points
AnimGPSVHF100 <- ggmap(Mbase) +
  scale_x_continuous(limits = c(-74.061, -74.050), expand = c(0, 0), 
                     breaks = seq(-74.0605, -74.056834, .0003666), 
                     labels = paste(seq(0, 100, 10), "%"),
                     position = "top") +
  scale_y_continuous(limits = c(41.384, 41.389), expand = c(0, 0)) +
  geom_point(Base100July, mapping = aes(x = Lon, y = Lat), color = "blue",
             alpha = .5, size = 6) +
  geom_point(Base100July, mapping = aes(x = x, y = y), color = "red", 
             size = 6, alpha = .5) +
  geom_rect(Base100July, mapping = aes(xmin = xmin, ymin = ymin, xmax = progress,
                                       ymax = ymax), inherit.aes = FALSE, fill = "grey75",
            color = "black", alpha = .6) +
  theme_bw() +
  theme(axis.line=element_blank(),
        axis.text.y=element_blank(),
        axis.title.y=element_blank(),
        axis.title.x = element_text(size = 11, hjust = .2121),
        title = element_text(size = 20),
        legend.title = element_blank(),
        legend.position = "none") +
  labs(x = "Animation Progress", title = "July {frame_time %/% 60 %/% 24 - 30}, 
       {round((frame_time / 60) %% 24, digits = 0)} Hours") +
  transition_time(tottime) 

## Render and save!
RendGPSVHF100NOOUTLIERS <- animate(AnimGPSVHF100, nframes = 800, fps = 30, width = 1200, height = 900)
save_animation(RendGPSVHF100NOOUTLIERS, "C:/Users/luke/Dropbox/Black Rock/Data/GPSVHF150100JulyNoOutliersSatellite.gif")
