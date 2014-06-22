stats <- read.csv(file="/home/tim/github/cycle-map-stats/Rscript/statstable.csv",check.name=F)

statsGeo <- toJSON(data.frame((stats)))

write(statsGeo, file="/home/tim/github/cycle-map-stats/statstable.json")

library(googleVis)

stats[1]
dat <- stats[,c("Total length of highways","Total cycleway km")]
dat <- dat[1,]
dat <- dat[1:2,]
dat <- stats[,c("Name","Percentage of NCN Cyclepath")]
library(reshape2)
stats2 <- melt(stats)
dat <- stats2[43:56,] stats[1:3,]
dat <- dat[1,]
df[,c('v1','v2')]
stats2[1,]
dcast(stats2, "Total cycleway km" + "Total length of highways" ~ "value")
doughnut <- gvisPieChart(Kelvin,
                         options=list(
                           width=500,
                           height=500,
                       #    slices="{0: {offset: 0.2},
#1: {offset: 0.2},
#2: {offset: 0.2}}",
                           title='Total length of highways vs cycleway',
                           legend='none',
                           colors="['black','green',]",
                           pieSliceText='label',
                           pieHole=0.5),
                         chartid="doughnut")
plot(doughnut)


Kelvin <- data.frame(path.type=c("highway", "cycleway"),
                  length.km=c(337, 17.4))


