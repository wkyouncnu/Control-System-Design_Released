%% W12_03_run_simulink.m
%  12주차 실습 (3) : Simulink 로 모드를 눈으로 보기
%
%  모델 W12_StateSpace_Modes.slx 를 열어 보십시오.
%
%      >> open_system('W12_StateSpace_Modes')
%
%  블록이 세 개뿐입니다. Step, State-Space, Scope.
%  그런데 State-Space 블록에는 전달함수 블록에 **없는 칸**이 하나 있습니다.
%
%      Initial conditions   <-- 이것
%
%  전달함수는 초기조건이 0 이라는 가정 위에서 유도한 것이라 이 칸이 없습니다.
%  오늘은 입력을 아예 0 으로 두고, **초기조건만으로** 시스템을 움직입니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 고유벡터 방향으로 출발하면 정말 지수함수 하나인가?  -> 2절
%    Q2. 아무 방향으로 출발하면 어떻게 되는가?               -> 3절
%    Q3. 불안정한 모드가 하나 있으면 어떻게 되는가?          -> 4절
%
%  돌리면 나오는 것
%    표 3개 + 그림 3장. Simulink 를 6 번 부릅니다
%    걸리는 시간 : 약 20 초 (첫 실행은 모델 컴파일 때문에 더 걸립니다)
%
%  대응하는 강의노트 : W12_LectureNote.mlx
%
%  제어시스템설계 12주차 | 충남대학교 자율운항시스템공학과

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

model = 'W12_StateSpace_Modes';
here  = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
if ~bdIsLoaded(model), load_system(fullfile(here, [model '.slx'])); end

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
%  Simulink 모델의 블록에는 숫자 대신 **변수 이름**이 적혀 있습니다.
%  그래서 여기서 값을 정하고 sim 을 부르면 그 값으로 돕니다.
%
%  오늘 쓰는 예제는 고유값이 -1 과 -2 인 2차 시스템입니다.

A_mat = [0 1; -2 -3];        % 고유값 -1, -2
B_mat = [0; 1];
C_mat = eye(2);              % 상태를 전부 뽑는다
D_mat = [0; 0];
u_amp = 0;                   % 입력은 0. 초기조건만으로 움직인다
t_end = 6;

[V, D] = eig(A_mat);
lam    = diag(D);

fprintf('=== 1. 오늘의 시스템 ===\n');
fprintf('  A = %s\n', mat2str(A_mat));
fprintf('  고유값   : %s\n', mat2str(round(lam.', 4)));
fprintf('  고유벡터 : v1 = %s,  v2 = %s\n\n', ...
        mat2str(round(V(:,1).', 4)), mat2str(round(V(:,2).', 4)));

fprintf('  고유벡터를 읽는 법\n');
fprintf('    v1 은 "이 방향으로 출발하면 e^(%.0f t) 로만 줄어든다" 는 뜻입니다.\n', lam(1));
fprintf('    v2 는 "이 방향이면 e^(%.0f t) 로만 줄어든다" 는 뜻입니다.\n\n', lam(2));

%% 2. 고유벡터 방향으로 출발하면
%
%  고유벡터 방향으로 초기조건을 주고 Simulink 를 돌립니다.
%  나오는 응답이 **지수함수 하나**여야 합니다.

x0_list = { sprintf('v1 방향 (lambda = %.0f)', lam(1)), V(:,1)
            sprintf('v2 방향 (lambda = %.0f)', lam(2)), V(:,2)
            '아무 방향 [1; 0]',                        [1; 0] };

Y = cell(3,1);  T = cell(3,1);
for k = 1:3
    x0  = x0_list{k,2};                                          %#ok<NASGU>
    out = sim(model, 'StopTime', num2str(t_end));
    ts  = out.x_sim;                                             % Timeseries
    T{k} = ts.Time;   Y{k} = ts.Data;
end

figure('Name', '고유벡터 방향에서 출발하면');
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for k = 1:2
    plot(T{k}, Y{k}(:,1), 'LineWidth', 2.4, 'DisplayName', x0_list{k,1});
end
% 이론값(순수 지수함수)을 점선으로 겹쳐 확인
for k = 1:2
    plot(T{k}, V(1,k)*exp(lam(k)*T{k}), 'k--', 'LineWidth', 1.4, ...
         'HandleVisibility', 'off');
end
xlabel('시간 [s]'); ylabel('x_1');
legend('Location', 'northeast');
title('실선 = Simulink, 검은 점선 = 이론 e^{\lambda t}');

nexttile
hold on; grid on;
for k = 1:3
    plot(Y{k}(:,1), Y{k}(:,2), 'LineWidth', 2.4, 'DisplayName', x0_list{k,1});
end
% 고유벡터 방향을 직선으로
r = 1.2;
for k = 1:2
    v = V(:,k)/norm(V(:,k));
    plot(r*[-v(1) v(1)], r*[-v(2) v(2)], ':', 'LineWidth', 1.6, ...
         'HandleVisibility', 'off');
end
xline(0, 'k-', 'HandleVisibility', 'off');
yline(0, 'k-', 'HandleVisibility', 'off');
axis equal; xlim([-1.2 1.2]); ylim([-1.2 1.2]);
xlabel('x_1'); ylabel('x_2');
legend('Location', 'northeast');
title('상태평면 — 고유벡터 위에서 출발하면 직선으로 간다');

fprintf('=== 2. 확인 ===\n');
for k = 1:2
    theo = V(1,k)*exp(lam(k)*T{k});
    fprintf('  %s : Simulink 와 이론의 최대 차이 %.2e\n', ...
            x0_list{k,1}, max(abs(Y{k}(:,1) - theo)));
end
fprintf('  --> 고유벡터 방향에서는 응답이 정확히 지수함수 하나입니다.\n\n');

%% 3. 아무 방향으로 출발하면 — 모드가 섞인다
%
%  x(0) = [1; 0] 은 고유벡터가 아닙니다. 그러면 두 모드가 섞입니다.
%
%      x(0) = c1*v1 + c2*v2
%      x(t) = c1*e^(lam1 t)*v1 + c2*e^(lam2 t)*v2
%
%  계수 c 는 고유벡터로 좌표를 바꾸면 나옵니다 :  c = V \ x0

c = V \ [1; 0];
fprintf('=== 3. 모드 분해 ===\n');
fprintf('  x(0) = [1;0] = %.4f * v1 + %.4f * v2\n', c(1), c(2));
fprintf('  따라서 x1(t) = %.4f*%.4f*e^(%.0ft) + %.4f*%.4f*e^(%.0ft)\n\n', ...
        c(1), V(1,1), lam(1), c(2), V(1,2), lam(2));

t3 = T{3};
m1 = c(1)*V(1,1)*exp(lam(1)*t3);
m2 = c(2)*V(1,2)*exp(lam(2)*t3);

figure('Name', '모드 분해');
plot(t3, Y{3}(:,1), 'LineWidth', 3, 'Color', [0.15 0.35 0.75]); hold on; grid on;
plot(t3, m1, '--', 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
plot(t3, m2, '--', 'LineWidth', 2, 'Color', [0.47 0.67 0.19]);
plot(t3, m1 + m2, ':', 'LineWidth', 2.4, 'Color', 'k');
xlabel('시간 [s]'); ylabel('x_1');
legend('Simulink 결과', ...
       sprintf('느린 모드 e^{%.0ft}', lam(1)), ...
       sprintf('빠른 모드 e^{%.0ft}', lam(2)), ...
       '두 모드의 합', 'Location', 'northeast');
title('아무 방향에서 출발하면 두 모드가 섞인다');

fprintf('  합과 Simulink 결과의 최대 차이 : %.2e\n', max(abs(Y{3}(:,1) - m1 - m2)));
fprintf('  --> 어떤 응답이든 **모드의 합**으로 쪼갤 수 있습니다.\n');
fprintf('      시간이 지나면 빠른 모드가 먼저 사라지고 느린 모드만 남습니다.\n');
fprintf('      그래서 응답의 꼬리는 **가장 느린 고유값**이 정합니다.\n\n');

%% 4. 불안정한 모드가 하나 있으면
%
%  고유값 하나만 우반면으로 옮겨 봅니다. 나머지는 그대로입니다.
%  거꾸로 선 진자가 정확히 이 상황입니다.

A_mat = [0 1; 2 -1];         % 고유값 +1, -2
[Vu, Du] = eig(A_mat);
lam_u = diag(Du);
fprintf('=== 4. 불안정한 모드 ===\n');
fprintf('  A = %s,  고유값 = %s\n', mat2str(A_mat), mat2str(round(lam_u.', 4)));

x0_u = { '안정한 고유벡터 방향', Vu(:, real(lam_u) < 0)
         '아주 살짝 틀어서',     Vu(:, real(lam_u) < 0) + [0.001; 0] };

figure('Name', '불안정한 모드');
hold on; grid on;
for k = 1:2
    x0  = x0_u{k,2};                                             %#ok<NASGU>
    out = sim(model, 'StopTime', '6');
    ts  = out.x_sim;
    plot(ts.Time, ts.Data(:,1), 'LineWidth', 2.4, 'DisplayName', x0_u{k,1});
end
yline(0, 'k:', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('x_1');
legend('Location', 'northwest');
title('안정한 고유벡터 위에 정확히 있으면 안 넘어간다 — 현실에서는 불가능');

fprintf('  안정한 고유벡터 방향에 **정확히** 놓으면 그 모드만 살아서 잦아듭니다.\n');
fprintf('  그런데 0.001 만 틀어도 불안정 모드가 섞여 들어와 결국 발산합니다.\n');
fprintf('  --> 현실에서는 정확히 놓을 수 없습니다.\n');
fprintf('      **고유값 하나라도 우반면이면 그 시스템은 불안정합니다.**\n\n');

%% 5. 직접 해 볼 것
%
%  - 모델을 열어 State-Space 블록을 더블클릭하고 Initial conditions 칸을 보십시오
%  - x0 를 [0;1] 로 바꿔 돌려 보십시오. 어느 모드가 더 크게 섞이나요?
%  - A 를 [0 1; -1 -0.2] (복소 고유값) 로 바꾸면 상태평면이 어떤 모양이 되나요?
%  - Scope 를 열어 두 상태를 함께 보십시오. 위치가 최대일 때 속도가 0 입니까?

fprintf('=== 정리 ===\n');
fprintf('  1. State-Space 블록은 초기조건을 받는다. 전달함수 블록은 못 받는다\n');
fprintf('  2. 고유벡터 방향에서 출발하면 응답이 지수함수 하나\n');
fprintf('  3. 아무 방향이면 모드의 합. 느린 모드가 꼬리를 정한다\n');
fprintf('  4. 고유값 하나라도 우반면이면 불안정하다\n');
fprintf('  --> 13주차에서는 이 고유값들을 **원하는 자리로 옮깁니다.**\n');
