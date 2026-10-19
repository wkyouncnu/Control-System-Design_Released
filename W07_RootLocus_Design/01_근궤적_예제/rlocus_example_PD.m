clc; close all; clear all;

s = tf('s');

GH_P = 1/((s+1)*(s+2))

GH_PD = (s+3)/(3*(s+1)*(s+2))

figure()
subplot(1,2,1);
rlocus(GH_P)
grid on;
subplot(1,2,2);
rlocus(GH_PD)
grid on;