

#telcom <- read.csv("D:/Data Mining/04-PdpChallenge/Inputs/DataPrepTelCom.csv")
#geocount <- read.csv("D:/Data Mining/04-PdpChallenge/Inputs/DataPrepTelCom-latlongcount.csv")
#telcomSub <- telcom[order(telcom$customerid, telcom$locdatetime),]


getHopsInGeoCoord <- function (data, daypart)
{
  
  data$date <- as.Date(data$locdatetime)
  data$datetime <- as.POSIXct(data$locdatetime)
  data$locdatetime <- NULL
  
  iter.cus <- as.data.frame(unique(data[, c("customerid", "date")]))
  iter.cus <- iter.cus[order(iter.cus$customerid, iter.cus$date),]
  
  #---create a empty data frame to hold row wise data result---------
  #-----------preserves order of column creation --- beware---------
  empty.df <- iter.cus[1,]
  empty.df$daypart <- 0
  empty.df$lat <- 0
  empty.df$long <- 0
  empty.df$activity <- 0
  empty.df <- empty.df[-1,]
  #------------------------------------------------------------
  
  #print(iter.cus)
  
  for(i in 1:nrow(iter.cus)) {
    #for(i in 1:3) {
    
    adayless <- as.POSIXct(as.character(iter.cus[i,"date"])) - 24 * 60 * 60
    
    temp <- data[data$customerid == iter.cus[i,"customerid"] & as.POSIXct(data$date) >= adayless & data$date <= iter.cus[i,"date"],]
    data.cus <- temp[order(temp$datetime),]
    rownames(data.cus) <- seq(length=nrow(data.cus))
    
    #print(data.cus)
    #t <- as.POSIXct(as.character(iter.cus[i,"date"])) + starthour * 60 * 60
    #print(t)
    
    daypartCount <- 0
    
    for (item in 1:nrow(daypart)){
      
      starthour <- daypart[item, "starthour"]
      endhour <- daypart[item, "endhour"]
      
      subset <- data.cus[data.cus$datetime >= (as.POSIXct(as.character(iter.cus[i,"date"])) + starthour * 60 * 60) & data.cus$datetime < (as.POSIXct(as.character(iter.cus[i,"date"])) + endhour * 60 * 60), ] 
      #print(daypart[item,])
      #print("T")
      #print(subset)
      
      startid <- as.integer(rownames(head(subset, n=1L)))
      endid <- as.integer(rownames(tail(subset, n=1L)))
      
      #print(startid)
      #print(endid)
      
      activity <- 0
      addtime <- 0
      
      if (length(startid) != 0 && length(endid) != 0) {
        
        #get unique locations of the time part
        unqlatlong <- unique(data.cus[startid:endid,c("lat","long")])
        rownames(unqlatlong) <- seq(length=nrow(unqlatlong))
        unqlatlong$activity <- 0
        #print(unqlatlong)
        
        for (j in c(startid:endid)){
          #--------- set the previous record number ----------------------
          if (j == startid && startid == 1) {
            jPrev <- 1        
          }
          else {
            jPrev <- j-1
          }
          
          t0 <- as.numeric(data.cus[jPrev,"datetime"], units = "mins")
          t1 <- as.numeric(data.cus[j,"datetime"], units = "mins")
          lat0 <- data.cus[jPrev,"lat"]
          lat1 <- data.cus[j,"lat"]
          long0 <- data.cus[jPrev,"long"]
          long1 <- data.cus[j,"long"]
          
          #--------Activity Tracking, any movement is tracked ---------
          if (abs(lat0-lat1) > 0 || abs(long0-long1) > 0) {
            
            prevValue <- unqlatlong[unqlatlong$lat == lat1 & unqlatlong$long == long1,"activity"]
            unqlatlong[unqlatlong$lat == lat1 & unqlatlong$long == long1,"activity"] <- prevValue + 1
            
          }
          #------------------------------------------------------------
          
        }
        #--for loop ends -------------------------
        
        for (l in 1:nrow(unqlatlong)) {
          newrow <- iter.cus[i,1:2]
          newrow$daypart <- item
          newrow$lat <- unqlatlong[l,"lat"]
          newrow$long <- unqlatlong[l,"long"]   
          newrow$activity <- unqlatlong[l,"activity"]   
          empty.df[nrow(empty.df)+1,] <- newrow
          #print(newrow)
          #print(empty.df)
        }
        
      }
      
    }
    print(iter.cus[i,] )   
    #--for loop ends for customer + date combo -------------------------
  }
  
  #retdata  <- iter.cus
  #print(empty.df)
  empty.df
  
}



#------------------ sample test data set for getTrips ----------------
starthour <- c(0:23)
endhour <- c(1:24)
top5Cus <- c("customer_759","customer_996", "customer_553","customer_147", "customer_143")
countdf <- telcomSub[telcomSub$customerid %in% top5Cus,]
locHops <- getHopsInGeoCoord(countdf, data.frame(starthour, endhour))

locHops$latlong <- paste(as.character(locHops$lat),"-",as.character(locHops$long),sep="")

save(locHops, file="D:\\Data Mining\\04-PdpChallenge\\Inputs\\locHops.RData" )
# load(D:\\Data Mining\\04-PdpChallenge\\Inputs\\hourly.RData")



# ---------- plotting of values from analysis ---------------
library(sqldf)
library(ggplot2)
cPalette <- c("Black", "Dark Red", "Blue", "Pink", "Yellow", "Orange", "Red", "Azure")
limits <- c("12am","1am","2am","3am","4am","5am","6am","7am","8am","9am","10am","11am","12pm","1pm","2pm","3pm","4pm","5pm","6pm","7pm","8pm","9pm","10pm","11pm")


topLoc5 <- sqldf("Select customerid, latlong, count(*) as locdiverse from locHops
  GROUP BY customerid, latlong
   ORDER BY customerid, locdiverse DESC")

topLoc5hourly <- subset(topLoc5, customerid == top5Cus[4])[1:5,]
rownames(topLoc5hourly) <- seq(length=nrow(topLoc5hourly))

focusCus <- locHops[locHops$customerid == unique(topLoc5hourly$customerid) & locHops$latlong %in% topLoc5hourly$latlong,]

# ---------- Total activities/transitions/movements made by all customers in each hour ---------------
topLocHopagg <- aggregate(focusCus$activity,
                       list(daypart = focusCus$daypart, latlong = focusCus$latlong),
                       avg)

#----fill in the hours with no activity with zeros-----------
focusCusAll <- topLocHopagg[1,]
focusCusAll <- focusCusAll[-1,]
iter <- 0

for (x in 1:5) {
  for (y in 1:24) {
    iter <- iter + 1
    focusCusAll[iter,"daypart"] <- y
    focusCusAll[iter,"latlong"] <- topLoc5hourly[x,"latlong"]
    focusCusAll[iter,"x"] <- 0
  }
}

focusCusFinal <- merge(focusCusAll, topLocHopagg, all=TRUE) 
      


ggplot(data=focusCusFinal, aes(x=daypart, y=x, group=latlong, colour=factor(latlong))) + 
  #stat_smooth(span = 0.1, se = FALSE) +
  #scale_colour_manual(values=cPalette, name="latlong") + 
  scale_x_discrete(limits=limits) + 
  ylab("Avg Activities") +
  geom_point() +
  geom_line() +
  theme(axis.title.y = element_text(size = rel(1.8), angle = 90)) +
  theme(axis.title.x = element_text(size = rel(1.8), angle = 00)) +
  theme(axis.text.y = element_text(size = rel(1.5), angle = 00, color="Dark Green")) +
  theme(axis.text.x = element_text(size = rel(1.5), angle = 00, color="Dark Red")) +  
  theme(legend.text = element_text(size = rel(1.8), angle = 00)) +
  theme(legend.title = element_text(size = rel(1.8), angle = 00)) +
  theme( axis.line.y = element_line(colour = "Dark Green", 
                                    size = 1, linetype = "solid")) +
  theme( axis.line.x = element_line(colour = "Dark Red", 
                                    size = 1, linetype = "solid"))


#----------- print top locations ---------------
library(ggmap)
revlocs <- sqldf("Select distinct lat, long from focusCus")
result <- do.call(rbind,
                  lapply(1:nrow(revlocs),
                         function(i) revgeocode(c(revlocs[i,"long"], revlocs[i,"lat"]))))
revlocs <- cbind(revlocs, result)
revlocs



