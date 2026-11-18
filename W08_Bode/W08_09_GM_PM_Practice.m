clc; clear all; close all;

s = tf('s');
G = 1/(s*(s+1)^2);

% controlSystemDesigner(G)

figure()
rlocus(G)

K1 = 0.5;
K2 = 2;
K3 = 3;
sys1 = K1*G;
sys2 = K2*G;
sys3 = K3*G;

figure()
margin(sys1); hold on;
margin(sys2); hold on;
margin(sys3); hold on;

