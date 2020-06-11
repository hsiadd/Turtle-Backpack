### Making Incremental 95% MCPs from VHF Data

## Libraries
library(sp)
library(adehabitatHR)
library(tidyverse)
library(data.table)

## Set Up Base Dataframe
setwd("C:/Users/luke/Dropbox/Black Rock/Data/Sightings")
VHFBase <- read.csv("Sightings Data.csv", fileEncoding="UTF-8-BOM")
VHFBase <- filter(VHFBase, is.na(mN) == FALSE)
VHFBase <- filter(VHFBase, is.na(mE) == FALSE)
VHFBase <- mutate(VHFBase, daynum = day + (month - 6) * 30 - 9)
VHFBase <- mutate(VHFBase, vhf = as.character(vhf))

## Make a blank dataframe to hold MCPs
IncMCPs <- data.frame(id = character(),
                      area = double(), 
                      daynum = double(),
                      Freq = double())

## Make the MCPs!
## This uses the mcp function from adehabitatHR, which operates on sp files
## It runs a while loop, which takes all points before a certain date k and builds MCPs from them (by turtle ID)
## It does this until k represents all days with data collected

k <- 0

while(k < max(VHFBase$daynum)){
  k <- k + 1
  dVHFBase <- filter(VHFBase, daynum <= k)
  dVHFBase <- dVHFBase[dVHFBase$vhf %in% names(which(table(dVHFBase$vhf) > 4)), ]
  dVHFCoords <- dplyr::select(dVHFBase, mN, mE)
  if(nrow(dVHFCoords) > 0){
    dVHFsp <- SpatialPointsDataFrame(dVHFCoords, dVHFBase, proj4string = 
                                       CRS("+proj=utm +zone=18 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
    dVHFsp@data <- dplyr::select(dVHFsp@data, vhf)
    dVHFMCP95 <- mcp(dVHFsp, 95, unout = "ha")
    dVHFMCP95df <- dVHFMCP95@data
    dVHFMCP95df$daynum <- k
    dVHFcounts <- as.data.frame(table(dVHFBase$vhf))
    dVHFcounts <- rename(dVHFcounts, id = Var1)
    dVHFMCP95df <- merge(dVHFMCP95df, dVHFcounts)
    ##print(dVHFMCP95df)
    IncMCPs <- rbind(IncMCPs, dVHFMCP95df)
  }
}

### Now go ahead and use this data however you want! 
##Graph (Freq on x, area on y) to see if the captured 95% MCP home range has reached a plateau yet
## A similar process could be done with GPS points
## "Freq" indicates the number of points used
