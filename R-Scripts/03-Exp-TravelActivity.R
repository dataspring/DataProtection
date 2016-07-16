

#telcom <- read.csv("D:/Data Mining/04-PdpChallenge/Inputs/DataPrepTelCom.csv")
#geocount <- read.csv("D:/Data Mining/04-PdpChallenge/Inputs/DataPrepTelCom-latlongcount.csv")
#telcomSub <- telcom[order(telcom$customerid, telcom$locdatetime),]
 
getTrips <- function (data, daypart, threshold)
{

  data$date <- as.Date(data$locdatetime)
  data$datetime <- as.POSIXct(data$locdatetime)
  data$locdatetime <- NULL
  
  iter.cus <- as.data.frame(unique(data[, c("customerid", "date")]))
  iter.cus <- iter.cus[order(iter.cus$customerid, iter.cus$date),]
  
  #---create a empty data frame to hold row wise data result---------
  empty.df <- iter.cus[1,]
  empty.df$daypart <- 0
  empty.df$trip <- 0
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
      
      daypartCount <- daypartCount + 1
      daypartColName <- paste("daypart",as.character(daypartCount),sep="" )
      
      starthour <- daypart[item, "starthour"]
      endhour <- daypart[item, "endhour"]
      
      iter.cus[i, daypartColName] <- 0
    
      subset <- data.cus[data.cus$datetime >= (as.POSIXct(as.character(iter.cus[i,"date"])) + starthour * 60 * 60) & data.cus$datetime < (as.POSIXct(as.character(iter.cus[i,"date"])) + endhour * 60 * 60), ] 
      #print(daypart[item,])
      #print("T")
      #print(subset)
      
      startid <- as.integer(rownames(head(subset, n=1L)))
      endid <- as.integer(rownames(tail(subset, n=1L)))
      
      #print(startid)
      #print(endid)
      
      trip <- 0
      activity <- 0
      addtime <- 0
      
      if (length(startid) != 0 && length(endid) != 0) {
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
              activity <- activity + 1
            }
            #------------------------------------------------------------
          
            #--------Trip Tracking with 30 min of stay considered a stop ---------
            if (abs(t0-t1) > threshold*60) {
              if (abs(lat0-lat1) > 0 || abs(long0-long1) > 0) {
                trip <- trip + 1
                addtime <- 0  
              }
            }
            else {
              if (abs(lat0-lat1) > 0 || abs(long0-long1) > 0) {
                if (addtime > 15) {
                  trip <- trip + 1
                  addtime <- 0    
                }
              }
              else {
                addtime <- addtime + 15
              }
            }
            #--------------------------------------------------------------
        }
        #--for loop ends -------------------------
      }
          
      iter.cus[i,daypartColName] <- trip
      
      newrow <- iter.cus[i,1:2]
      newrow$daypart <- item
      newrow$trip <- trip
      newrow$activity <- activity
      
      empty.df[nrow(empty.df)+1,] <- newrow
      
     }
      print(iter.cus[i,] )   
    #--for loop ends for customer + date combo -------------------------
  }
  
  #retdata  <- iter.cus
  retdata  <- empty.df
  retdata
}


#------------------ sample test data set for getTrips ----------------
starthour <- c(0:23)
endhour <- c(1:24)
sample <- getTrips(telcomSub[1:50,], data.frame(starthour, endhour), 30)


# -------- day part trips analysis -------------------
starthour <- c(0, 6, 11, 16, 21)
endhour <- c(6, 11, 16, 21, 24)
part5 <- getTrips(telcomSub, data.frame(starthour, endhour), 30)


save(part5, file="D:\\Data Mining\\04-PdpChallenge\\Inputs\\daypart5.RData" )
# load(D:\\Data Mining\\04-PdpChallenge\\Inputs\\daypart5.RData")


# -------- hourly trip analysis -------------------
starthour <- c(0:23)
endhour <- c(1:24)
hourly <- getTrips(telcomSub, data.frame(starthour, endhour), 30)
hourly$weekday <- weekdays(hourly[,"date"], abbreviate=TRUE)


save(hourly, file="D:\\Data Mining\\04-PdpChallenge\\Inputs\\hourly.RData" )
# load(D:\\Data Mining\\04-PdpChallenge\\Inputs\\hourly.RData")



# ---------- plotting of values from analysis ---------------
library(ggplot2)
cPalette <- c("Black", "Dark Green", "Blue", "Pink", "Yellow", "Orange", "Red", "Azure")
weekfactor <- factor(hourlytrip$weekday, levels = c("Mon","Tue","Wed","Thu","Fri","Sat","Sun"))
limits <- c("12am","1am","2am","3am","4am","5am","6am","7am","8am","9am","10am","11am","12pm","1pm","2pm","3pm","4pm","5pm","6pm","7pm","8pm","9pm","10pm","11pm")

# at <- as.data.frame(colSums(Filter(is.numeric, hourly))/1)
# colnames(at) <- c("y")
# at$day <- rownames(at)
# at$x <- seq(length=nrow(at))
# rownames(at) <- seq(length=nrow(at))
# qplot(at$x, at$y, geom='smooth',span =0.1,xlab="Hours", ylab="Trips", color="red")


# ---------- Total activities/transitions/movements made by all customers in each hour ---------------
hourlyagg <- aggregate(hourly$activity,
                       list(daypart = hourly$daypart, weekday = hourly$weekday),
                       sum)
hourlyagg$weekday <- weekfactor


ggplot(data=hourlyagg, aes(x=daypart, y=x, group=weekday, colour=factor(weekday))) + 
  stat_smooth(span = 0.2, se = FALSE) +
  scale_colour_manual(values=cPalette, name="weekday") + 
  scale_x_discrete(limits=limits) + 
  ylab("Total Activities") 

# ---------- Total Trips made by all customers in each hour ---------------
hourlytrip <- aggregate(hourly$trip,
                       list(daypart = hourly$daypart, weekday = hourly$weekday),
                       sum)
hourlytrip$weekday <- weekfactor


ggplot(data=hourlytrip, aes(x=daypart, y=x, group=weekday, colour=factor(weekday))) + 
  stat_smooth(span = 0.2, se = FALSE) +
  scale_colour_manual(values=cPalette, name="weekday") + 
  scale_x_discrete(limits=limits) + 
  ylab("Total Trips") 

# ---------- Total Trips made by few top travelling customers in each hour ---------------

library(sqldf)

top5 <- sqldf("Select customerid, count(*) locdiverse from
(Select distinct customerid, lat, long from telcom) ds
GROUP BY customerid
ORDER BY locdiverse DESC limit 5")
top5hourly <- subset(hourly, customerid %in% top5$customerid)

top5hourlyhop <- aggregate(top5hourly$activity,
                        list(daypart = top5hourly$daypart, customerid = top5hourly$customerid),
                        sum)

ggplot(data=top5hourlyhop, aes(x=daypart, y=x, group=customerid, colour=factor(customerid))) + 
  #geom_line() +
  stat_smooth(span = 0.2, se = FALSE) +
  scale_colour_manual(values=cPalette, name="customerid") + 
  scale_x_discrete(limits=limits) + 
  ylab("Total Movements") +
  ylim(0, 50)


