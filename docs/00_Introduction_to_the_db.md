# TOC


## Important columns in schemas

This section shows columns that are important for understanding and querying electrophysiology data from the MySQL database, using either [DataGrouper](DataGrouper.md), Datajoint queries or SQL queries.

*Side note: Due to cameltyping, querying through DataGrouper / Datajoint uses one single underscrore `_`, but if you query though SQL, sometimes there will be two underscores `__` instead*

The descriptions are shown as `column_name` -> `database.table`: details.

- `file_name` -> `sln_symphony.Experiment`: The  `.h5` file name from Symphony. Usually follows the format of `MMDDYYX` with `X` as the rig name (A or B). File names are unique. If a file name query returns null, there is a high chance there is something wrong with the insertion of experiment into the database (see more at [`sln_symphony.insert_experiment('file_name')`]())
- `experiment_source` -> `sln_symphony.ExperimentSource`: All data sources of an experiments. Can be either a retina, brain area, an animal, or a cell / cell pair. The **combination** of `file_name` and `experimental_source` should be unique. 
- `experiment_retina` -> `sln_symphony.ExperimentRetina`: Mapped the retina(s) to animals by `animal_id` (can be joined with tables from `sln_animal`). Also contains `side` (Left / Right), `experimenter` (can be projected out to join with `sln_lab.User`), and `orientation`
- `experiment_cell`
- `experiment_epoch_group`
- `experiment_epoch_block`
- `experiment_epoch_electrode`
- `experiment_epoch`
- `experiment_epoch_channel`