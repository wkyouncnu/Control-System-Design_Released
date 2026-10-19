clc; close all; clear all;

s = tf('s');

G = 1/((s+1)*(s+2));
H = 1;
K = 1;

% G_cl = G/(1+G*H)
% G_cl = minreal(G_cl)

G_cl_1 = feedback(G, H);   % K = 1
G_cl_2 = feedback(2*G, H); % K = 2

t = 0:0.001:10;
y_1 = step(G_cl_1,t); % K = 1
y_2 = step(G_cl_2,t); % K = 2

figure()
plot(t,y_1, 'LineWidth', 2); hold on;
plot(t,y_2, 'LineWidth', 2);
xlabel('time (s)');
ylabel('y(t)');
title('Step response');
legend('K = 1', 'K = 2');
grid on;

figure()
rlocus(G*H)
% grid on;
% sgrid([0.6 0.7 0.8], [])
sgrid([], [1 2 3])
axis([-3 3 -7 7]);

% [K, poles] = rlocfind(G*H)
% grid on;
