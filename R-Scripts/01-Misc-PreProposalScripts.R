mdata <- as.table(rbind(c(15, 23, 42.01, 23, 50, 1150, 37),
c(12, 43, 59.93, 28, 70, 1960, 37),
c(64, 229, 319.27,12,84, 1008, 25),
c(12, 45, 62.07, 29, 73, 2117, 30),
c(28, 39,74.21, 9, 30, 270, 40),
c(71, 102, 191.5, 10, 63, 630, 20),
c(23, 64, 95.16, 9, 74, 666, 10),
c(25, 102, 138.14, 72,30, 2160, 80),
c(48, 230, 301.78, 26, 30, 780, 35),
c(32, 50, 90.62, 6, 45, 270, 15),
c(90, 200, 318.4, 8, 45, 360,15),
c(16, 100, 125.56, 34, 55, 1870, 49) ))


install.packages("sdcMicro", depend= TRUE) #Install
library(sdcMicro) 


library(fields)
threshold.in.km <- 1.5

dist <- rdist.earth(geod,miles = F,R=6371) #dist <- dist(data) if data is UTM
fit <- hclust(as.dist(dist), method = "single")
clusters <- cutree(fit,h = 10) #h = 2 if data is UTM
plot(geod$lat, geod$long, col = clusters, pch = 20)
clusters

install.packages("deldir", depend= TRUE) #Install
library(deldir)
library(ggplot2)
voronoi <- deldir(geod$lat, geod$long)

ggplot(data=geod, aes(x=geod$lat,y=geod$long)) +
  #Plot the voronoi lines
  geom_segment(
    aes(x = x1, y = y1, xend = x2, yend = y2),
    size = 2,
    data = voronoi$dirsgs,
    linetype = 1,
    color= "#FFB958") + 
  #Plot the points
  geom_point(
    fill=rgb(70,130,180,255,maxColorValue=255),
    pch=21,
    size = 4,
    color="#333333") +
  #(Optional) Specify a theme to use
  ltd_theme

install.packages("ggmap", depend= TRUE) #Install

library(ggmap)
get_googlemap(urlonly = TRUE)
ggmap(get_googlemap())
# markers and paths are easy to access
d <- function(x=1.3, y=103, n,r,a){
  round(data.frame(
    lon = jitter(rep(x,n), amount = a),
    lat = jitter(rep(y,n), amount = a)
  ), digits = r)
}
df <- d(n=50,r=3,a=.3)
map <- get_googlemap(markers = df, path = df,, scale = 2)
ggmap(map)

lt <- rep(c(1:6), each=6)
lg <- rep(1:6, times=6)

voronoi <- deldir(lt, lg)

ggplot(data=as.data.frame(cbind(lt, lg)), aes(x=lt,y=lg)) +
  #Plot the voronoi lines
  geom_segment(
    aes(x = x1, y = y1, xend = x2, yend = y2),
    size = 2,
    data = voronoi$dirsgs,
    linetype = 1,
    color= "#FFB958") + 
  #Plot the points
  geom_point(
    fill=rgb(70,130,180,255,maxColorValue=255),
    pch=21,
    size = 4,
    color="#333333")


-----
  
  sing <- get_map(location="singapore")
  ggmap(sing, extent = "normal")


df <- read.csv("D:/Data Mining/04-PdpChallenge/Inputs/DataPrepTelCom-latlongcount.csv")
geod <- as.data.frame(df)
str(geod)
geod$bin=cut(geod$freq, c(1,50,100,500,1000,2000,3000,Inf), include.lowest=TRUE)


theme_set(theme_bw(16))
singMap <- qmap("singapore", zoom = 11, color = "bw", legend = "topleft")

singMap +
  geom_point(aes(x = long, y = lat, colour = bin, size = bin),
             data = geod)



---plot SLA data for singapore matrices
install.packages("rgdal")
install.packages("maptools")
install.packages("rgeos")
gpclibPermit()

library(maptools)
library(rgdal)
library(ggplot2)

fn <- 'D:/Data Mining/04-PdpChallenge/Mapping/SLA_CADASTRAL_MAP_INDEX.kml'
fn2 <- 'D:/Data Mining/04-PdpChallenge/Mapping/sla-cadastral-land-lot/sla-cadastral-land-lot.kmz'

#Look up the list of layers
ogrListLayers(fn)

kml <- readOGR(fn,layer='SLA_CADASTRAL_MAP_INDEX')

#This seems to work for plotting boundaries:
plot(kml)

kml <- spTransform(kml, CRS("+proj=longlat +datum=WGS84"))
kml <- fortify(kml)

singMap + geom_polygon(aes(x=long, y=lat, group=group), fill=as.factor(rownames(kml)), size=.2,color='red', data=kml, alpha=0) + geom_point(aes(x = long, y = lat, colour = bin, size = bin),
             data = geod) 


library(maptools)
library(rgdal)
library(ggplot2)
fn2 <- 'D:/Data Mining/04-PdpChallenge/Mapping/sla-cadastral-land-lot/cadastral_land_lot.kml'
kml2 <- readOGR(fn2,layer='Cadastral_Land_Lot')
kml2 <- spTransform(kml2, CRS("+proj=longlat +datum=WGS84"))
kml2 <- fortify(kml2)

singMap + geom_polygon(aes(x=long, y=lat, group=group), fill=as.factor(rownames(kml)), size=.2,color='red', data=kml2, alpha=0) + geom_point(aes(x = long, y = lat, colour = bin, size = bin),
                                                                                                                                            data = geod) 

