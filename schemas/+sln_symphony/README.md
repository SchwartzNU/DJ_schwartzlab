# Main todo items:
## Symphony file parsing
- [ ] get branch and commit from experiment
- [ ] add background for projector and parse
- [x] parse device resources and configuration settings
  - ideally a `Calibration` table with an `ExperimentCalibration` part
- [ ] add a source note whenever there's an `Other` object
- [ ] convenience script for missing `animal_id`
- [ ] search for missing `experimenter`
- [ ] parse `Symphony1` files
  - main issue is nested epoch groups, with the source as an epoch group
  - will have to make decision about how to handle missing mouse info
- [ ] hold needs to be an epoch-level parameter
- [ ] NDF in projector settings should share reference with calibration
- [ ] what to do about r-star, etc.

## Misc
- [ ] automatic loading of `eye` objects
- [ ] figure out a good representation for cells in `sln_cell`

## Analysis
- [ ] test out the master/part with target framework
  - start with SMS

