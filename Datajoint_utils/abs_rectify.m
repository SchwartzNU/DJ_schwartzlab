function v_out = abs_rectify(v)
%take absolute value based on largest absolute value in vector and rectify
%negatives

if abs(max(v)) > abs(min(v))
    v_out = v;
else
    v_out = -v;
end

v_out(v_out<0) = 0;
