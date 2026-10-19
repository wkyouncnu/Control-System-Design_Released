clc; clear all; close all;

s = tf('s');

% GH = (s+3)/(3*(s+1)*(s+2));
G = 1/(s*(s+2)*(s+5));
% controlSystemDesigner(G);
C = 25*(s+1);  % PD 제어기
H = 1;

% G_cl = G*C/(1+C*G*H)
% G_cl = minreal(G_cl)

G_cl_2 = feedback(C*G*H, 1);

Info = stepinfo(G_cl_2)

t = 0:0.01:10;
y = step(G_cl_2, t);

figure()
plot(t, y, 'LineWidth', 2);
grid on; xlabel('time (s)'); 
ylabel('step response (y)');



