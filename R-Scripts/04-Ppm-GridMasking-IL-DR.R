

install.packages("hydroGOF")

library(geosphere)
library(sqldf)
library(hydroGOF)
library(Metrics)
library(sdcMicro)


telcom <- read.csv("D:/Data Mining/04-PdpChallenge/Inputs/DataPrepTelCom.csv")


#distance in kilometers between two long/lat positions (from "fossil" package)
earth.dist <- function (long1, lat1, long2, lat2) 
{
  rad <- pi/180
  a1 <- lat1 * rad
  a2 <- long1 * rad
  b1 <- lat2 * rad
  b2 <- long2 * rad
  dlon <- b2 - a2
  dlat <- b1 - a1
  a <- (sin(dlat/2))^2 + cos(a1) * cos(b1) * (sin(dlon/2))^2
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))
  R <- 6378.145
  d <- R * c
  return(d)
}

new.lon.lat <-
  function (lon, lat, bearing, distance) 
  {
    rad <- pi/180
    a1 <- lat * rad
    a2 <- lon * rad
    tc <- bearing * rad
    d <- distance/6378.145
    nlat <- asin(sin(a1) * cos(d) + cos(a1) * sin(d) * cos(tc))
    dlon <- atan2(sin(tc) * sin(d) * cos(a1), cos(d) - sin(a1) * 
                    sin(nlat))
    nlon <- ((a2 + dlon + pi)%%(2 * pi)) - pi
    npts <- cbind(nlon/rad, nlat/rad)
    return(npts)
  }


GetGeoGridMatrix <- 
  function(startLong, startLat, endLong, endLat, downChunkDist, rightChunkDist) {
  
  #     East to West bearing  
  #     startLong ??? Starting Longitude (start x axis point)
  #     startLong ??? Starting Latitude  (start y axis point)
  #     endLong ??? Ending Longitude (end x axis point)
  #     endLong ??? Ending Latitude  (end y axis point)
  #     downChunkDist ??? down bearing (180 degree dead down) distance in Km
  #     downChunkDist ??? right bearing (90 degree east) distance in Km
    
    
    #--compute number of squares / iterations to traverese east and down ----------
    
    eastDist <- earth.dist(startLong, startLat, endLong, startLat)
    southDist <- earth.dist(startLong, startLat, startLong, endLat)
    
    #---- as cell size increases, final cell may not accomodate all the length and breath, so add a cell on both sides
    eastIter <- round(eastDist / rightChunkDist, digits = 0) + 1
    southIter <- round(southDist / downChunkDist, digits = 0) + 1
    
    
    print(paste(eastDist, southDist, eastIter, southIter, collapse = " " ))
    
    # ----------- create a empty data frame -------------------------
    df <- data.frame(cell=character(),
                     x1=numeric(), 
                     y1=numeric(), 
                     x2=numeric(), 
                     y2=numeric(), 
                     x3=numeric(), 
                     y3=numeric(), 
                     x4=numeric(), 
                     y4=numeric(),                      
                     midx=numeric(), 
                     midy=numeric(),
                     geomidx=numeric(),
                     geomidy=numeric(),
                     top=numeric(), 
                     right=numeric(), 
                     stringsAsFactors=FALSE)
    
    #----Iterate on vertical height (Latitude) ---------    
    x1 <- startLong
    y1 <- startLat
    
    for (j in 1:southIter) {
      # ---Call function (new.lon.lat) to generate a cell  
      new <- new.lon.lat(x1, y1, 180, downChunkDist)
      x4 <- new[1]
      y4 <- new[2]
      
      newrowx1 <- x4
      newrowy1 <- y4
        
      #----Iterate on horizontal length ---------
      for (i in 1:eastIter)  {  
        # ---Call function (new.lon.lat) to generate a cell  
        new <- new.lon.lat(x1, y1, 90, rightChunkDist)
        x2 <- new[1]
        y2 <- new[2]     
        
        x3 <- x2
        y3 <- y4
        
        #--------- diagonal midpoint ---------------
        midx <- round((x4 + x2)/2,digits = 4)
        midy <- round((y4 + y2)/2,digits = 4)
        
        # Compute centroid using midpoint method in R geosphere 
        centre <- centroid(rbind(c(x1,y1), c(x2,y2), c(x3, y3), c(x4,y4), c(x1,y1)))
        geomidx <- round(centre[1],digits = 4)
        geomidy <- round(centre[2],digits = 4)
        
        #-------record grid indices----------------
        cll <- paste("r",j,"c",i,sep="")
        print(paste("processing ", cll))
        #---------------- fill in the data frame record -------------      
        tmpdf <- data.frame(cell=1,
                            x1=x1, 
                            y1=y1, 
                            x2=x2, 
                            y2=y2, 
                            x3=x3, 
                            y3=y3, 
                            x4=x4, 
                            y4=y4,                      
                            midx=midx, 
                            midy=midy,
                            geomidx=geomidx,
                            geomidy=geomidy,
                            top=rightChunkDist, 
                            right=downChunkDist 
                            )
        tmpdf$cell <- cll
        #---------------- fill in the data frame record ends -------------
        df[nrow(df)+1,] <- tmpdf
        
        
        #----- reset x1 to x2 -- to keep moving forward --------
        x1 <- x2
        y1 <- y2
        
        x4 <- x3
        y4 <- y3
      }
      #----- reset x1 to x3 -- to keep moving forward --------
      x1 <- newrowx1
      y1 <- newrowy1
    }
    #---return df out -----------
    df
          
  }

#---------------- sample to test the matrix generation-------------- 
#geoMatrix <- GetGeoGridMatrix(103.55, 1.48, 104.1, 1.20, 1.3, 1.3)
#geoMatrix <- GetGeoGridMatrix(103, 1.48, 104.1, 1.20, 1.3, 1.3)

#---------------------------------------------------------------------

#---------------- find the mid point in the cell matrices for a given lat long --------------
getCentroid <- function(geo, x, y) {
  
  cell <- head(geo[   geo$x1<x & geo$y1>y 
                & geo$x2>x & geo$y2>y 
                & geo$x3>x & geo$y3<y 
                & geo$x4<x & geo$y4<y, 
                c("midx","midy")  
                ], 1)
  
  #------handle edge cases ----------------
  if (!nrow(cell)) {
    cell <- head(geo[   geo$x1<=x & geo$y1>=y 
                        & geo$x2>=x & geo$y2>=y 
                        & geo$x3>=x & geo$y3<=y 
                        & geo$x4<=x & geo$y4<=y, 
                        c("midx","midy")  
                        ], 1)
  }
  
  #--- return cell data ----------
  cell
}


# getCentroid(geoMatrix, 103.88, 1.21)

geoMatrix[   geoMatrix$x1<103 & geoMatrix$y1>1.3566, 
#        & geoMatrix$x2>x & geoMatrix$y2>y 
#        & geoMatrix$x3>x & geoMatrix$y3<y 
#        & geoMatrix$x4<x & geoMatrix$y4<y, 
       c("midx","midy")  
       ]

#---------------------------------------------------------------------------------------------


maskdf <- data.frame(right=c(1.1,2.2,3.3,4.4,5.5), down=c(1.1,2.2,3.3,4.4,5.5))

maskLabel <- c("1.1^2","2.2^2","3.3^2","4.4^2","5.5^2")
savefilename <- c("1x1","2x2","3x3","4x4","5x5")

#maskdf <- data.frame(right=c(.9,1.3,1.7,2.2,3.8), down=c(.9,1.3,1.7,2.2,2.9))
#metricdf[metricdf$AbsOrAvg=="Avg" & metricdf$ILMethod=="MSE",]

#maskLabel <- c(".9x.9","1.3x1.3","1.7x1.7","2.2x2.2","3.8x2.9")
#savefilename <- c("900m","1300m","1700m","2200m","38x29")

unqlatlong <- sqldf("Select distinct lat, long from telcom")

# ----------- create a empty data frame for IL Graph -------------------------
metricdf <- data.frame(AbsOrAvg=character(),
                 maskdim=character(), 
                 ILMethod=character(), 
                 metric=numeric(), 
                 stringsAsFactors=FALSE)


#for (i in 1:1) {
for (i in 1:nrow(maskdf)) {  
  #-----gen geo coords matrix --------------------------
  geoMatrix <- GetGeoGridMatrix(103, 1.48, 104.1, 1.20, maskdf[i,"right"], maskdf[i,"down"])
  
  # ----- make a copy of telecom to play with --------------
   telMask <- telcom
   telMask$lat1 <- 0
   telMask$long1 <- 0
  
  #for (j in 1:3) {
  for (j in 1:nrow(unqlatlong)) {  
      centr <- getCentroid(geoMatrix, unqlatlong[j,"long"], unqlatlong[j,"lat"])
      print(paste(unqlatlong[j,"long"], unqlatlong[j,"lat"], "centroid", centr$midx, centr$midy, sep=" "))
      
      telMask[telMask$lat == unqlatlong[j,"lat"] & telMask$long == unqlatlong[j,"long"], "long1"] <- centr$midx
      telMask[telMask$lat == unqlatlong[j,"lat"] & telMask$long == unqlatlong[j,"long"], "lat1"] <- centr$midy
  }
  
  #------------- IL based on standard statistics metric calculation starts ------------------
  
  for(f in 1:8) {
    tmpMetdf <- data.frame(AbsOrAvg=1,maskdim=1,ILMethod=1,metric=0)
    tmpMetdf$maskdim <- savefilename[i]
    
    #----------- MSE : mse(actual, predicted) -----------------
    if (f == 1) {
      tmpMetdf$AbsOrAvg <- "Abs"
      tmpMetdf$ILMethod <- "MSE"
      tmpMetdf$metric = mean(hydroGOF::mse(telMask[,c("lat", "long")], telMask[,c("lat1", "long1")])) 
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }
    
    #----------- MAE : mae(actual, predicted) -----------------
    else if (f == 2) {
      tmpMetdf$AbsOrAvg <- "Abs"
      tmpMetdf$ILMethod <- "MAE"
      tmpMetdf$metric = mean(hydroGOF::mae(telMask[,c("lat", "long")], telMask[,c("lat1", "long1")])) 
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }

    #----------- MV : MEAN VARIATION -----------------
    else if (f == 3) {
      tmpMetdf$AbsOrAvg <- "Abs"
      tmpMetdf$ILMethod <- "MV"
      tmpMetdf$metric = mean(abs(telMask$lat-telMask$lat1)/telMask$lat) + mean(abs(telMask$long-telMask$long1)/telMask$long)
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }

    #----------- MSE : on Averages -----------------
    else if (f == 4) {
      tmpMetdf$AbsOrAvg <- "Avg"
      tmpMetdf$ILMethod <- "MSE"
      tmpMetdf$metric = mean(abs(mean(telMask$lat)-mean(telMask$lat1))^2  + abs(mean(telMask$long)-mean(telMask$long1))^2)
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }
    
    #----------- MAE : on Averages -----------------
    else if (f == 5) {
      tmpMetdf$AbsOrAvg <- "Avg"
      tmpMetdf$ILMethod <- "MAE"
      tmpMetdf$metric = mean(abs(mean(telMask$lat)-mean(telMask$lat1))  + abs(mean(telMask$long)-mean(telMask$long1)))
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }
    
    #----------- MAE : on Averages -----------------
    else if (f == 6) {
      tmpMetdf$AbsOrAvg <- "Avg"
      tmpMetdf$ILMethod <- "MV"
      tmpMetdf$metric = mean (
                                abs(mean(telMask$lat)-mean(telMask$lat1))/mean(telMask$lat) + 
                                abs(mean(telMask$long)-mean(telMask$long1))/mean(telMask$long)
                              )
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }
    
    #----------- sdc : dRisk -----------------
    else if (f == 7) {
      tmpMetdf$AbsOrAvg <- "sdcMicro"
      tmpMetdf$ILMethod <- "dRisk"
      tmpMetdf$metric = dRisk(telMask[,c("lat", "long")], telMask[,c("lat1", "long1")]) 
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }
    

    #----------- sdc : Utility -----------------
    else if (f == 8) {
      tmpMetdf$AbsOrAvg <- "sdcMicro"
      tmpMetdf$ILMethod <- "dUtility"
      tmpMetdf$metric = dUtility(telMask[,c("lat", "long")], telMask[,c("lat1", "long1")]) 
      
      metricdf[nrow(metricdf)+1,] <- tmpMetdf
      #print(metricdf)
    }
    
#     #----------- sdc : dRiskRMD -----------------
#     else if (f == 9) {
#       tmpMetdf$AbsOrAvg <- "sdcMicro"
#       tmpMetdf$ILMethod <- "dRiskRMD"
#       tmpMetdf$metric = dRiskRMD(telMask[,c("lat", "long")], telMask[,c("lat1", "long1")]) 
#       
#       metricdf[nrow(metricdf)+1,] <- tmpMetdf
#       #print(metricdf)
#     }
    
    
  }
  
  print(metricdf)
  
  
  filePathName <- paste("D:\\Data Mining\\04-PdpChallenge\\R-Scripts-output\\telcom-",savefilename[i],".RData",sep="")
  save(telMask, file=filePathName )
  
}

save(metricdf, file="D:\\Data Mining\\04-PdpChallenge\\R-Scripts-output\\telcom-IL-StadStat-Metrics.RData")







