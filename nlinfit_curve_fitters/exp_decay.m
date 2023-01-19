function y_hat = exp_decay(params, x)
%extract the parameters
tau = params(1);

%compute y_hat from your equation
y_hat = exp(-tau * x);

% %don't allow nan or inf values. nlinfit does not like it!
% y_hat(isnan(y_hat)) = 0;
% y_hat(isinf(y_hat)) = 0;

