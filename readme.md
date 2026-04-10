# Regional Nav Sat Constellation Simulation
# Update 24/03/2026

This project simulates and optimizes a regional satellite navigation constellation for Indonesia using MATLAB.

It includes:
- LEO satellite propagation
- 1 hosted GEO payload
- availability check
- simple cost estimation
- NSGA-II multi-objective optimization

# how to use
- run `simulateConstellation`
- this now starts the NSGA-II optimization study
- to evaluate one design directly, call `simulateConstellation(configStruct)`

# file overview
- simulateConstellation.m
  main driver script, and direct design evaluation entry point

- orbitProp.m
  propagate LEO satellites and transform coordinates to ECEF

- addGeoHostedPayload.m
  add one GEO hosted payload above Indonesia, currently using N5 at 113 E

- satAvailability.m
  check which satellites are visible from each target location and calculate availability

- satCost.m
  estimates the total constellation cost

- optimizeConstellationNSGA2.m
  runs NSGA-II with the design variables, objectives, and constraints from the study setup
