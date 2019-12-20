
#Integrating cellular automata and discrete global grid systems: a case study into wildfire modelling
---
**author:** "[`The Spatial lab`] (https://www.thespatiallab.org) "
**date:** 11/20/2019


[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/am2222/AGILECA.git/master)



## Abstract

With new forms of digital spatial data driving new applications for monitoring and understanding environmental change, there are growing demands on traditional GIS tools for spatial data storage, management and processing. Discrete Global Grid System (DGGS) are methods to tessellate globe into multiresolution grids, which represent a global spatial fabric capable of storing heterogeneous spatial data, and improved performance in data access, retrieval, and analysis. While DGGS-based GIS may hold potential for next-generation big data GIS platforms, few of studies have tried to implement them as a framework for operational spatial analysis. Cellular Automata (CA) is a classic dynamic modeling framework which has been used with traditional raster data model for various environmental modeling such as wildfire modeling, urban expansion modeling and so on. The main objectives of this paper were to (i) investigate the possibility of using DGGS for running dynamic spatial analysis, (ii) evaluate CA as a generic data model for dynamic phenomena modeling within a DGGS data model and (iii) evaluate an in-database approach for CA modelling. To do so, a case study into wildfire spread modelling is developed. Results demonstrate that using a DGGS data model not only provides the ability to integrated different data sources, but also provides a framework to do spatial analysis without using geometry-based analysis. This results in a simplified architecture and common spatial fabric to support development of a wide array of spatial algorithms. While considerable work remains to be done, CA modelling within a DGGS-based GIS is a robust and flexible modelling framework for big-data GIS analysis in an environmental monitoring context.

**Key Words**: _DGGS, Discrete Global Grid System, Cellular Automaton, Wildfire_ 

[![DOI](https://zenodo.org/badge/228503632.svg)](https://zenodo.org/badge/latestdoi/228503632)


## One-click execution

This repo can be opened directly in [Binder](https://mybinder.org/)

[![screencast of senseBox-Binder analysis in RStudio running on mybinder.org](https://media.giphy.com/media/l49JRjO65S0WQ1Kyk/giphy.gif)](https://mybinder.org/v2/gh/am2222/AGILECA/bfe6c0e184111dfe5460f34d0b9b2520e3ad9516)

## Data and Software Availability

To run the CA model several software packages were used; R (R Core Team 2019); Dplyr (Wickham et al. 2019) and dggridR (Barnes 2018). Table 1 also shows the different datasets, which were used for wildfire spread modelling. These data were converted into the DGGS data model and stored in the database table structure. A Netezza IBM database engine was used as big geo data storage platform, however any relational database system could be used. Currently, due to security-related issues it is not possible to share any connection to this database application. For this reason, a small portion of the data, which is used to run the model, is stored as CSV data format with a working script, which are accessible in the following GitHub repository: https://github.com/am2222/AGILECA

|	|Dataset|	Resolution (spatial/temporal)	|Retrieved parameters|	Source/ Licence|
|1|	Nasa Active fire data (VNIIRS)	|approximate spatial resolution of 350m/ daily 	Active fire data used for starting fire points|	https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/active-fire-data
NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VNP14IMGT.NRT.001.
Free to the user community.
2	Copernicus Climate data	spatial resolution of these data is 0.1 degree / 1 hour	climate data including  wind speed and wind direction data	https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land?tab=overview
DOI: 10.24381/cds.e2161bac
3	Canada Dem	0.0002 degree spatial resolution	Elevation	https://open.canada.ca/data/en/dataset/7
f245e4d-76c2-4caa-951a-45d1d2051333
Open Government Licence - Canada
4	National land cover dataset	0.0002 degree spatial resolution	Land Cover	https://www.nrcan.gc.ca
8	Landsat 8 Data
(2016/05/03-2016/05/05-2016/05/12)	30 meters / 16 days	True color band composition to extract fire boundary	https://www.usgs.gov/landsat
Landsat-7 image courtesy of the U.S. Geological Survey

## References

This project is licensed under Apache License, Version 2.0, see file LICENSE.
