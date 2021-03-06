## utils for fetch functions

# cell_size is in degrees
ncep_radar_to_sp <- function(filepath, crs_str, cell_size) {
  
  nc <- ncdf4::nc_open(filepath)
  
  # generate point sp
  x <- ncdf4::ncvar_get(nc, nc$var$lon)
  y <- ncdf4::ncvar_get(nc, nc$var$lat)
  coords <- data.frame(x=matrix(x, ncol = 1), y=matrix(y, ncol = 1))
  # hard code crs for creating points, then reproject into desired crs
  geo_point_data <- sp::SpatialPoints(coords, proj4string = sp::CRS("+init=epsg:4326"))
  geo_point_data <- sp::spTransform(geo_point_data, sp::CRS(crs_str))
  
  # add precip data (need it to be in inches, not mm)
  prcp_data <- matrix(t(ncdf4::ncvar_get(nc, nc$var$Total_precipitation_surface_1_Hour_Accumulation)), ncol=1) # switch axis order with t()
  prcp_data_inches <- prcp_data/25.4
  geo_p_data_inches <- sp::SpatialPointsDataFrame(geo_point_data, data.frame(prcp=prcp_data_inches))
  
  # generate grid sp
  bbox <- sp::bbox(geo_p_data_inches)
  x_range <- (bbox[3] - bbox[1])/cell_size
  y_range <- (bbox[4] - bbox[2])/cell_size
  grid_topology <- sp::GridTopology(bbox[c(1:2)], cellsize = c(cell_size,cell_size), 
                                    cells.dim = c(x_range, y_range))
  sp_grid <- raster::raster(sp::SpatialGrid(grid_topology, sp::CRS(crs_str)))
  
  # combine points and grid
  sp_grid_data_inches <- raster::rasterize(geo_p_data_inches, sp_grid, "prcp", fun=mean)
  
  return(sp_grid_data_inches)
}
