D_s_G_s=tf([1 3],3*[1 3 2]);
rlocus(D_s_G_s)
t=0:0.001:5;
% K = 3
K = 3;
GT_3=feedback(K*D_s_G_s,1);
K_3 = step(GT_3,t);
% K = 8
K = 8;
GT_8=feedback(K*D_s_G_s,1);
K_8 = step(GT_8,t);
% K =38
K = 38;
GT_38=feedback(K*D_s_G_s,1);
K_38 = step(GT_38,t);
 
figure()
plot(t, K_3, 'LineWidth', 2); hold on;
plot(t, K_8, 'LineWidth', 2); hold on;
plot(t, K_38, 'LineWidth', 2); hold on;
grid on;
legend('K = 3', 'K = 8', 'K = 38');
ylim([0 2])
xlabel('Time (s)');
ylabel('Output');

%% P 제어 (K = 38)
G_s = 1/((s+1)*(s+2));
K = 38;
GT_38=feedback(K*G_s,1);
K_38_P = step(GT_38,t);

figure()
plot(t, K_38_P, 'LineWidth', 2); hold on;  % P 제어
plot(t, K_38, 'LineWidth', 2); hold on;    % PD 제어
grid on;
legend('P(K=38)', 'PD (K = 38)');
ylim([0 2])
xlabel('Time (s)');
ylabel('Output');


% PD 제어에서 zeta = 0.94 (wn 이 큰 경우) 일때 sgrid함수를 사용하여 K 값 (rlocfind) 을 찾고, 그때 
% 정착시간 ts를 계산하고, 실제 그래프와 비교 하고, Peak time을 식과 실제 값과 비교하라.

% zeta = 0.94일때 
% 아래의 계산 식과 실제 값을 구하시오
% 계산식
% ts = 4/(zeta*wn)  
% tp = pi/(wn*sqrt(1-zeta^2))

% 실제값
% stepinfo 