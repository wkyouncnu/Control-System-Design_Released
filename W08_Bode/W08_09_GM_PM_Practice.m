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

T1 = feedback(sys1, 1);
T2 = feedback(sys2, 1);
T3 = feedback(sys3, 1);


t = 0:0.01:30;
y1 = step(T1, t);
y2 = step(T2, t);
y3 = step(T3, t);

figure()
plot(t, y1); hold on;
plot(t, y2); hold on;
plot(t, y3); hold on;
