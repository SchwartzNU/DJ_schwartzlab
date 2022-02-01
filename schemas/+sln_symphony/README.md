# Main todo items:
## Symphony file parsing
- [ ] get branch and commit from experiment
- [ ] change canvas size to 'display size' and include the fake canvasSize, or something along those lines
- [ ] debug why multiple calibrations are being created....
- [ ] debug a faulty raw_data instance... see bottom
- [ ] failures in experiment_protocols should delete all created files to avoid mishaps
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
- [ ] add an on-connection callback to set the path to the file server

## Analysis
- [ ] test out the master/part with target framework
  - start with SMS


file name: "092321A"
         source_id: 2
    epoch_group_id: 7
    epoch_block_id: 29
          epoch_id: 1382
      channel_name: 'Amp1'
         direction: 180
             speed: 870.5510
          raw_data: [49152×1 uint8] *******