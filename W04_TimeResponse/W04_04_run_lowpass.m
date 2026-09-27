%% W04_04_run_lowpass.m
%  4주차 실습 (4) : 1차 시스템은 왜 저역통과 필터인가
%
%  이 스크립트에서 답할 질문
%    Q1. 느린 사인과 빠른 사인을 섞어 넣으면 무엇이 살아남는가   -> 2절
%    Q2. 크기비 공식 1/sqrt(1+(w*tau)^2) 이 실제로 맞는가        -> 3절
%    Q3. 차단주파수 w = 1/tau 에서 정말 0.707 배가 되는가        -> 4절
%
%  돌리면 나오는 것
%    그림 2장 (섞인 신호의 필터 통과, 크기비 곡선) + 표 1개 (공식 대 실측)
%    걸리는 시간 : 약 10 초
%
%  대응하는 강의노트 : W04_LectureNote.mlx 의 2-2 ~ 2-5 절
%  대응하는 Simulink : W04_LowPass.slx
%
%  제어시스템설계 4주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;
s = tf('s');

model = 'W04_LowPass';
here  = fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model), load_system(fullfile(here, [model '.slx'])); end

%% 0. 이 모델은 어떤 블록으로 되어 있나
%  표를 소리 내어 읽으면서 모델 창에서 블록을 하나씩 짚어 보십시오.
model_blocks(model, 'print');

%% 1. 파라미터
%  tau 를 키우면 필터가 더 느려지고, 더 낮은 주파수부터 깎아 냅니다.
tau  = 1;        % 시정수 [s]
w_lo = 0.2;      % 살리고 싶은 느린 신호 [rad/s]
w_hi = 10;       % 걸러 내고 싶은 빠른 잡음 [rad/s]
a_lo = 1;        % 느린 신호의 진폭
a_hi = 0.5;      % 빠른 잡음의 진폭
t_end = 60;

fprintf('\n차단주파수 w_c = 1/tau = %.2f rad/s\n', 1/tau);
fprintf('  저주파 %.1f rad/s 는 차단주파수보다 낮으므로 통과합니다.\n', w_lo);
fprintf('  고주파 %.1f rad/s 는 차단주파수보다 높으므로 깎입니다.\n\n', w_hi);

%% 2. 섞인 신호를 통과시켜 본다
out = sim(model, 'StopTime', num2str(t_end));
uy  = out.uy_sim;                    % 1열 입력, 2열 출력
t   = uy.Time;
u   = uy.Data(:,1);
y   = uy.Data(:,2);

figure()
plot(t, u, 'LineWidth', 1.2, 'Color', [0.6 0.6 0.6]); hold on; grid on
plot(t, y, 'LineWidth', 2.2)
xlim([20 40])                        % 처음 과도구간을 지난 뒤를 본다
xlabel('시간 [s]'); ylabel('신호')
legend('입력 (느린 신호 + 빠른 잡음)', '출력 (필터를 지난 뒤)')
title('빠른 잡음만 깎여 나간다')

fprintf('입력의 들쭉날쭉한 정도 : %.3f\n', std(u(t>20)));
fprintf('출력의 들쭉날쭉한 정도 : %.3f   <- 잡음이 줄었다\n\n', std(y(t>20)));

%% 3. 크기비 공식이 맞는지 주파수마다 확인
%  한 번에 한 주파수만 넣어 정상상태 진폭을 잽니다.
w_list = [0.1 0.2 0.5 1 2 5 10];
A_meas = zeros(size(w_list));
A_form = 1 ./ sqrt(1 + (w_list*tau).^2);      % 유도한 공식

G = 1/(tau*s + 1);
for i = 1:numel(w_list)
    tt = (0:0.001:80)';
    uu = sin(w_list(i)*tt);
    yy = lsim(G, uu, tt);
    A_meas(i) = max(yy(tt > 60));             % 정상상태에서의 진폭
end

fprintf('   w [rad/s]   공식 크기비   실측 크기비\n');
fprintf('  ----------  -----------  -----------\n');
for i = 1:numel(w_list)
    fprintf('  %10.2f  %11.4f  %11.4f\n', w_list(i), A_form(i), A_meas(i));
end

%% 4. 차단주파수에서 0.707 배인지 확인
A_cut = 1/sqrt(1 + (1/tau*tau)^2);
fprintf('\nw = 1/tau 에서 크기비 = %.4f  (= 1/sqrt(2) = %.4f)\n', A_cut, 1/sqrt(2));
fprintf('데시벨로는 %.2f dB 입니다. 그래서 -3 dB 점이라고 부릅니다.\n\n', 20*log10(A_cut));

figure()
w_plot = logspace(-2, 2, 400);
loglog(w_plot, 1./sqrt(1 + (w_plot*tau).^2), 'LineWidth', 2.4); hold on; grid on
loglog(w_list, A_meas, 'o', 'MarkerSize', 9, 'LineWidth', 2)
yline(1/sqrt(2), 'k--'); xline(1/tau, 'k:')
xlabel('주파수 \omega [rad/s]'); ylabel('크기비')
legend('공식 1/\surd(1+(\omega\tau)^2)', '실측', 'Location','southwest')
title('공식과 실측이 겹친다 — 그래서 저역통과 필터다')

%% 5. 이번 실습의 정리
%  - 1차 시스템은 느린 신호를 통과시키고 빠른 신호를 깎는다
%  - 경계는 w = 1/tau 이고 그 자리에서 0.707 배 (-3 dB) 가 된다
%  - tau 를 키우면 경계가 낮아져 더 많이 걸러 내지만, 응답도 그만큼 느려진다
%
%  다음 실습 : 9주차에서 이 크기비 곡선을 보드 선도로 다시 그립니다.
