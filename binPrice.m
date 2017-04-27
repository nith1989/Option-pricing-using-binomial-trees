% Program to calculate the price of a vanilla European Put or Call option using a Binomial tree.
%
% Inputs: X - strike
%       : S0 - stock price
%       : r - risk free interest rate
%       : u & d - up & down factor
%       : dt - size of time steps
%       : steps - number of time steps to calculate
%       : oType - must be 'PUT' or 'CALL'.
%
% Output: oPrice - the option price
%
% Author: Nithya Mahadevan (nmahadevan@hawk.iit.edu)
% Date  : Q1, 2017

% Input required parameters for model
S0 = input('Enter current stock price: ');
X = input('Enter strike price of option: ');
r = input('Enter the risk free interest rate: ');
u = input('Enter the up-factor for stocks: ');
d = input('Enter the down-factor for stocks: ');
dt = input('Enter the time-gap between any two steps: ');
steps = input('Enter the number of steps: ');
oType = input('Enter type of European option: ','s');

% Calculate the model parameters
a = exp(r*dt);
pTilda = (a-d)/(u-d);

% Loop over each node and calculate the underlying price tree
priceTree = nan(steps+1,steps+1);

priceTree(1,1) = S0;
for i = 2:steps+1
    priceTree(1:i-1,i) = priceTree(1:i-1,i-1)*u;
    priceTree(i,i) = priceTree(i-1,i-1)*d;
end

% Calculate the value at expiry
valueTree = nan(size(priceTree));
switch oType
    case 'PUT'
        valueTree(:,end) = max(X-priceTree(:,end),0);
    case 'CALL'
        valueTree(:,end) = max(priceTree(:,end)-X,0);
end

% Loop backwards to get values at the earlier times
steps = size(priceTree,2)-1;
for i = steps:-1:1
    valueTree(1:i,i) = ...
        exp(-r*dt)*(pTilda*valueTree(1:i,i+1) ...
        + (1-pTilda)*valueTree(2:i+1,i+1));
end

% Output the option price
oPrice = valueTree(1); 
X = sprintf('Price of the European %s option is: %f ',oType, oPrice);
disp(X);
