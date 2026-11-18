clc; clear all; close all;

s = tf('s');
G = 1/s; % 제어대상 (plant)
H = 1; % sensor (unit feedback)
C = 1; % 제어기 

L = C*G*H; % 제어 게인  = 1
T = (L)/(1+L);

L2 = 10*G*H; % 제어 게인 = 10
T2 = (L2)/(1+L2);

figure()
bode(L); hold on;
bode(T); 
bode(L2);
bode(T2)
legend('L(s)', 'T(s)', 'L2(s)', 'T2(s)')

