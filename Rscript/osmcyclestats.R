library(osmar)
library(rgeos)
library(rgdal)
library(knitr)
library(sp)
library(ROAuth)
library(twitteR)
library(RCurl)
library(plyr)
library(SortableHTMLTables)
library(log4r)
library(rjson)
library(RJSONIO)

#system("wget -O /home/tim/github/cycle-map-stats/R scripts/glasgow.osm \"http://overpass-api.de/api/interpreter?data=way[%22highway%22]%2855.30570111642547,-5.3887939453125,56.74669909639952,-2.49114990234375%29;out%20body;%3E;out%20skel;\"")

#system("wget -O /home/tim/github/R scripts/map.osm \"http://overpass-api.de/api/interpreter?data=%3C!--%0AThis%20has%20been%20generated%20by%20the%20overpass-turbo%20wizard.%0AThe%20original%20search%20was%3A%0A%E2%80%9Chighway%E2%80%9D%0A--%3E%0A%3Cosm-script%20output%3D%22json%22%20timeout%3D%2225%22%3E%0A%20%20%3C!--%20gather%20results%20--%3E%0A%20%20%3Cunion%3E%0A%20%20%20%20%3C!--%20query%20part%20for%3A%20%E2%80%9Chighway%E2%80%9D%20--%3E%0A%20%20%20%20%3Cquery%20type%3D%22node%22%3E%0A%20%20%20%20%20%20%3Chas-kv%20k%3D%22highway%22%2F%3E%0A%20%20%20%20%20%20%3Cbbox-query%20s%3D%2255.74102787471819%22%20w%3D%22-4.50714111328125%22%20n%3D%2255.98071368329446%22%20e%3D%22-3.992156982421875%22%2F%3E%0A%20%20%20%20%3C%2Fquery%3E%0A%20%20%20%20%3Cquery%20type%3D%22way%22%3E%0A%20%20%20%20%20%20%3Chas-kv%20k%3D%22highway%22%2F%3E%0A%20%20%20%20%20%20%3Cbbox-query%20s%3D%2255.74102787471819%22%20w%3D%22-4.50714111328125%22%20n%3D%2255.98071368329446%22%20e%3D%22-3.992156982421875%22%2F%3E%0A%20%20%20%20%3C%2Fquery%3E%0A%20%20%20%20%3Cquery%20type%3D%22relation%22%3E%0A%20%20%20%20%20%20%3Chas-kv%20k%3D%22highway%22%2F%3E%0A%20%20%20%20%20%20%3Cbbox-query%20s%3D%2255.74102787471819%22%20w%3D%22-4.50714111328125%22%20n%3D%2255.98071368329446%22%20e%3D%22-3.992156982421875%22%2F%3E%0A%20%20%20%20%3C%2Fquery%3E%0A%20%20%3C%2Funion%3E%0A%20%20%3C!--%20print%20results%20--%3E%0A%20%20%3Cprint%20mode%3D%22body%22%2F%3E%0A%20%20%3Crecurse%20type%3D%22down%22%2F%3E%0A%20%20%3Cprint%20mode%3D%22skeleton%22%20order%3D%22quadtile%22%2F%3E%0A%3C%2Fosm-script%3E\"")

system("wget -O /home/tim/github/localtivate/Rscripts/localtivate.osm \"http://overpass-api.de/api/interpreter?data=way[%22highway%22]%2855.7476,-4.5634,55.9849,-3.8658%29;out%20body;%3E;out%20skel;\"")



setwd("/home/tim/R/polys")
download.file("http://download.geofabrik.de/europe/great-britain/scotland-latest.osm.bz2",
              "scotland-latest.osm.bz2")




system("bzip2 -d scotland-latest.osm.bz2")

setwd("/home/tim/github/cycle-map-stats/Rscript/reduced")

files  <- list.files(pattern ='\\.poly$')
files1 <- list(files)
number <- length(list.files(pattern ='\\.poly$'))

setwd("/home/tim/github/cycle-map-stats/Rscript")

stats <- lapply(files1, function(name){
  
  osmosis1 <- paste("osmosis --read-xml file=localtivate.osm --tf accept-ways highway=* --used-node idTrackerType=Dynamic --bounding-polygon file=",(name)," --write-xml file=",(name),".osm",sep="")
  
  return(osmosis1)
})

for (i in 1:(number)){
  system(stats[[1]][i])
}


setwd("/home/tim/github/cycle-map-stats/Rscript/reduced")

files2  <- list.files(pattern ='\\.poly.osm$')
files2 <- list(files2)

stats3 <- lapply(files2[[1]], function(osm2){
  
  ua <- get_osm(complete_file(), source = osmsource_file(osm2))
  
  return(ua)
})

NCN_length <- lapply(stats3, function(osm4){
  test<-osm4$relations$tags$v == "ncn"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids <- find(osm4, relation(tags(v=="ncn")))
    hwr_ids <- find_down(osm4, relation(hwr_ids))
    hwr1 <- subset(osm4, ids = hwr_ids)
    ncn_poly <- as_sp(hwr1, "lines")
    ncnUTM <-spTransform(ncn_poly,CRS("+proj=utm")) 
    ncnLength <- SpatialLinesLengths(ncnUTM)
    ncnLength <- sum(ncnLength)
    ncnLength <- ncnLength / 1000
    ncnLength <- round(ncnLength, digits=1)
    return(ncnLength)
  }})

non.null.list <- lapply(NCN_length, function(x){
  ifelse(is.null(x), NA, x)})

NCN_lengths <- rbind.fill(lapply(non.null.list, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) # removing null values from NCN length (const without NCN network) and creating data.frame of lengths

NCN_Proposed <- lapply(stats3, function(osm4){
  test<-osm4$relations$tags$v == "proposed"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids2 <- find(osm4, relation(tags(v=="proposed")))
    hwr_ids2 <- find_down(osm4, relation(hwr_ids2))
    hwr2 <- subset(osm4, ids = hwr_ids2)
    ncn_p_poly <- as_sp(hwr2, "lines")
    ncnUTMp <-spTransform(ncn_p_poly,CRS("+proj=utm")) 
    ncnLengthp <- SpatialLinesLengths(ncnUTMp)
    ncnLengthp <- sum(ncnLengthp)
    ncnLengthtrue <- round(ncnLengthp, digits=1)
    ncnLengthtrue <- ncnLengthtrue / 1000
    return(ncnLengthtrue)
  }})
non.null.list <- lapply(NCN_Proposed, function(x){
  ifelse(is.null(x), NA, x)})

NCN_Propose <- rbind.fill(lapply(non.null.list, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) 

Mtbr <- lapply(stats3, function(osm4){
  test<-osm4$relations$tags$v == "mtb"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids2 <- find(osm4, relation(tags(v=="mtb")))
    hwr_ids2 <- find_down(osm4, relation(hwr_ids2))
    hwr2 <- subset(osm4, ids = hwr_ids2)
    ncn_p_poly <- as_sp(hwr2, "lines")
    ncnUTMp <-spTransform(ncn_p_poly,CRS("+proj=utm")) 
    ncnLengthp <- SpatialLinesLengths(ncnUTMp)
    ncnLengthp <- sum(ncnLengthp)
    ncnLengthtrue <- round(ncnLengthp, digits=1)
    ncnLengthtrue <- ncnLengthtrue / 1000
    return(ncnLengthtrue)
  }})
non.null.list <- lapply(Mtbr, function(x){
  ifelse(is.null(x), NA, x)})

Mtbr <- rbind.fill(lapply(non.null.list, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) 

Mtbr <- replace(Mtbr, is.na(Mtbr), 0)

Cycleway <- lapply(stats3, function(osm4){
  test<-osm4$ways$tags$v == "cycleway"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids2 <- find(osm4, way(tags(v=="cycleway")))
    hwr_ids2 <- find_down(osm4, way(hwr_ids2))
    hwr2 <- subset(osm4, ids = hwr_ids2)
    ncn_p_poly <- as_sp(hwr2, "lines")
    ncnUTMp <-spTransform(ncn_p_poly,CRS("+proj=utm")) 
    ncnLengthp <- SpatialLinesLengths(ncnUTMp)
    ncnLengthp <- sum(ncnLengthp)
    ncnLengthtrue <- round(ncnLengthp, digits=1)
    ncnLengthtrue <- ncnLengthtrue / 1000
    return(ncnLengthtrue)
  }})
non.null.list2 <- lapply(Cycleway, function(x){
  ifelse(is.null(x), NA, x)})

Cycleway <- rbind.fill(lapply(non.null.list2, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) 

Mtb <- lapply(stats3, function(osm4){
  test<-osm4$ways$tags$v == "mtb"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids2 <- find(osm4, way(tags(v=="mtb")))
    hwr_ids2 <- find_down(osm4, way(hwr_ids2))
    hwr2 <- subset(osm4, ids = hwr_ids2)
    ncn_p_poly <- as_sp(hwr2, "lines")
    ncnUTMp <-spTransform(ncn_p_poly,CRS("+proj=utm")) 
    ncnLengthp <- SpatialLinesLengths(ncnUTMp)
    ncnLengthp <- sum(ncnLengthp)
    ncnLengthtrue <- round(ncnLengthp, digits=1)
    ncnLengthtrue <- ncnLengthtrue / 1000
    return(ncnLengthtrue)
  }})
non.null.list2 <- lapply(Mtb, function(x){
  ifelse(is.null(x), NA, x)})

Mtb <- rbind.fill(lapply(non.null.list2, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) 

Mtb <- replace(Mtb, is.na(Mtb), 0) 

TotalMtb <- Mtb + Mtbr

Highway <- lapply(stats3, function(osm4){
  test<-osm4$ways$tags$k == "highway"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids2 <- find(osm4, way(tags(k=="highway")))
    hwr_ids2 <- find_down(osm4, way(hwr_ids2))
    hwr2 <- subset(osm4, ids = hwr_ids2)
    ncn_p_poly <- as_sp(hwr2, "lines")
    ncnUTMp <-spTransform(ncn_p_poly,CRS("+proj=utm")) 
    ncnLengthp <- SpatialLinesLengths(ncnUTMp)
    ncnLengthp <- sum(ncnLengthp)
    ncnLengthtrue <- round(ncnLengthp, digits=1)
    ncnLengthtrue <- ncnLengthtrue / 1000
    return(ncnLengthtrue)
  }})
non.null.list3 <- lapply(Highway, function(x){
  ifelse(is.null(x), NA, x)})

Highway <- rbind.fill(lapply(non.null.list3, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) 


##### need to analysis different types of highwway making up relations?

NCNdata <- lapply(stats3, function(osm4){
  test<-osm4$relations$tags$v == "ncn"
  test2<- (any(test == TRUE))
  if(test2==TRUE){
    hwr_ids <- find(osm4, relation(tags(v=="ncn")))
    hwr_ids <- find_down(osm4, relation(hwr_ids))
    hwr1 <- subset(osm4, ids = hwr_ids)
    return(hwr1)
  }})


NCNcycleways <- lapply(NCNdata, function(osm5){
  test<-osm5$ways$tags$v == "cycleway"
  test2<- (any(test == TRUE))
  if(test2==TRUE){  
    hwr_ids <- find(osm5, way(tags(v == "cycleway")))
    hwr_ids <- find_down(osm5, way(hwr_ids))
    hwr1 <- subset(osm5, ids = hwr_ids)
    cycleway_poly <- as_sp(hwr1, "lines")
    cyclewayUTM <-spTransform(cycleway_poly,CRS("+proj=utm")) 
    cyclewayLength <- SpatialLinesLengths(cyclewayUTM)
    cyclewayLength <- sum(cyclewayLength)
    cyclewayLength <- cyclewayLength / 1000
    cyclewayLength <- round(cyclewayLength, digits=1)
    return(cyclewayLength)
  }}) 

non.null.list <- lapply(NCNcycleways, function(x){
  ifelse(is.null(x), NA, x)})

NCNcycleways <- rbind.fill(lapply(non.null.list, function(f) {
  as.data.frame(Filter(Negate(is.null), f))
})) 

NCNcyclewaymap <- lapply(NCNdata, function(osm4){
  test<-osm4$ways$tags$v == "cycleway"
  test2<- (any(test == TRUE))
  if(test2==TRUE){  
    hwr_ids <- find(osm4, way(tags(v == "cycleway")))
    hwr_ids <- find_down(osm4, way(hwr_ids))
    hwr1 <- subset(osm4, ids = hwr_ids)
    return(hwr1)
  }})

for (i in 1:(number)){
  test <- NCNcyclewaymap[i] == "NULL"
  test2 <- (any(test == TRUE))
  if(test2==TRUE){
    NCNcyclewaymap[i] <- "NA"}}

stats4 <- lapply(NCNdata, function(osm3){
  usersways <-(unique((osm3)$nodes$attrs$user))
  usersways <- as.character(usersways)
  usersways <- data.frame(usersways)
  return(usersways)
}) # unique user names on nodes per area

stats5 <- lapply(NCNdata, function(osm3){
  usersways <- (unique((osm3)$ways$attrs$user))
  usersways <- as.character(usersways)
  usersways <- data.frame(usersways)
  return(usersways)
}) # unique user names on ways per area

allconusers <- lapply(stats4, function(x){
  conusers <- data.frame(x)
  conusers2 <- length(levels(conusers$usersways))
  return(conusers2)
})

AllUsers <- rbind.fill(lapply(allconusers, function(f) {
  as.data.frame(f)
})) # user numbers from ways

nodeallconusers <- lapply(stats5, function(x){
  conusers <- data.frame(x)
  conusers2 <- length(levels(conusers$usersways))
  return(conusers2)
})

AllUsers2 <- rbind.fill(lapply(nodeallconusers, function(f) {
  as.data.frame(f)
}))  # user numbers from nodes



names <- strsplit(files, ".poly")
namesall <- gsub("_", " ", names)
names3 <- rbind.fill(lapply(namesall, function(Name) {
  as.data.frame(Name)
})) ## file names list removing .poly from end


ncndata <- names3
ncndata$'NCN total length km' <- round(NCN_lengths / 2, digit=1)
ncndata$'NCN total length km' <- replace(ncndata$'NCN total length km', is.na(ncndata$'NCN total length km'), 0) 
ncndata$'NCN proposed km' <- round(NCN_Propose / 2, digit=1)
ncndata$'NCN proposed km' <- replace(ncndata$'NCN proposed km', is.na(ncndata$'NCN proposed km'), 0) 
ncndata$'NCN current length km' <- (ncndata$'NCN total length km' - ncndata$'NCN proposed km')
ncndata$'Number of OSM Contributors' <- (AllUsers$f + AllUsers2$f)
ncndata$'Length Cyclepath within NCN km' <- NCNcycleways
ncndata$'Percentage of NCN Cyclepath' <- (100/ncndata$'NCN total length km') * ncndata$'Length Cyclepath within NCN km'
ncndata$'Percentage of NCN Cyclepath' <- round(ncndata$'Percentage of NCN Cyclepath', digit=1)
ncndata$'Total Highway (roads and paths)' <- round(Highway, digit=1)
ncndata$'Total cycleway (in or out of NCN network)' <- round(Cycleway, digit=1)
ncndata$'Current NCN Vs total highway length' <- (ncndata$'NCN current length km' / ncndata$'Total Highway (roads and paths)')
ncndata$'Current NCN Vs total highway length' <- round(ncndata$'Current NCN Vs total highway length', digit=5)
ncndata$'Total MTB only cycleway'<- round(TotalMtb, digit=2)

toJSON(data.frame((ncndata))
sortable.html.table(ncndata, 'sample.html', 'sandbox')
toJSON(ncndata)
unlist(NCN_lengths)


######################## Maps ##############################
for (i in 1:(number)){
  test <- NCNdata[i] == "NULL"
  test2 <- (any(test == TRUE))
  if(test2==TRUE){
    NCNdata[i] <- "NA"}}  


maps <- lapply(NCNdata, function(x){
  test <- x == "NA"
  test2<- (any(test == TRUE))
  if(test2==FALSE){
    map<- as_sp(x, "lines")
    return(map)
  }})


for (i in 1:(number)){
  test <- stats3[i] == "NA"
  test2<- (any(test == TRUE))
  if(test==FALSE){
    hmaps <- lapply(stats3, function(x){
      map <- as_sp(x, "lines")
    })
  }}

for (i in 1:(number)){
  test <- NCNcyclewaymap[i] == "NULL"
  test2 <- (any(test == TRUE))
  if(test2==TRUE){
    NCNcyclewaymap[i] <- "NA"}} 


cmaps <- lapply(NCNcyclewaymap, function(x){
  test <- x == "NA"
  test2<- (any(test == TRUE))
  if(test2==FALSE){
    map<- as_sp(x, "lines")
    return(map)
  }})

#Write as geojson
writeOGR(cmaps[[1]], 'dataMap.geojson','cmaps', driver='GeoJSON')



for (i in 1:(number)){  
  test <- cmaps[i] == "NULL"
  test4<- (any(test == TRUE))
  if(test4==FALSE){
    nfiles <- paste(filename="/home/tim/R/polys/sandbox/plot",(i),".png",sep="")
    png(nfiles)
    plot(hmaps[[i]], col="gray")
    plot(maps[[i]], add=TRUE, col="red")
    plot(cmaps[[i]], add=TRUE, col="blue")
    title(main=namesall[i], col="black")
    dev.off()  
  }}



