function y_hat = diffCumGauss(params, x)
%extract the parameters
center_weight = params(1);
center_size = params(2);
surround_weight = params(3);
surround_size = params(4);

%compute y_hat from your equation
y_hat = center_weight*normcdf(x,0,center_size) ...
    - surround_weight*normcdf(x,0,surround_size);

%don't allow nan or inf values. nlinfit does not like it!
y_hat(isnan(y_hat)) = 0;
y_hat(isinf(y_hat)) = 0;

