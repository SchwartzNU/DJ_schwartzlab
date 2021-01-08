function [] = dataToH5ForIgor(x_vals, y_vals, fname, varName)
if nargin < 4
    varName = 'data';
end
if nargin < 3
    fname = 'temp.h5';
end

S = struct;

%check if x_vals are evenly spaced
d = diff(x_vals);
d1 = d(1);
if all(d-d1<d1/1E3) %evenly spaced
    S.([varName '_startX']) = x_vals(1);
    S.([varName '_intervalX']) = d1;
else
    S.([varName '_x']) = x_vals;
end
S.(varName) = y_vals;

if exist(fname, 'file') %delete old file
    delete(fname)
end

%open new file
fid = fopen(fname, 'w');
fclose(fid);

fields = fieldnames(S);
for i=1:length(fields)
    hdf5write(fname, ['/' fields{i}], S.(fields{i}), 'WriteMode', 'append');
end