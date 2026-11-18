clear all; close all; clc;

s = tf('s');
G = 1/(s^2 + 3*s + 2);
C1 = 20;
H = 1;

L = C1*G*H; % L(s) = 개루프 전달함수
T = feedback(C1*G, H); % T(s) = 개루프 전달함수

opts = bodeoptions;
opts.FreqUnits = 'Hz';

figure()
bode(L, T, opts);
legend('L(s)', 'T(s)');

[~,~,~, wc] = margin(L); 
% Cross-over-frequency = wc (rad/s)
fc = wc/(2*pi) 
wb = bandwidth(T);
% Bandwidth-frequency
fb = wb/(2*pi)