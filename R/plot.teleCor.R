#' Plots teleconnection correlation maps
#'
#' This function provides basic plotting for analyses returned from cor.tel
#' 
#'
#' @export
#' 
#' @import ggplot2
#' @importFrom dplyr mutate filter "%>%"
#' 
#' @param teleCor object of class teleCor, containing pointwise correlations
#' @param signif if TRUE, then teleCor must have a column labeled 'signif' that
#'  indicates which correlations are significant.  These correlations will be
#'  printed in bold, and the rest will be printed more lightly
#' @param coord.s specifies the longitude and 
#'  latitude of local coordinate for which to plot pointwise correlations. if 
#'  NULL, the middle local coordinate will be plotted.
#' @param boxsize size of grid boxes plotted
#' @param map name of map provided by the maps package. These include county, 
#'  france, italy, nz, state, usa, world, world2.  By default, all stData plots
#'  will include us state outlines.
#' @param region name of subregions to include. Defaults to . which includes 
#'  all subregions. See documentation for map for more details.
#' @param zlim c(min, max) vector that specifies the colorscale limits
#' 
#' @return a ggplot object with the specified map

plot.teleCor = function( teleCor, signif=F, coord.s=NULL, boxsize=NULL, 
                         map='world', region='.', zlim=NULL ) {
  
  # extract basic plotting information
  n = nrow(teleCor$coords.s)
  r = nrow(teleCor$coords.r)
  
  # if not specified, identify a base location
  if(is.null(coord.s))
    coord.s = teleCor$coords.s[round(n/2),]
  
  # identify the index of the local coordinate to be plotted
  coord.s = unlist(coord.s)
  coord.s.ind = which( coord.s[1] == teleCor$coords.s[,1] &
                       coord.s[2] == teleCor$coords.s[,2] )
  
  # convert pointwise correlation data into plottable frame
  cor.frame = data.frame( cor = teleCor$cor[coord.s.ind,],
                          lon.Z = teleCor$coords.r[,1],
                          lat.Z = teleCor$coords.r[,2] )
  
  # add information about significant teleconnections
  if(signif) {
    cor.frame = cbind(cor.frame, signif = teleCor$signif[coord.s.ind,])
  }
    
  # set basic plotting theme
  lab.col = expression(rho)
  scheme.col = list(low = "#0571b0", mid = '#f7f7f7', high = '#ca0020')
  
  if(signif) {
    alpha = .2
  } else {
    alpha = 1
  }
    

  # compute truncations and apply wrapping
  if(max(cor.frame$lon.Z)>0) {
    if(min(cor.frame$lon.Z)<0) {
      lon.E = max(cor.frame %>% filter(lon.Z<=0) %>% select(lon.Z))
      lon.W = min(cor.frame %>% filter(lon.Z>0) %>% select(lon.Z)) - 360
    } else {
      lon.E = max(cor.frame$lon.Z) - 360
      lon.W = min(cor.frame$lon.Z) - 360
    }
  } else {
    lon.E = max(cor.frame$lon.Z)
    lon.W = min(cor.frame$lon.Z)
  }
  lat.S = min(cor.frame$lat.Z)
  lat.N = max(cor.frame$lat.Z)
  
  cor.frame = rbind(cor.frame, cor.frame %>% mutate(lon.Z=lon.Z-360))
  
  
  # get us state outlines ggplot format
  world = map_data('state', region=region)
  # get country outlines ggplot format
  if(map=='world') {
    # get raw outline data
    world.raw = map_data('world')
    # duplicate countries for plotting with any map center
    world.raw = rbind(world.raw, world.raw %>% 
                        mutate(long=long-360, group=group+max(group)+1))
    # add outline data to state outlines
    world = rbind(world, world.raw %>% mutate(group=group+max(world$group)+1))
  }
  
  
  #
  # set commands to modify plotting options, if specified
  #
  
  if(is.null(boxsize)) {
    tile.aes = aes(x=lon.Z, y=lat.Z, fill=cor)
  } else {
    tile.aes = aes(x=lon.Z, y=lat.Z, fill=cor, 
                   width=boxsize, height=boxsize)
  }
    
  
  if(is.null(zlim)) {
    fillscale = scale_fill_gradient2(lab.col,
                                     low = scheme.col$low, 
                                     mid = scheme.col$mid, 
                                     high = scheme.col$high)
  } else {
    fillscale = scale_fill_gradient2(lab.col,
                                     low = scheme.col$low, 
                                     mid = scheme.col$mid, 
                                     high = scheme.col$high,
                                     limits = zlim)
  }
    
  # build base plot
  worldmap = ggplot(world, aes(x=long, y=lat, group=group)) +
    geom_tile(tile.aes, data = cor.frame  %>% 
                mutate(lon.Z = ifelse(lon.Z<=0, lon.Z, lon.Z-360)), 
              inherit.aes = F, alpha=alpha) +
    fillscale +
    scale_x_continuous(trans = lon_trans()) +
    scale_y_continuous(trans = lat_trans()) +
    xlab('Longitude') +
    ylab('Latitude') + 
    geom_path() +
    theme_grey()
  
  # add significant overlays, if applicable
  if(signif)
    if(nrow(cor.frame %>% filter(signif==T)) > 0) {
      worldmap = worldmap + 
        geom_tile(tile.aes, data = cor.frame %>% filter(signif==T),
                  inherit.aes = F, color='black', lwd=1.75, alpha = 1)
    }
  
  # add coord.s to the plot and modify truncation
  worldmap = worldmap + geom_point(aes(x=lon.Y, y=lat.Y), 
                                   data = data.frame(lon.Y = coord.s[1],
                                                     lat.Y = coord.s[2]),
                                   col = 2, inherit.aes = F)
  lon.E = max(lon.E, coord.s[1])
  lon.W = min(lon.W, coord.s[1])
  lat.N = max(lat.N, coord.s[2])
  lat.S = min(lat.S, coord.s[2])
  
  # apply map projection and truncation
  worldmap + coord_fixed(xlim=c(lon.W, lon.E), ylim=c(lat.S, lat.N), ratio=1.3)
  
}