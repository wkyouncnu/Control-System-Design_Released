%% W01_02_model_uncertainty.m
%  1주차 실습 (2) : 모델이 틀렸을 때 개루프와 폐루프는 어떻게 갈리는가
%
%  앞의 W01_01 에서는 외란을 다뤘습니다.
%  이번에는 외란이 전혀 없는 대신, 우리가 알고 있는 모델 자체가 틀린 상황을 봅니다.
%
%  현실에서 모델은 반드시 틀립니다.
%    - 스프링 상수는 온도에 따라 변합니다.
%    - 부품마다 편차가 있습니다 (같은 모터도 개체차가 있습니다).
%    - 배는 화물을 실으면 질량이 변합니다.
%    - 마찰계수는 애초에 정확히 알 수가 없습니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 스프링이 예상보다 50% 뻣뻣하면 개루프는 얼마나 틀리는가?  -> 2절
%    Q2. 같은 상황에서 폐루프는?                                    -> 3절
%    Q3. 왜 폐루프가 둔감한가? 수식으로 설명할 수 있는가?           -> 4절
%    Q4. 오차 범위를 넓게 훑어보면 어떤 그림이 나오는가?            -> 5절
%
%  대응하는 강의노트 : W01_LectureNote.mlx
%
%  [명령어 사용법이 궁금하면]
%  tf, step, dcgain, feedback 의 원리와 입출력은
%  W01_LectureNote.mlx 의 1부에 자세히 정리해 두었습니다.
%
%  제어시스템설계 1주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 경로 자동 등록 — setup_path 를 아직 안 했어도 알아서 잡습니다
%  (이 블록은 실습 내용과 상관없습니다. 지우지 마십시오.)
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end
s = tf('s');

%% 1. 두 개의 플랜트 : 설계용 모델과 실제 플랜트
%
%  우리가 책상에서 설계할 때 쓰는 모델을 G_design 이라고 합시다.
%  그런데 실험실에 가서 실제로 만들어 보니 스프링이 예상보다 뻣뻣했습니다.
%  이 진짜 시스템을 G_true 라고 합시다.
%
%  중요한 점: 우리는 G_true 를 모릅니다.
%  알았다면 애초에 그걸로 설계했겠지요. 설계는 오직 G_design 만 보고 합니다.

k_design = 1.0;                 % 설계할 때 가정한 스프링 상수 [N/m]
k_true   = 1.5;                 % 실제 스프링 상수 [N/m]  (50% 더 뻣뻣했다)

[G_design, pd] = plant_msd([], [], k_design);
[G_true,   pt] = plant_msd([], [], k_true);

fprintf('=== 1절. 두 플랜트 비교 ===\n');
fprintf('  설계 모델 : k = %.2f,  G(0) = %.4f\n', k_design, dcgain(G_design));
fprintf('  실제 플랜트: k = %.2f,  G(0) = %.4f\n', k_true,   dcgain(G_true));
fprintf('  모델 오차 : %.0f %%\n\n', 100*(k_true-k_design)/k_design);

t = 0:0.01:100;
r = 1;                          % 목표 변위 1 m

%% 2. 개루프 제어의 결과 : 틀린 만큼 그대로 틀린다
%
%  개루프 제어기는 설계 모델을 보고 Kff = 1/G_design(0) 로 정해집니다.
%  이 제어기를 실제 플랜트에 붙이면 정상상태 출력은
%
%      y_ss = Kff * G_true(0) = G_true(0) / G_design(0)
%
%  가 됩니다. 즉 모델 오차가 출력 오차로 1:1 로 전달됩니다.
%  스프링이 1.5배 뻣뻣하면 1.5배 덜 밀립니다. 그게 전부입니다.

Kff = 1 / dcgain(G_design);     % 설계 모델만 보고 정한 값

y_open = step(r * Kff * G_true, t);
e_open = r - y_open(end);

fprintf('=== 2절. 개루프 제어 (실제 플랜트에 적용) ===\n');
fprintf('  Kff = %.4f  (설계 모델 기준으로 정함)\n', Kff);
fprintf('  정상상태 출력 = %.4f m\n', y_open(end));
fprintf('  정상상태 오차 = %.4f m  (%.1f %%)\n', e_open, 100*e_open/r);
fprintf('  --> DC 이득이 %.1f%% 틀리니 출력도 정확히 그만큼 틀렸습니다.\n', ...
        100*(dcgain(G_design)-dcgain(G_true))/dcgain(G_design));
fprintf('      개루프에는 이를 막을 방어수단이 전혀 없습니다.\n\n');

%% 3. 폐루프 제어의 결과 : 훨씬 덜 틀린다
%
%  폐루프 제어기도 똑같이 설계 모델만 보고 정합니다.
%  비례이득 K 와 기준입력 스케일링 Kr 을 G_design 기준으로 계산합니다.
%  그리고 그 제어기를 그대로 실제 플랜트에 붙입니다.

K  = 9;
Kr = 1 / dcgain(feedback(K*G_design, 1));   % 설계 모델 기준

T_true  = Kr * feedback(K*G_true, 1);       % 실제 플랜트에 붙였을 때의 폐루프
y_close = step(r * T_true, t);
e_close = r - y_close(end);

fprintf('=== 3절. 폐루프 제어 (실제 플랜트에 적용) ===\n');
fprintf('  K = %d,  Kr = %.4f  (둘 다 설계 모델 기준으로 정함)\n', K, Kr);
fprintf('  정상상태 출력 = %.4f m\n', y_close(end));
fprintf('  정상상태 오차 = %.4f m  (%.1f %%)\n', e_close, 100*e_close/r);
fprintf('  --> 개루프 오차의 약 %.1f 분의 1 로 줄었습니다.\n\n', abs(e_open/e_close));

figure()
h1 = plot(t, y_open,  'LineWidth', 2); hold on;
h2 = plot(t, y_close, 'LineWidth', 2);
h3 = yline(r, 'k--', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('Displacement x [m]');
title(sprintf('스프링이 설계값보다 %.0f%% 뻣뻣할 때', 100*(k_true-k_design)/k_design));
legend([h1 h2 h3], ...
       {sprintf('개루프 (오차 %.1f%%)',  100*abs(e_open)/r), ...
        sprintf('폐루프 (오차 %.1f%%)', 100*abs(e_close)/r), ...
        '목표값 r'}, 'Location', 'southeast');
ylim([0 1.6]);

%% 4. 왜 폐루프가 둔감한가
%
%  이것은 운이 좋아서가 아니라 정해진 성질입니다. 그런데 이유는 아주 간단합니다.
%
%  폐루프에서 오차가 생기면 제어기가 그만큼 힘을 더 냅니다.
%  스프링이 뻣뻣해서 덜 밀렸다면, 제어기가 "덜 갔네" 하고 더 밀어 줍니다.
%  개루프는 이 과정이 없습니다. 정해진 힘만 주고 끝입니다.
%
%  그 "얼마나 덜 틀리는가"의 비율이 아래 값입니다.
%
%      1 / (1 + 루프이득)
%
%  루프이득이란 신호가 루프를 한 바퀴 돌 때 곱해지는 값, 즉 K*G(0) 입니다.
%  이 값이 클수록 모델 오차에 둔감해집니다.
%
%  여기서 눈여겨볼 점이 있습니다.
%  W01_01 에서 본 외란 억제비도 똑같은 1/(1+K*G) 였습니다.
%
%  즉 피드백이 주는 두 가지 이득 (외란 버티기, 모델 오차 버티기) 이
%  사실은 같은 값 하나로 설명됩니다. 이 값을 감도(sensitivity)라고 부르고,
%  11주차 주파수영역 설계에서 주인공으로 다시 만납니다.
%  지금은 "1 나누기 (1 + 루프이득)" 이라는 형태만 기억해 두면 충분합니다.

L0 = K * dcgain(G_design);      % 루프이득 (한 바퀴 도는 값)
S0 = 1 / (1 + L0);              % 감도

fprintf('=== 4절. 얼마나 둔감해지는가 ===\n');
fprintf('  루프이득 K*G(0) = %.1f\n', L0);
fprintf('  감도 1/(1+루프이득) = %.3f\n', S0);
fprintf('\n');
fprintf('  개루프 오차 : %.1f %%\n', 100*abs(e_open)/r);
fprintf('  폐루프 오차 : %.1f %%\n', 100*abs(e_close)/r);
fprintf('  실제로 %.1f 배 줄었습니다.\n', abs(e_open/e_close));
fprintf('  --> 루프이득이 %.0f 이니 대략 %.0f 배 정도 줄어드는 것이 맞습니다.\n\n', ...
        L0, 1+L0);

%% 5. 오차 범위를 넓게 훑어보기
%
%  실제 스프링 상수가 설계값의 절반부터 두 배까지 변한다고 가정하고
%  개루프와 폐루프의 정상상태 오차가 어떻게 달라지는지 그려 봅니다.
%
%  덤으로 비례이득 K 를 바꿔 가며 그려서, K 가 클수록 얼마나 더 둔감해지는지도
%  같이 확인합니다.

k_sweep = linspace(0.5, 2.0, 60);       % 실제 k 값의 범위
K_sweep = [1 3 9 30];                   % 비교할 비례이득

err_open = zeros(size(k_sweep));
err_close = zeros(numel(K_sweep), numel(k_sweep));

for j = 1:numel(k_sweep)
    Gt = plant_msd([], [], k_sweep(j));         % 실제 플랜트

    % 개루프 : 설계 모델 기준 Kff 를 실제 플랜트에 적용
    err_open(j) = r - r * Kff * dcgain(Gt);

    % 폐루프 : 각 K 마다 설계 모델 기준 Kr 을 실제 플랜트에 적용
    for i = 1:numel(K_sweep)
        Ki  = K_sweep(i);
        Kri = 1 / dcgain(feedback(Ki*G_design, 1));
        err_close(i,j) = r - r * Kri * dcgain(feedback(Ki*Gt, 1));
    end
end

figure()
h = gobjects(1, numel(K_sweep)+1);
h(1) = plot(k_sweep, 100*abs(err_open)/r, 'k', 'LineWidth', 3); hold on;
for i = 1:numel(K_sweep)
    h(i+1) = plot(k_sweep, 100*abs(err_close(i,:))/r, 'LineWidth', 2);
end
xline(k_design, 'r:', 'LineWidth', 2);
grid on;
xlabel('실제 스프링 상수 k [N/m]   (설계값은 1.0)');
ylabel('정상상태 오차 크기 [%]');
title('5절. 모델이 틀린 정도에 따른 정상상태 오차');
legend(h, [{'개루프'}, arrayfun(@(K) sprintf('폐루프 K = %d', K), K_sweep, ...
       'UniformOutput', false)], 'Location', 'north');

fprintf('=== 5절. 스윕 결과 ===\n');
fprintf('  k = 2.0 (설계값의 2배) 일 때 오차\n');
fprintf('    개루프        : %.1f %%\n', 100*abs(err_open(end))/r);
for i = 1:numel(K_sweep)
    fprintf('    폐루프 K = %2d : %.1f %%\n', K_sweep(i), 100*abs(err_close(i,end))/r);
end
fprintf('\n');

%% 6. 이번 실습의 결론
%
%  1) 개루프의 정확도는 모델의 정확도와 똑같습니다.
%     모델이 틀린 만큼 출력도 그대로 틀립니다. 막을 방법이 없습니다.
%
%  2) 폐루프는 모델이 틀려도 훨씬 덜 틀립니다.
%     오차가 생기면 제어기가 그만큼 더 밀어 주기 때문입니다.
%     이것이 "피드백은 강인하다(robust)"는 말의 뜻입니다.
%
%  3) 외란을 버티는 것도, 모델 오차를 버티는 것도 같은 값 하나로 설명됩니다.
%
%         1 / (1 + 루프이득)
%
%     루프이득이 클수록 둘 다 좋아집니다.
%
%  4) 그러면 K 를 무한히 키우면 되지 않느냐?
%     안 됩니다. W01_01 에서 봤듯이 K 를 키우면 진동이 심해지고,
%     더 키우면 아예 불안정해집니다. 그 한계를 계산하는 것이
%     5주차(안정도), 6주차(근궤적), 10주차(안정여유)의 주제입니다.
%
%  다음 실습 : W01_03_run_simulink.m
%              지금까지 한 계산을 Simulink 블록선도로 다시 만들어
%              두 결과가 정말 같은지 눈으로 확인합니다.
