%% FMCW Radar parameters

clear all
clc;

% BW = 20MHz, Tsweep = 200us, adc/dac 12bit
% Frequency of operation = 5.8GHz
% Max Range = 200m
% Range Resolution = 7.5 m  => c/(2*BW)
% Max Velocity = 30 m/s

range_max = 480;    % (m) N*c/(4*BW)
delta_r = 7.5;      % range resolution(m)
max_vel = 64;  % (m/s), 232(km/h)
c = 3e8;            % speed of light(m/s)

target_range = 50;
target_vel = -10;      % 36(km/h)

%% FMCW waverform generation

BW = c/2*delta_r;
Tsweep = 2e-4;   
slope = BW/Tsweep;  % slope of the chirp
 
fc= 5.8e9;  %carrier freq
                                               
N=128; % FFT size 

Ns=4096; % sample of each sample

t=linspace(0,N*Tsweep,Ns*N); %total time for samples

% Tx, Rx vector
Tx=zeros(1,length(t));      %Tx signal
Rx=zeros(1,length(t));      %Rx signal
Mix = zeros(1,length(t));   %beat signal

% t_delay, target_range vector
r_t=zeros(1,length(t)); %range covered
t_delay=zeros(1,length(t)); % time delay

%% Signal generation  

for i=1:length(t)         
    
    % time stamp when  constant velocity.
    r_t(i) = target_range + target_vel * t(i);
    t_delay(i) = 2 * r_t(i) / c;
    
    % signal update 
    Tx(i) = cos(2*pi*((fc*t(i)) + (slope*t(i)^2)/2));
    delay = t(i) - t_delay(i); %tau
    Rx (i)  = cos(2*pi*(fc*delay + slope * (delay^2)/2));
    
    %beat signal
    Mix(i) = Tx(i).*Rx(i);
    
end

%% RANGE MEASUREMENT

Mix = reshape(Mix,[Ns,N]);

sig_fft = fft(Mix, Ns);
sig_fft = sig_fft ./ Ns;

sig_fft = abs(sig_fft);

% one side of the spectrum.
sig_fft= sig_fft(1:Ns/2 - 1);

figure ('Name','Range from First FFT')
plot(sig_fft);
axis ([0 200 0 1]);

