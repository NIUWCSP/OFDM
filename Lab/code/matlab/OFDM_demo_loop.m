%% **********************���d�ҶȾA�Ω����ۦ��۵o�ϥ�-������********************************
clearvars -except times;close all;warning off; %�w�]����
set(0,'defaultfigurecolor','w'); 
%�[�Jpath
addpath ..\..\library 
addpath ..\..\library\matlab 
addpath ..\..\code\matlab\OFDM

%�]�wpluto IP
ip = '192.168.2.1';

%�]�w�P�i�JTX�禡
upsample=4; %�L���˨�4���A�Ʀ��٭���������i�H�����u
txdata = Transmitter(upsample);
txdata = round(txdata .* 2^15); %[(32768*4096)/1024]  -2/2


%% Transmit and Receive using MATLAB libiio �걵pluto

% System Object Configuration
s = iio_sys_obj_matlab; % MATLAB libiio Constructor
s.ip_address = ip;
s.dev_name = 'ad9361';
s.in_ch_no = 2;
s.out_ch_no = 2;
s.in_ch_size = length(txdata);
s.out_ch_size = length(txdata).*10;

s = s.setupImpl();

input = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
output = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));

% Set the attributes of AD9361
input{s.getInChannel('RX_LO_FREQ')} = 2400e6;
input{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('RX_RF_BANDWIDTH')} = 20e6;
input{s.getInChannel('RX1_GAIN_MODE')} = 'manual';%% slow_attack manual
input{s.getInChannel('RX1_GAIN')} = 1;
input{s.getInChannel('TX_LO_FREQ')} = 2400e6;
input{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;


%% PLOT TX for Evan_debug �e�XTX���ɰ�ϻP�W�й�
TimeScopeTitleStr = 'OFDM-TX-Baseband I/Q Signal';
SpectrumTitleStr = 'OFDM-TX-Baseband Signal Spectrum';
    
samp_rate = 40e6;    
    scope1 = dsp.TimeScope('SampleRate',      samp_rate, ...
                          'Title',           TimeScopeTitleStr, ...
                          'TimeSpan',        1/samp_rate*(length(txdata)+100), ...
                          'YLimits',         [-5 5], ...
                          'ShowLegend',      true, ...
                          'ShowGrid',        true, ...
                          'Position',        [0 300 400 400]);
    step(scope1,txdata);
    release(scope1);
    
spectrum1 = dsp.SpectrumAnalyzer('SampleRate',      samp_rate, ...
                                'SpectrumType',    'Power density', ...
                                'SpectralAverages', 10, ...
                                'YLimits',         [-70 60], ...
                                'Title',           SpectrumTitleStr, ...
                                'YLabel',          'Power spectral density', ...
                                'Position',        [500 300 400 400]);

% Show power spectral density of captured burst
step(spectrum1,txdata);
release(spectrum1);

while(1) %�T�O���ƺʴ�
%% PLOT RX �e�XRX����
for i=i:4 %�ѩ�PLUTO-USB�ƾڶq����~�]��RX�ϥΦ�FOR-LOOP����TX�ƾڶi�J by Evan 2019-04-16
    fprintf('Transmitting Data Block %i ...\n',i);
    input{1} = real(txdata);
    input{2} = imag(txdata);     
    output = stepImpl(s, input);
    fprintf('Data Block %i Received...\n',i);
end
    I = output{1};
    Q = output{2};
    Rx = I+1i*Q;
    figure(1); clf;
    set(gcf,'name','������-RX���I/Q�������A'); % EVAN for debug OK
    subplot(121);
    plot(I);
    hold on;
    plot(Q);
    subplot(122);
    pwelch(Rx, [],[],[], 40e6, 'centered', 'psd');
    %% PLOT RX
    Rx = Rx(:,1);
    Receiver(Rx(1:4:end));
    pause(0.1);
    %break;
end

%% ����
fprintf('Transmission and reception finished\n');

% Read the RSSI attributes of both channels
rssi1 = output{s.getOutChannel('RX1_RSSI')};
% rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();


