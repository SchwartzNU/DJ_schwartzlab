function y_hat = double_exp_decay(params, x)
%extract the parameters
tau1 = params(1);
tau2 = params(2);
c1 = params(3);


%compute y_hat from your equation
y_hat = c1*exp(-tau1 * x) + (1-c1)*exp(-tau2 * x);

%don't allow nan or inf values. nlinfit does not like it!
y_hat(isnan(y_hat)) = 0;
y_hat(isinf(y_hat)) = 0;