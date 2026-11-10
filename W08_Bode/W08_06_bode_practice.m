
clear all; close all; clc;

s = tf('s');

G1 = 1/(s+1);
G2 = 1/(0.1*s+1);
G3 = 1/(0.01*s+1);

opts = bodeoptions;
opts.FreqUnits = 'Hz';

figure()
bode(G1, G2, G3, opts);

%% Next class
% lsim 이용해서 사인파 줬을 때, bode plot에서 파악한 크기 변화와 맞는지 확인하기

% db를 크기로 변화시키는 함수도 확인해봅시다.

% Wc <-> Wb <-> time constant <-> 반응속도

% PM <-> damping ratio 비례
%% 왜? DB 을 쓰는지? K 만큼 곱했을때 bode plot 의 모양 변화를 살펴봅시다.

