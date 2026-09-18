%% W01_03_run_simulink.m
%  1주차 실습 (3) : Simulink 모델을 돌리고 MATLAB 계산 결과와 맞춰 보기
%
%  이 스크립트가 이번 주차에서 가장 중요합니다.
%  W01_01 에서 우리는 전달함수와 feedback 명령으로 "계산"을 했습니다.
%  이제 똑같은 시스템을 Simulink 블록선도로 "시뮬레이션"해서
%  두 결과가 정말 같은지 확인합니다.
%
%  왜 이 확인이 중요한가
%    - 전달함수는 수학적 표현이고 블록선도는 물리적 구성입니다.
%      둘이 같은 것을 가리킨다는 확신이 있어야 앞으로 마음 놓고 오갈 수 있습니다.
%    - 실무에서 플랜트 모델은 대부분 전달함수가 아니라 Simulink 블록선도로 옵니다.
%      블록선도를 해석 도구로 다룰 줄 알아야 합니다.
%    - 나중에 포화, 잡음, 비선형처럼 전달함수로 표현할 수 없는 요소가 들어오면
%      Simulink 만이 답을 줍니다. 그때를 대비한 준비운동입니다.
%
%  대응하는 모델   : W01_OpenClosed.slx
%  모델 재생성     : W01_build_model.m (교수자용, 평소에는 실행할 필요 없음)
%
%  [Simulink 만으로도 볼 수 있습니다]
%  이 스크립트를 돌리지 않아도 됩니다. 모델을 그냥 열고 Ctrl+T 를 누르면
%  Scope 두 개가 자동으로 열리며 결과가 나옵니다.
%      >> open_system('W01_OpenClosed')
%  이 스크립트는 값을 바꿔 가며 실험하고, MATLAB 계산 결과와 숫자로
%  대조하고 싶을 때 씁니다.
%
%  [명령어 사용법이 궁금하면]
%  sim, interp1 을 비롯해 이 스크립트에 나오는 명령의 원리와 입출력은
%  W01_LectureNote.mlx 의 1부와 3부에 정리해 두었습니다.
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

model = 'W01_OpenClosed';

%% 0. 이 모델은 어떤 블록으로 되어 있나
%
%  모델을 열기 전에 안에 무엇이 들어 있는지 먼저 읽고 들어갑니다.
%  블록 하나가 무슨 계산을 하는지, 그리고 왜 하필 거기 있는지를
%  아래 표가 한 줄씩 알려 줍니다. 표를 소리 내어 읽으면서
%  모델 창에서 그 블록을 하나씩 짚어 보십시오.
%
%  같은 표가 .slx 안에도 주석으로 붙어 있습니다. 두 곳의 글은 항상 같습니다.
%  원본은 common/model_blocks.m 한 곳뿐이고, 나머지는 모두 그것을 불러다 씁니다.

model_blocks(model, 'print');

%% 1. 파라미터 설정
%
%  Simulink 모델의 블록에는 숫자가 아니라 변수 이름이 적혀 있습니다.
%  (예: Transfer Fcn 의 분모가 [m b k] 라고 적혀 있습니다)
%  따라서 모델을 돌리기 전에 이 변수들을 워크스페이스에 만들어 두어야 합니다.
%
%  이렇게 만들어 두면 스크립트에서 값만 바꿔 가며 모델을 반복 실행할 수 있습니다.
%  블록을 일일이 더블클릭해서 숫자를 고치는 것보다 훨씬 빠르고 실수도 없습니다.

[G, p] = plant_msd();           % MATLAB 쪽 전달함수 (비교 기준)

m = p.m;   b = p.b;   k = p.k;  % 플랜트 파라미터  -> Transfer Fcn 블록이 사용

r     = 1;                      % 목표 변위 [m]        -> Step 블록
d     = 0.5;                    % 외란 크기 [N]        -> Step 블록

t_d   = 40;                     % 외란 유입 시각 [s]   -> Step 블록
t_end = 100;                    % 시뮬레이션 종료 [s]  -> 솔버 StopTime

K   = 9;                                        % 비례이득
Kff = 1 / dcgain(G);                            % 개루프 보정
Kr  = 1 / dcgain(feedback(K*G, 1));             % 기준입력 스케일링

fprintf('=== 파라미터 ===\n');
fprintf('  m=%.2f  b=%.2f  k=%.2f\n', m, b, k);
fprintf('  r=%.1f  d=%.1f  t_d=%d s\n', r, d, t_d);
fprintf('  K=%d  Kff=%.4f  Kr=%.4f\n\n', K, Kff, Kr);

%% 2. Simulink 모델 실행
%
%  sim 명령으로 모델을 실행합니다.
%  모델 안의 To Workspace 블록이 결과를 out 구조체에 담아 돌려줍니다.

fprintf('Simulink 모델 실행 중...\n');
out = sim(model);

ts_open  = out.y_open_sim;      % timeseries 객체
ts_close = out.y_close_sim;

fprintf('완료. 개루프 %d 점, 폐루프 %d 점을 받았습니다.\n\n', ...
        numel(ts_open.Time), numel(ts_close.Time));

%% 3. MATLAB 쪽에서 같은 계산 수행
%
%  W01_01 의 5절과 완전히 같은 계산입니다.
%  다만 비교를 위해 시간 격자를 균일하게 잡습니다.

t = (0:0.01:t_end)';

u_ref = r * ones(size(t));
u_dis = d * (t >= t_d);

% 개루프 : y = Kff*G*r + G*d   (중첩의 원리)
y_open_mat  = lsim(Kff*G, u_ref, t) + lsim(G, u_dis, t);

% 폐루프 : y = Kr*T*r + (G/(1+K*G))*d
y_close_mat = lsim(Kr*feedback(K*G,1), u_ref, t) + lsim(feedback(G,K), u_dis, t);

%% 4. 두 결과를 같은 시간 격자로 옮겨 비교
%
%  Simulink 는 가변스텝 솔버(ode45)를 쓰기 때문에 시간 간격이 일정하지 않습니다.
%  MATLAB 계산 결과와 숫자로 비교하려면 같은 시각의 값이 필요하므로
%  interp1 로 균일 격자 위에 올려놓습니다.

y_open_sim  = interp1(ts_open.Time,  squeeze(ts_open.Data),  t);
y_close_sim = interp1(ts_close.Time, squeeze(ts_close.Data), t);

err_open  = max(abs(y_open_sim  - y_open_mat));
err_close = max(abs(y_close_sim - y_close_mat));

fprintf('=== MATLAB 계산 vs Simulink 시뮬레이션 ===\n');
fprintf('  개루프 최대 차이 : %.3e m\n', err_open);
fprintf('  폐루프 최대 차이 : %.3e m\n', err_close);

tol = 1e-3;
if err_open < tol && err_close < tol
    fprintf('  --> 두 결과가 일치합니다. 전달함수와 블록선도는 같은 시스템입니다.\n\n');
else
    fprintf('  --> 차이가 큽니다. 파라미터나 결선을 확인하십시오.\n\n');
end

%% 5. 겹쳐 그리기
%
%  선이 완전히 포개져서 하나처럼 보이면 성공입니다.
%  Simulink 결과는 실선, MATLAB 결과는 굵은 점선으로 그려 구분합니다.

figure()
tiledlayout(2,1);

nexttile
h1 = plot(t, y_open_sim, 'LineWidth', 2); hold on;
h2 = plot(t, y_open_mat, '--', 'LineWidth', 2);
h3 = yline(r, 'k:', 'LineWidth', 1.5);
xline(t_d, 'r:', 'LineWidth', 1.5);
grid on;
ylabel('x [m]');
title(sprintf('개루프 : Simulink vs MATLAB   (최대 차이 %.1e m)', err_open));
legend([h1 h2 h3], {'Simulink', 'MATLAB (lsim)', '목표값 r'}, 'Location','southeast');
ylim([0 2]);

nexttile
h1 = plot(t, y_close_sim, 'LineWidth', 2); hold on;
h2 = plot(t, y_close_mat, '--', 'LineWidth', 2);
h3 = yline(r, 'k:', 'LineWidth', 1.5);
xline(t_d, 'r:', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('x [m]');
title(sprintf('폐루프 : Simulink vs MATLAB   (최대 차이 %.1e m)', err_close));
legend([h1 h2 h3], {'Simulink', 'MATLAB (lsim)', '목표값 r'}, 'Location','southeast');
ylim([0 2]);

%% 6. 직접 해 볼 것 (과제 아님, 수업 중 실습)
%
%  아래 값을 바꿔 가며 이 스크립트를 다시 실행해 보십시오.
%  블록을 건드릴 필요 없이 1절의 숫자만 고치면 됩니다.
%
%   (1) K = 30 으로 키우면?
%       -> 외란을 더 잘 잡지만 진동이 더 심해집니다.
%
%   (2) K = 0.5 로 줄이면?
%       -> 진동은 얌전해지지만 외란에 크게 밀립니다.
%
%   (3) d = 2 로 외란을 키우면?
%       -> 개루프는 완전히 무너지고, 폐루프는 비율만큼만 밀립니다.
%
%   (4) 모델을 열어(open_system('W01_OpenClosed')) 폐루프의 되먹임 선을 지우면?
%       -> 폐루프가 개루프와 똑같아집니다. 되먹임 선 하나가 전부라는 뜻입니다.
%
%  마지막으로 모델을 직접 열어서 구조를 눈으로 확인하십시오:
%      >> open_system('W01_OpenClosed')
