# Set up and get functional imaging going

## Set up
- Make sure `DJ_schwartzlab` is pulled and up-to-date from git.
- Add `setenv('Func_imaging_folder', '/Volumes/fsmresfiles/Ophthalmology/Research/SchwartzLab/FunctionalImaging')` or `setenv('Func_imaging_folder', '[Path_to_fsm_res_files]/Ophthalmology/Research/SchwartzLab/FunctionalImaging')`to `startup.m`.
- Have `+ScanImageTiffReader` on MATLAB Path ([Windows: Download from vidriotech gitlab](https://vidriotech.gitlab.io/scanimagetiffreader-matlab/), mac: ask Trung to compile from source).
