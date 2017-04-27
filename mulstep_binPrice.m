% Multi-step Binomial Option Pricing (American & European options)
% 
% INPUTS
%    N --> An integer specifying the number of days to use in the
%    volatility calculation - 20 is considered
%    Stock data --> Historic stock data with closing prices each day to be
%    used for model calibration
% 
% OUTPUT
%    Plots of American & European options against their strikes
% 
% NOTES:    
% 1. The historical volatility is calculated using the closing prices
%    of each trading day.  
%
% Created by Nithya Mahadevan
% March 10, 2017

% Go to required directory where stock data is available
main_path='C:\Nithya Mahadevan\Studies\Semester - II\Mathematical Finance\Project\Project - 1\Data';
cd(main_path);
figuresdir = 'C:\Nithya Mahadevan\Studies\Semester - II\Mathematical Finance\Project\Project - 1\Output\'; 


% Import stocks & options data
stocks_Data_raw = dataset('File','Stocks.csv','Delimiter',',');
stocks_Data=stocks_Data_raw(1:58,:);

% Part 1 - Calibrate volatility
disp('Part 1 - Calculating volatility...');
% Get number of days input for calibrating volatility
N = 15;

data = stocks_Data;
closing = data.Close;   % Use only closing data

% Creating empty data set for the %change & %volatility
vol_temp = zeros((length(data)-N), 2);
change=zeros((length(data)-1), 1);
sd=zeros((length(data)-N), 1);

% Finding the size of input data (number of days in historic stocks data)
days=length(data);

% Calculate the percentage change over the past N trading days
for i = 1:(days-1)
change(i)=(closing(i)/closing(i+1))-1;
end

% Get standard deviation of that change
for j = 1:(days-N) 
sd(j) = std(change(j:j+N-1));
vol_temp(j,1) = (days-N)+1-j;
vol_temp(j,2) = sd(j);
end

% Sort to get the volatility from oldest date on the top
vol_f = sortrows(vol_temp,1);
vol=vol_f(:,2);

% Part 2 - Calibrate up & down factor
disp('Part 2 - Calculating up, down-factors & risk-free probabilities for stocks')

% Assuming the time between two steps in binomial model is 1
dt=1;

% Approximating the drift to be 0
drift=0;

% Risk free interest rate (using LIBOR rate for US dollars - over 1 month)
r = 0.0097722;
a = exp(r*dt);
b=exp((-r)*dt);

% We choose options expiring on April 21st 2017 and, 62 - N days of data for stock prices
num_days = datenum({'21/04/2017'},'dd/mm/yyyy')-datenum(today);

% Creating u & d empty matrices
up=zeros(num_days, 1);
down=zeros(num_days, 1);
pTilda=zeros((days-N), 1);

% We calibrate a set of up & down factors for every time step (every day) using the
% volatility data
% We find the risk neutral probability for each step using the up & down
% factors
for i = 1:(days-N)
up(i)= exp(vol(i)*dt);
down(i)= 1/(exp(vol(i)*dt));
pTilda(i)=(a-down(i))/(up(i)-down(i));
end

% Duplicating the up & down factors for the next set of days till expiration
for i= (days-N+1):num_days
up(i)=up(i-days+N);
down(i)=down(i-days+N);
pTilda(i)=pTilda(i-days+N);
end

disp('Part 3 - Computing forward tree for stocks')

% Consider today's stock price as the starting stock price for the
% forward stock tree
% Construct a price tree till expiration by using the same set of up & down
% factors - that is, if N=20, use all the 42 up & down factors for each day
% Loop over each node and calculate the underlying price tree
priceTree = zeros(num_days,num_days);

% Input today's stock price here
c=yahoo;
S0 = fetch(c,'IBM');
close(c);
priceTree(1,1)=S0.Last;

for i = 2:num_days+1 % For the 65 days till expiry
    priceTree(1:i-1,i) = priceTree(1:i-1,i-1)*up(i-1);
    priceTree(i,i) = priceTree(i-1,i-1)*down(i-1);
end

% Go to required directory where strikes data is available
cd(main_path);

% Importing different strike prices for maturity April 13th 2017
options_Data = dataset('File','Strike.csv','Delimiter',',');
data_strike = options_Data(:,{'oType','Strike'});
options = dataset('File','Options.csv','Delimiter',',');

disp('Part 4 - Computing backward tree for options')

% Execute for American/ European option
for y=1:2

option_name = options{y,1};

% Create empty array to store the options prices against each strike
oPrice=zeros(length(data_strike),2);
oPrice(:,1) = data_strike(:,2); 

for k=1:length(data_strike)
valueTree = zeros(num_days+1,num_days+1);

% Calculate the value at expiry
oType=data_strike{k,1};
strike=data_strike{k,2};
switch oType
    case 'Put'
        valueTree(:,end) = max(strike-priceTree(:,end),0);
    case 'Call'
        valueTree(:,end) = max(priceTree(:,end)-strike,0);
end

% Loop backwards to get values at the earlier times
steps = size(priceTree,2)-1;
for i = steps:-1:1
    valueTree(1:i,i) = max((b*(((pTilda(i)*valueTree(1:i,i+1)) + ((1-pTilda(i))*valueTree(2:i+1,i+1))))),0);
    if option_name=='A'
        switch oType
            case 'Put'
                valueTree(1:i,i) = max(strike-priceTree(1:i,i),valueTree(1:i,i));
            case 'Call'
                valueTree(1:i,i) = max(priceTree(1:i,i)-strike,valueTree(1:i,i));
        end
    end
end
oPrice(k,2) = valueTree(1); 
end

if option_name=='A'
    oPrice_American=oPrice;
else 
    oPrice_European=oPrice;
end

end;

disp('Option prices have been calculated!!')

%Creating lists to hold data for american, european call and put option
%prices & strikes

AmericanCallPrice=oPrice_American(1:24,2);
AmericanPutPrice = oPrice_American(25:51,2);
EuropeanCallPrice = oPrice_European(1:24,2);
EuropeanPutPrice = oPrice_European(25:51,2);

MarketPriceCall = [52.6000000000000;72.3700000000000;58.2000000000000;55.7000000000000;52.3500000000000;41.7000000000000;39.5000000000000;31.6500000000000;30.3000000000000;23.3800000000000;16.4300000000000;11.7000000000000;7.55000000000000;4.35000000000000;1.97000000000000;0.790000000000000;0.260000000000000;0.0900000000000000;0.0700000000000000;0.0300000000000000;0.0300000000000000;0.0100000000000000;0.0100000000000000;0.0100000000000000];
MarketPricePut = [0.0100000000000000;0.0100000000000000;0.0200000000000000;0.0300000000000000;0.0100000000000000;0.0100000000000000;0.0100000000000000;0.0100000000000000;0.0100000000000000;0.0100000000000000;0.0200000000000000;0.0100000000000000;0.0300000000000000;0.0400000000000000;0.0800000000000000;0.150000000000000;0.320000000000000;0.720000000000000;1.53000000000000;3.20000000000000;5.90000000000000;9.31000000000000;13.1500000000000;19.1000000000000;18.8000000000000;37.5300000000000;45.6300000000000];


strike_list=data_strike(:,2);
strike_call=strike_list(1:24,1);
strike_put=strike_list(25:51,1);

actual_price_amer_call = options_Data((1:24),{'LastPrice'});
actual_price_amer_put = options_Data((25:51),{'LastPrice'});

disp('Part 4 - Plots for option prices versus their respective strikes')

p1=plot(strike_call, AmericanCallPrice);
xlabel('Strike price');
ylabel('Option price');
title('American Call Option Prices v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-1'), 'jpeg');


p2=plot(strike_put, AmericanPutPrice);
xlabel('Strike price');
ylabel('Option price');
title('American Put Option Prices v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-2'), 'jpeg');


p3=plot(strike_call, EuropeanCallPrice);
xlabel('Strike price');
ylabel('Option price');
title('European Call Option Prices v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-3'), 'jpeg');

p4=plot(strike_put,EuropeanPutPrice);
xlabel('Strike price');
ylabel('Option price');
title('European put Option Prices v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-4'), 'jpeg');
hold off

p5=plot(strike_call, AmericanCallPrice);
hold on
plot(strike_call, MarketPriceCall);
xlabel('Strike price');
ylabel('Option price');
legend('y = Predicted American Call Option prices', 'y = Actual American Call Option prices');
title('American Call Option Actual & Predicted Prices v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-5'), 'jpeg');
hold off

p6=plot(strike_put, AmericanPutPrice);
hold on
plot(strike_put, MarketPricePut);
xlabel('Strike price');
ylabel('Option price');
legend('y = Predicted American Put Option prices', 'y = Actual American Put Option prices');
title('American Put Option Actual & Predicted Prices v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-6'), 'jpeg');
hold off

p7=plot(strike_call, AmericanCallPrice);
hold on
plot(strike_call, EuropeanCallPrice);
xlabel('Strike price');
ylabel('Option price');
legend('y = Predicted American Call Option prices', 'y = Predicted European Call Option prices');
title('Comparison of European & American Call option predictions v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-7'), 'jpeg');
hold off

p8=plot(strike_put, AmericanPutPrice);
hold on
plot(strike_put, EuropeanPutPrice);
xlabel('Strike price');
ylabel('Option price');
legend('y = Predicted American Put Option prices', 'y = Predicted European Put Option prices');
title('Comparison of European & American Put option predictions v/s Strikes');
saveas(gcf,strcat(figuresdir, 'Plot-8'), 'jpeg');
hold off


% End



