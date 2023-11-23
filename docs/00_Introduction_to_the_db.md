# TOC


## Important columns in schemas

This section shows columns that are important for understanding and querying electrophysiology data from the MySQL database, using either [DataGrouper](DataGrouper.md), Datajoint queries or SQL queries.

*Side note: Due to cameltyping, querying through DataGrouper / Datajoint uses one single underscrore `_`, but if you query though SQL, sometimes there will be two underscores `__` instead*

The descriptions are shown as `column_name` -> `database.table`: details.

- `file_name` -> [`sln_symphony.Experiment`](./assets/01_sln_symphony_experiment.png): The  `.h5` file name from Symphony. Usually follows the format of `MMDDYYX` with `X` as the rig name (A or B). File names are unique. If a file name query returns null, there is a high chance there is something wrong with the insertion of experiment into the database (see more at [`sln_symphony.insert_experiment('file_name')`]()). This is the utmost important table to join with other tables and/or to restrict other table by, as the majority of tables in `sln_symphony` is connected to `Experiment` (i.e. join / restrict by `file_name = "MMDDYYX"` helps you quickly find your data).
- `experiment_source` -> `sln_symphony.ExperimentSource`: All data sources of an experiments. Can be either a retina, brain area, an animal, or a cell / cell pair. The **combination** of `file_name` and `experimental_source` should be unique. 
- `experiment_retina`: `animal_id`, `side`, `experimenter`, `orientation` -> `sln_symphony.ExperimentRetina`: Mapped the retina(s) to animals by `animal_id` (can be joined with tables from `sln_animal`). Also contains `side` (Left / Right), `experimenter` (can be projected out to join with `sln_lab.User`), and `orientation` (ventral up, ventral down, unknown)
- `experiment_cell`: `cell_number`, `online_type`, `x`, `y` -> `sln_symphony.ExperimentCell`: All online information relating to a cell including: the retina ID, the cell number (aka. the number after `MMDDYYXc*`, for example the 16 in `081223Ac16`, which means the 16th cells, recorded on August 12, 2023, on rig A),  online types and the X/Y coordinates ($\mu m$ from the optic nerve). 
- `experiment_epoch_group`
- `experiment_epoch_block`
- `experiment_epoch_electrode`
- `experiment_epoch`
- `experiment_epoch_channel`
- `dataset`
- `dataset_epoch`