%{
# ROI traces
->sln_funcimage.ROIField
->sln_symphony.DatasetEpoch
---
traces : blob@raw #matrix where rows are ROIs and columns are time points (ms) in the epoch
%}
classdef ROITraces < dj.Computed
    properties
        keySource = sln_symphony.DatasetEpoch * sln_funcimage.ROIField;
    end

    methods(Access=protected)
        function makeTuples(self, key)
            roi_field = fetch(sln_funcimage.ROIField & key, '*');            
            ep = aka.Epoch & key;
            frame_rate = fetch1(sln_funcimage.ImagingRun & key, 'frame_rate');
            dur_ms = fetch1(ep,'epoch_duration');
            key.traces = zeros(roi_field.n_rois,dur_ms);
            movie = fetch(sln_funcimage.EpochMovie & key, '*');
            [rows, cols, frames] = size(movie.raw_movie);
            trace_x = 1:dur_ms;
            for i=1:roi_field.n_rois
                [xvals, yvals] = ind2sub([rows, cols],roi_field.pixels_in_roi{i});
                trace = squeeze(mean(double(movie.raw_movie(xvals,yvals,:)),[1 2]));
                trace = interp1(linspace(1,1E3*frames/frame_rate,frames),trace,trace_x);
                key.traces(i,:) = circshift(trace,movie.offset_ms);
            end
            self.insert(key);
        end
    end
end