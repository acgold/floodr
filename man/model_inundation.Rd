% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_inundation.R
\name{model_inundation}
\alias{model_inundation}
\title{Run bathtub inundation model}
\usage{
model_inundation(
  model,
  elev,
  elev_units,
  overlay = NULL,
  overlay_quantile = 0.95,
  from_elevation = -3,
  to_elevation = 3,
  step = 0.5,
  model_ponding = F,
  DEM_RMSE = 0.2,
  conv_RMSE = 0.1,
  pipe_RMSE = 0.1,
  DEM_confidence = F,
  minimum_area = 0.6,
  minimum_area_units = "km^2",
  min_elev_cutoff = -5,
  use_outlets = T,
  site_name,
  workspace,
  overwrite = T
)
}
\arguments{
\item{model}{A \code{bathtub} model. Result of \code{assemble_network_model}}

\item{elev}{\code{RasterLayer} DEM object for inundation modeling. Result of \code{DEM_setup}.}

\item{elev_units}{Units of \code{elev} values}

\item{overlay}{\code{sf} object or \code{RasterLayer} of flooding extent (Optional)}

\item{overlay_quantile}{Quantile of elevation values flooded by \code{overlay} to use for
modeling flooding (Optional)}

\item{from_elevation}{Lower bound of elevation for modeling. Units same as model inverts}

\item{to_elevation}{Upper bound of elevation for modeling. Units same as model inverts}

\item{step}{Step of sequence between \code{from_elevation} and \code{to_elevation}.
Units same as model inverts}

\item{model_ponding}{Model overland ponding from structure surcharge? Default F}

\item{DEM_RMSE}{RMSE of DEM in same units as 'elev_units'. Default is 0.2.}

\item{conv_RMSE}{RMSE of conversion from NAVD88 to MHHW. Default is 0.1 m}

\item{pipe_RMSE}{RMSE of elevation or depth measurements of pipes in same units as model$pipes. Default is 0.1}

\item{DEM_confidence}{Calculate confidence rasters for DEMs? Default is F}

\item{minimum_area}{Minimum area of flooded area to keep}

\item{minimum_area_units}{Units of flooded area}

\item{min_elev_cutoff}{Minimum cutoff for elevation values}

\item{use_outlets}{Force outlets to be connected by receiving waters
(i.e., contiguous flooded area > min_elev_cutoff)}

\item{site_name}{Name of site}

\item{workspace}{Path to bathtub folder}
}
\value{
A list of \code{sf} objects denoting impacted infrastructure from each step
of the model. Objects include impacted Pipes, Nodes, and Structures (using propagation
through network), Nodes and Structures impacted by overland flooding with no propagation
through network (e.g., "np_nodes" & "np_structures"), overland flooding, overland ponding.
Includes the overlay if used rather than a range of water levels.
}
\description{
Run bathtub inundation model
}
\examples{
# bft_model_output <- model_inundation(
# model = bft_model,
# elev = bft_elev,
# elev_units = "m",
# from_elevation = -3,
# to_elevation = 4,
# step = 3/12,
# model_ponding = T,
# site_name = "beaufort",
# minimum_area = 0.01,
# workspace = workspace
# )
}
