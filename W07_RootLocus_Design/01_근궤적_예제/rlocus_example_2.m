s = tf('s');
G_s = 1/((s+1)*(s+2));
 
t= 0:0.001:5;
%% K = 3
K = 3;
GT_3=feedback(K*G_s,1);
K_3 = step(GT_3,t);
S_3 = stepinfo(GT_3)
 
%% K = 8
K = 8;
GT_8=feedback(K*G_s,1);
K_8 = step(GT_8,t);
S_8 = stepinfo(GT_8)
 
%% K =38
K = 36;
GT_36=feedback(K*G_s,1);
K_36 = step(GT_36,t);
S_36 = stepinfo(GT_36)
 
figure(2)
plot(t, K_3, 'LineWidth', 2); hold on;
plot(t, K_8, 'LineWidth', 2); hold on;
plot(t, K_36, 'LineWidth', 2); hold on;
grid on;
legend('K = 3', 'K = 8', 'K = 36');
ylim([0 2])
xlabel('Time (s)');
ylabel('Output');


zeta_36 = 0.243;

% MOS = max(K_36)-1;
% y_ss = K_36(end);
% 
% MOS/y_ss * 100;

100*exp((-zeta_36*pi)/sqrt(1-zeta_36^2))




