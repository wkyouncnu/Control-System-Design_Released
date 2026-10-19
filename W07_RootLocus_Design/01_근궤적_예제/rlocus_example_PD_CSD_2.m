clc; clear all; close all;
s = tf('s');
% G = 1/(s*(s+2)*(s+5));
% H = 1;
% GH = G*H;
% 

P_OS = 10; % 10% overshoot

zeta_min = -log(P_OS/100)/(sqrt(pi^2 + log(P_OS/100)^2))

ts = 2.5;

wn_min = 4/(zeta_min*ts);

zeta_min = 0.5912
wn_min = 2.7066

G = 1/((s+1)*(s+4));

controlSystemDesigner(G)
