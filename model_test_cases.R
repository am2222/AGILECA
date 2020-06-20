
#============================== data loading


nbs_ltable <- read.csv(here('data/nghb_test.txt'),sep=";", header=T, col.names=c("cid","direction","wind","hour","nb"))


column_names <- c("wkt","dggid","i","j","bearing","alpha","dem","luse")
lookup <- read.csv(here('data/lookupRes20.txt'),sep="|", header=FALSE, col.names=column_names)


#==============================model parameters

tr <- 0.6 # threshold for converting a burning cell into burned cell 
windCoef <- 1 #less value decreases the wind effect. for example 0.17 makes all the wind directions be in a same
# range. 1 exagerates the wind effect. 
elevCoef <- 1

m <- 1
optimizationInteraval <- 10
newFireThershold <-3000
#============================== read wind data

wind <-filter(nbs_ltable,hour==1)%>%
  dplyr::select("cid","nb","direction","wind")%>%
  mutate(wind= case_when(
    direction==1 ~ as.numeric(1/5),
    direction==4 ~ as.numeric(5),
    TRUE  ~ as.numeric(0)))
#==============================  test wind sensitivity

testWind <- function(maxiteration,wind,windCoef){
  wind <- mutate(wind, wind=exp(windCoef*wind),optweight=1)
  
  
  df <- dplyr::select(lookup,"dggid","wkt","i","j","dem","luse")
  df$state <-0
  df$sumr <- 0
  # set some sells in fire 
  df <- within(df, state[dggid %in% c(15099154439)] <- 1)
  #============================== 
  
  #TODO: Apply other landuse weights. 
  # you can apply vegetation density and vegetation type or ..
  # 1 needleleaf forest 
  # 2 tiga needleleaf
  # 3 braodleaf evergreen forest R~ 0.0058
  # 4, 5 deciduous evergreen 
  # 6 Mixed Forest
  # 8 shurbland R ~ 0.0082
  # 10 Grassland R ~ 0.0031
  # 14, 17, 18 wetland, urban, water ==0
  df <- mutate(df,"luse" = case_when( luse %in% c(17,18)  ~ as.numeric(0),
                                      luse %in% c(3,4,5,6) ~ as.numeric(0.75),
                                      luse %in% c(1,10,14)  ~ as.numeric(0.50),
                                      TRUE  ~ as.numeric(1)))%>% 
    dplyr::select("dggid","wkt",state,luse,dem,sumr)%>% 
    mutate(r0=luse)
  
  
  #==============================
  burningCells <- filter(df,state>0|sumr>0)%>%
    dplyr::select("dggid")
  potentialCells <- inner_join(burningCells,wind,by=c("dggid"="cid"))%>%
    dplyr::select("dggid"=nb)%>%
    dplyr::union(burningCells)
  
  
  df2 <- filter(df,dggid %in% potentialCells$dggid)
  
  
  j <- inner_join(df2,wind,by=c("dggid"="nb"))%>%
    inner_join(df2,c("cid"="dggid"))%>%
    mutate(elev=elevCoef*exp(atan(dem.x-dem.y)))%>%
    mutate(stw=case_when(
      state.y %in% c(1,2,3,4) ~ wind*optweight,
      TRUE ~ 0
    ))%>%
    group_by(dggid)%>%
    mutate(sumr1.x=case_when(
      state.x==0 ~ sum(stw),
      TRUE ~ 0
    ),nburn=sum(state.y))%>% # sum must remove the burned cells first
    ungroup()%>%
    mutate(sumr.x=sumr.x+(m*sumr1.x/max(stw)))%>%
    group_by(dggid)%>%
    dplyr::select(dggid,"wkt"=wkt.x,"dem"=dem.x,"state"=state.x,"sumr"=sumr.x,nburn,"r0"=r0.x,"luse"=luse.x)%>%
    distinct()%>%
    mutate(state = case_when(state==0 & nburn==0 ~ as.numeric(0),
                             state==0  & nburn>0 & sumr <tr ~ as.numeric(0),
                             state==0  & nburn>0 & sumr >tr ~ as.numeric(1),
                             state==1 ~ as.numeric(2),
                             state==2  ~ as.numeric(3),
                             state==3  ~ as.numeric(4),
                             state==4  ~ as.numeric(4)))
  
  
  
  
  #write.table(j, file = "test1.txt", row.names = FALSE, dec = ".", sep = "|", quote = FALSE)
  
  
  #======
  burningCells <-ungroup(j)%>% filter(state>0|sumr>0)%>%
    dplyr::select("dggid")
  potentialCells <- inner_join(burningCells,wind,by=c("dggid"="cid"))%>%
    dplyr::select(nb)%>%
    mutate(dggid=nb)%>%
    dplyr::select(dggid)%>%
    dplyr::union(burningCells)
  
  
  newnghbs <- filter(potentialCells, !dggid %in% j$dggid)
  
  df2 <- filter(df,dggid %in% newnghbs$dggid)%>%
    mutate(nburn=0)%>%
    dplyr::union(j)
  
  
  
  # get init time 
  
  
  name <- paste("wind_3_6_50it_c",windCoef)
  
  
  finalresults <- mutate(j,step=0)
  
  for (i in 1:maxiteration) {
    #print(i)
    
    if (i%%optimizationInteraval==0){
      # let's run optimization once
     # print("storing Data")
#       boundry <- filter(j)%>%
#         left_join(lookup,by=c("dggid","dggid"))%>%
#         dplyr::select(dggid,i,j,"wkt"=wkt.y,state)
      
      boundry <- filter(j)%>%
        left_join(lookup,by = c("dggid"))%>%
        dplyr::select(dggid,i,j,"wkt"=wkt.y,state)
      
      
      finalresults <- mutate(j,step=i)%>%
        dplyr::union(finalresults,j)
      
     # write.table(boundry, file =paste(i,name,"_data.txt",sep="") , row.names = FALSE, dec = ".", sep = "|", quote = FALSE)
      
      
    }
    
    
    
    #elev*wind*optweight*r0.y
    # df2nb <- filter(df2,!nburn==24 & !state==4)
    
    j <- inner_join(df2,wind,by=c("dggid"="nb"))%>%
      inner_join(df2,c("cid"="dggid"))%>%
      mutate(elev=elevCoef*exp(atan(dem.x-dem.y)))%>%
      mutate(stw=case_when(
        state.y %in% c(1,2,3,4) ~  wind, 
        TRUE ~ 0
      ))%>%
      group_by(dggid)%>%
      mutate(sumr1.x=case_when(
        state.x==0 ~ sum(stw),
        TRUE ~ 0
      ),nburn=sum(state.y))%>% # sum must remove the burned cells first
      ungroup()%>%
      mutate(sumr.x=sumr.x+(m*sumr1.x/max(stw)))%>%
      group_by(dggid)%>%
      dplyr::select(dggid,"wkt"=wkt.x,"dem"=dem.x,"state"=state.x,"sumr"=sumr.x,nburn,"r0"=r0.x,"luse"=luse.x)%>%
      distinct()%>%
      mutate(state = case_when(state==0 & nburn==0 ~ as.numeric(0),
                               state==0  & nburn>0 & sumr <tr ~ as.numeric(0),
                               state==0  & nburn>0 & sumr >tr ~ as.numeric(1),
                               state==1 ~ as.numeric(2),
                               state==2  ~ as.numeric(3),
                               state==3  ~ as.numeric(4),
                               state==4  ~ as.numeric(4)))
    
    
    
    
    
    #write.table(j, file = "test1.txt", row.names = FALSE, dec = ".", sep = "|", quote = FALSE)
    
    
    #======
    burningCells <-ungroup(j)%>% filter(state>0|sumr>0)%>%
      dplyr::select("dggid")
    potentialCells <- inner_join(burningCells,wind,by=c("dggid"="cid"))%>%
      dplyr::select(nb)%>%
      mutate(dggid=nb)%>%
      dplyr::select(dggid)%>%
      dplyr::union(burningCells)
    
    
    newnghbs <- filter(potentialCells, !dggid %in% j$dggid)
    
    df2 <- filter(df,dggid %in% newnghbs$dggid)%>%
      mutate(nburn=0)%>%
      dplyr::union(j)
    
    
    
  }
  
  return(finalresults)
}

#==============================  plot sensitivity data
plotResult <- function(data){
  sf_df = st_as_sf(data, wkt='wkt', crs = 4326)
  # sf_df <- st_transform(sf_df,st_crs(3857))
  # nc3_points <- sf::st_point_on_surface(sf_df)
  # nc3_coords <- as.data.frame(sf::st_coordinates(nc3_points))
  
  p <- ggplot() + 
    geom_sf(data=sf_df, aes(fill =  step), lwd=0, color=NA) +
    # scale_fill_viridis_c(option = "inferno") + 
    scale_fill_gradient(low="#DCDCDC", high="#708090")+
    theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          # panel.border = element_rect(colour = "black", fill=NA, size=1),
          panel.background = element_blank(),
          legend.position="none")
  # +coord_sf(datum=st_crs(3857))
  #p
  return(p)
}
#==============================  Plot the final result

finalPlot <- function(data){
  sf_df = st_as_sf(data, wkt='wkt', crs = 4326)
  # sf_df <- st_transform(sf_df,st_crs(3857))
  # nc3_points <- sf::st_point_on_surface(sf_df)
  # nc3_coords <- as.data.frame(sf::st_coordinates(nc3_points))
  
  p <- ggplot() + 
    geom_sf(data=sf_df, aes(fill =  state), lwd=0, color=NA)
  return(p) 
}

#==================landuse sensitiviy function



testLandUse <- function(maxiteration,wind,windCoef){
  wind <- mutate(wind, wind=exp(windCoef*wind),optweight=1)
  
  
  df <- dplyr::select(lookup,"dggid","wkt","i","j","dem","luse")
  df$state <-0
  df$sumr <- 0
  # set some sells in fire 
  df <- within(df, state[dggid %in% c(15102756420)] <- 1)
  #============================== 
  
  #TODO: Apply other landuse weights. 
  # you can apply vegetation density and vegetation type or ..
  # 1 needleleaf forest 
  # 2 tiga needleleaf
  # 3 braodleaf evergreen forest R~ 0.0058
  # 4, 5 deciduous evergreen 
  # 6 Mixed Forest
  # 8 shurbland R ~ 0.0082
  # 10 Grassland R ~ 0.0031
  # 14, 17, 18 wetland, urban, water ==0
  df <- mutate(df,"luse" = case_when( 
    luse %in% c(5,6) ~ as.numeric(0.2),
    TRUE  ~ as.numeric(1)))%>% 
    dplyr::select("dggid","wkt",state,luse,dem,sumr)%>% 
    mutate(r0=luse)
  
  
  #==============================
  burningCells <- filter(df,state>0|sumr>0)%>%
    dplyr::select("dggid")
  potentialCells <- inner_join(burningCells,wind,by=c("dggid"="cid"))%>%
    dplyr::select("dggid"=nb)%>%
    dplyr::union(burningCells)
  
  
  df2 <- filter(df,dggid %in% potentialCells$dggid)
  
  
  j <- inner_join(df2,wind,by=c("dggid"="nb"))%>%
    inner_join(df2,c("cid"="dggid"))%>%
    mutate(elev=elevCoef*exp(atan(dem.x-dem.y)))%>%
    mutate(stw=case_when(
      state.y %in% c(1,2,3,4) ~ (r0.x),
      TRUE ~ 0
    ))%>%
    group_by(dggid)%>%
    mutate(sumr1.x=case_when(
      state.x==0 ~ sum(stw),
      TRUE ~ 0
    ),nburn=sum(state.y))%>% # sum must remove the burned cells first
    ungroup()%>%
    mutate(sumr.x=sumr.x+(m*sumr1.x/max(stw)))%>%
    group_by(dggid)%>%
    dplyr::select(dggid,"wkt"=wkt.x,"dem"=dem.x,"state"=state.x,"sumr"=sumr.x,nburn,"r0"=r0.x,"luse"=luse.x)%>%
    distinct()%>%
    mutate(state = case_when(state==0 & nburn==0 ~ as.numeric(0),
                             state==0  & nburn>0 & sumr <tr ~ as.numeric(0),
                             state==0  & nburn>0 & sumr >tr ~ as.numeric(1),
                             state==1 ~ as.numeric(2),
                             state==2  ~ as.numeric(3),
                             state==3  ~ as.numeric(4),
                             state==4  ~ as.numeric(4)))
  
  
  
  
  #write.table(j, file = "test1.txt", row.names = FALSE, dec = ".", sep = "|", quote = FALSE)
  
  
  #======
  burningCells <-ungroup(j)%>% filter(state>0|sumr>0)%>%
    dplyr::select("dggid")
  potentialCells <- inner_join(burningCells,wind,by=c("dggid"="cid"))%>%
    dplyr::select(nb)%>%
    mutate(dggid=nb)%>%
    dplyr::select(dggid)%>%
    dplyr::union(burningCells)
  
  
  newnghbs <- filter(potentialCells, !dggid %in% j$dggid)
  
  df2 <- filter(df,dggid %in% newnghbs$dggid)%>%
    mutate(nburn=0)%>%
    dplyr::union(j)
  
  
  
  # get init time 
  
  
  name <- paste("wind_3_6_50it_c",windCoef)
  
  
  finalresults <- mutate(j,step=0)
  
  for (i in 1:maxiteration) {
    #print(i)
    
    if (i%%optimizationInteraval==0){
      # let's run optimization once
      print("storing Data")
      boundry <- filter(j)%>%
        left_join(lookup,by=c("dggid","dggid"))%>%
        dplyr::select(dggid,i,j,"wkt"=wkt.y,state)
      finalresults <- mutate(j,step=i)%>%
        dplyr::union(finalresults,j)
      
     # write.table(boundry, file =paste(i,name,"_data.txt",sep="") , row.names = FALSE, dec = ".", sep = "|", quote = FALSE)
      
      
    }
    
    
    
    #elev*wind*optweight*r0.y
    # df2nb <- filter(df2,!nburn==24 & !state==4)
    
    j <- inner_join(df2,wind,by=c("dggid"="nb"))%>%
      inner_join(df2,c("cid"="dggid"))%>%
      mutate(elev=elevCoef*exp(atan(dem.x-dem.y)))%>%
      mutate(stw=case_when(
        state.y %in% c(1,2,3,4) ~  r0.y, 
        TRUE ~ 0
      ))%>%
      group_by(dggid)%>%
      mutate(sumr1.x=case_when(
        state.x==0 ~ sum(stw),
        TRUE ~ 0
      ),nburn=sum(state.y))%>% # sum must remove the burned cells first
      ungroup()%>%
      mutate(sumr.x=sumr.x+(m*sumr1.x/max(stw)))%>%
      group_by(dggid)%>%
      dplyr::select(dggid,"wkt"=wkt.x,"dem"=dem.x,"state"=state.x,"sumr"=sumr.x,nburn,"r0"=r0.x,"luse"=luse.x)%>%
      distinct()%>%
      mutate(state = case_when(state==0 & nburn==0 ~ as.numeric(0),
                               state==0  & nburn>0 & sumr <tr ~ as.numeric(0),
                               state==0  & nburn>0 & sumr >tr ~ as.numeric(1),
                               state==1 ~ as.numeric(2),
                               state==2  ~ as.numeric(3),
                               state==3  ~ as.numeric(4),
                               state==4  ~ as.numeric(4)))
    
    
    
    
    
   # write.table(j, file = "test1.txt", row.names = FALSE, dec = ".", sep = "|", quote = FALSE)
    
    
    #======
    burningCells <-ungroup(j)%>% filter(state>0|sumr>0)%>%
      dplyr::select("dggid")
    potentialCells <- inner_join(burningCells,wind,by=c("dggid"="cid"))%>%
      dplyr::select(nb)%>%
      mutate(dggid=nb)%>%
      dplyr::select(dggid)%>%
      dplyr::union(burningCells)
    
    
    newnghbs <- filter(potentialCells, !dggid %in% j$dggid)
    
    df2 <- filter(df,dggid %in% newnghbs$dggid)%>%
      mutate(nburn=0)%>%
      dplyr::union(j)
    
    
    
  }
  
  return(finalresults)
}



