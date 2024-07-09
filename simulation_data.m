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
target_vel = 10;      % 36(km/h)

%% FMCW waverform generation

BW = c/2*delta_r;
Tsweep = 2e-4;   
slope = BW/Tsweep;  % slope of the chirp

 
fc= 5.8e9;  %carrier freq
                                               
M=128; % FFT size 

N=4096; % sampling of each chirp
Fs = N/Tsweep;

t=linspace(0,M*Tsweep,N*M); %total time for samples

% Tx, Rx vector
Tx=zeros(1,length(t));      %Tx signal
Rx=zeros(1,length(t));      %Rx signal
beat_signal = zeros(1,length(t));   %beat signal

% t_delay, target_range vector
r_t=zeros(1,length(t)); %range covered
t_delay=zeros(1,length(t)); % time delay

%% Signal generation  


for i=1:length(t)         
    
    % time stamp when  constant velocity.
    r_t(i) = target_range + target_vel * t(i);
    t_delay(i) = 2 * r_t(i) / c;
   

    % signal update 
    Tx(i) = cos(2*pi*((fc*t(i)) + (slope*t(i)^2)/2)); %+ randn;
    delay = t(i) - t_delay(i); %tau
    Rx(i)  = cos(2*pi*(fc*delay + slope * (delay^2)/2)); %+ randn;
    
    %beat signal
    beat_signal(i) = Tx(i).*Rx(i);
    
end

%% Beat signal FFT

beat_signal = reshape(beat_signal,[N,M]);

sig_fft = fft(beat_signal, N);
sig_fft = sig_fft ./ N; % nomalize

sig_fft = abs(sig_fft);

% one side of the spectrum.
sig_fft= sig_fft(1:N/2 - 1);

plot(sig_fft);
axis ([0 2000 0 1]);

[~, peak_index] = max(sig_fft); % Find the peak index
peak_frequency = (peak_index - 1) * (Fs / N); % Convertion index -> frequency

range_estimated = (peak_frequency * c * Tsweep) / (2 * BW);

% Display the estimated range
fprintf('Estimated target range: %.2f meters\n', range_estimated);

%% 2D FFT

% 2D FFT for both dimensions.
signal_fft2 = fft2(beat_signal, N, M);

% one side of the spectrum
signal_fft2 = signal_fft2(1:N/2,1:M);
signal_fft2 = fftshift (signal_fft2);

% Range Doppler Map
RDM = abs(signal_fft2);
RDM = 10*log10(RDM) ;

doppler_axis = linspace(-100,100,M);
range_axis = linspace(-200,200,N/2)*((N/2)/400);

figure,surf(doppler_axis,range_axis,RDM);
title('Amplitude and Range From RDM');
xlabel('Speed');
ylabel('Range');
zlabel('Amplitude');

