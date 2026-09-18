%% W14_01_observer.m
%  14주차 실습 (1) : 관측기 — 못 재는 상태를 만들어 낸다
%
%  13주차 내내 u = -K*x 를 썼습니다. 그러려면 x 를 **전부 알아야** 합니다.
%  그런데 현실에서는 각도만 잽니다. 각속도계는 비싸고 잡음이 많습니다.
%
%  오늘 그 문제를 풉니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 관측기란 무엇인가?                        -> 1절
%    Q2. 왜 place(A', C', p)' 인가?                -> 2절
%    Q3. 추정오차는 정말 스스로 줄어드는가?        -> 3절
%    Q4. 관측기 극을 얼마나 빠르게 잡는가?         -> 4절
%    Q5. 빠르면 무조건 좋은가?                     -> 5절
%
%  돌리면 나오는 것
%    표 3개 + 그림 4장
%    걸리는 시간 : 약 8 초
%
%  대응하는 강의노트 : W14_LectureNote.mlx
%  대응하는 Simulink : W14_ObserverBased.slx
%
%  제어시스템설계 14주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 관측기란 무엇인가
%
%  아이디어는 놀랄 만큼 단순합니다.
%
%    **같은 모델을 컴퓨터 안에서 함께 돌린다.**
%
%  실제 플랜트가
%      x' = A x + B u,      y = C x
%  라면, 컴퓨터 안에서도 똑같이
%      xhat' = A xhat + B u
%  를 돌립니다. 입력 u 는 우리가 만든 것이니 당연히 압니다.
%
%  그런데 이것만으로는 안 됩니다. 초기값이 다르면 영영 어긋난 채로 갑니다.
%  모델이 조금만 틀려도 마찬가지입니다. **이것을 열린 관측기라고 합니다.**
%
%  그래서 한 항을 더합니다.
%
%      xhat' = A xhat + B u + L (y - C xhat)
%                             ^^^^^^^^^^^^^^
%                             실제로 잰 것과 내가 예상한 것의 차이
%
%  차이가 나면 그만큼 추정을 고칩니다. **오차를 보고 고친다** — 피드백입니다.
%  지금까지 열세 주 동안 해 온 것과 정확히 같은 발상입니다.

[Gp, p] = plant_dcmotor('position');
A = p.A;  B = p.B;  C = p.C;  D = p.D;
n = size(A,1);

fprintf('=== 1. 오늘의 플랜트 ===\n');
fprintf('  DC 모터 위치제어, 상태 %d 개\n', n);
fprintf('    x1 = 각도, x2 = 각속도, x3 = 전류\n');
fprintf('  C = %s  ->  **각도만 잰다**\n', mat2str(C));
fprintf('  rank(obsv) = %d / %d  ->  가관측. 관측기를 만들 수 있습니다\n\n', ...
        rank(obsv(A,C)), n);

%% 2. 왜 place(A', C', p)' 인가 — 전치 트릭
%
%  추정오차를 e = x - xhat 로 두고 두 식을 빼면
%
%      e' = (A x + B u) - (A xhat + B u + L(Cx - C xhat))
%         = A e - L C e
%         = (A - L C) e
%
%  **입력 u 가 사라졌습니다.** 무슨 입력을 넣든 추정오차는 스스로 줄어듭니다.
%  단, A - L*C 의 고유값이 전부 좌반면에 있어야 합니다.
%
%  그럼 L 을 어떻게 구할까요? 13주차의 place 는 A - B*K 를 다뤘는데
%  지금은 A - L*C 라 모양이 다릅니다. 그런데
%
%      eig(A - LC) = eig( (A - LC)' ) = eig( A' - C' L' )
%
%  전치해도 고유값은 안 변합니다. 그러면 A' 를 A 로, C' 를 B 로,
%  L' 를 K 로 놓으면 **13주차와 똑같은 문제**가 됩니다.
%
%      L = place(A', C', p_obs)'
%
%  전치를 두 번 하는 것이 전부입니다. 이것을 **쌍대성**이라고 부릅니다.

p_obs = [-30 -34 -38];
L = place(A', C', p_obs)';

fprintf('=== 2. 관측기 이득 L ===\n');
fprintf('  원하는 관측기 극점 : %s\n', mat2str(p_obs));
fprintf('  L = %s   (열벡터입니다)\n', mat2str(round(L.', 3)));
fprintf('  검증 eig(A - L*C) = %s\n\n', mat2str(round(sort(eig(A-L*C)).', 3)));

% obsv_design 이 같은 일을 하고 정보도 함께 줍니다
[L2, info_o] = obsv_design(ss(A,B,C,D), p_obs);
fprintf('  obsv_design 으로 구한 것과 차이 : %.2e\n', max(abs(L - L2)));
fprintf('  (obsv_design 은 가관측성 확인과 수렴 시간까지 함께 돌려줍니다)\n\n');

%% 3. 추정오차는 정말 스스로 줄어드는가
%
%  실제 플랜트는 초기값이 있고, 관측기는 **아무것도 모르니 0 에서 출발**합니다.
%  그런데도 따라잡는지 봅니다.

t   = (0:0.001:0.6)';
u   = ones(size(t));               % 아무 입력이나 넣어 본다
x0  = [0.5; 0; 0];                 % 실제 플랜트의 초기 상태
xh0 = [0; 0; 0];                   % 관측기는 아무것도 모른다

% 실제와 추정을 한 시스템으로 묶어 돌린다
Aa = [A,        zeros(n);
      L*C,      A - L*C];
Ba = [B; B];
sys_aug = ss(Aa, Ba, eye(2*n), zeros(2*n,1));
[~, ~, Xa] = lsim(sys_aug, u, t, [x0; xh0]);
X  = Xa(:, 1:n);
Xh = Xa(:, n+1:end);

fprintf('=== 3. 추정오차의 수렴 ===\n');
fprintf('  관측기는 x(0) 를 모르므로 0 에서 출발합니다.\n');
fprintf('  각도는 처음부터 0.5 만큼 틀렸고, 나머지 둘은 각도를 따라잡는\n');
fprintf('  과정에서 **일시적으로** 크게 벗어났다가 돌아옵니다.\n\n');
nm = {'각도 (잴 수 있다)', '각속도 (못 잰다)', '전류 (못 잰다)'};
fprintf('  %-22s  최대 오차   2 %% 이내 도달[s]\n', '상태');
fprintf('  %-22s  ---------   ---------------\n', '----');
for i = 1:n
    e  = X(:,i) - Xh(:,i);
    em = max(abs(e));
    k  = find(flipud(abs(e)) > 0.02*em, 1, 'first');
    if isempty(k), tk = 0; else, tk = t(end - k + 1); end
    fprintf('  %-22s  %9.3f   %15.3f\n', nm{i}, em, tk);
end
fprintf('\n');

figure('Name', '관측기의 수렴');
tiledlayout(2, 2, 'TileSpacing', 'compact');
for i = 1:2
    nexttile
    plot(t, X(:,i), 'LineWidth', 2.6); hold on; grid on;
    plot(t, Xh(:,i), '--', 'LineWidth', 2.4);
    xlabel('시간 [s]'); ylabel(nm{i});
    legend('실제', '관측기의 추정', 'Location', 'best');
    title(sprintf('%s : 관측기는 0 에서 출발한다', nm{i}));
end
for i = 1:2
    nexttile
    plot(t, X(:,i) - Xh(:,i), 'LineWidth', 2.4, 'Color', [0.85 0.2 0.15]);
    grid on; yline(0, 'k--');
    xlabel('시간 [s]'); ylabel(sprintf('e_%d = x_%d - xhat_%d', i, i, i));
    title('추정오차는 (A - LC) 의 고유값으로 스스로 줄어든다');
end

fprintf('  **각속도를 재는 센서가 없는데도 맞춰 냅니다.**\n');
fprintf('  각도를 계속 지켜보면서 그 변화를 보고 유추하는 것입니다.\n\n');

%% 4. 관측기 극을 얼마나 빠르게 잡는가
%
%  관례는 **제어기 극보다 2~5배 빠르게** 입니다. 이유는 이렇습니다.
%
%    - 너무 느리면 : 추정이 따라오기 전에 제어기가 틀린 값으로 일한다
%    - 너무 빠르면 : L 이 커져서 y 의 잡음을 그대로 증폭한다
%
%  제어기 극을 [-8 -10 -12] 로 잡았다면 관측기 극은 [-30 근처]가 적당합니다.

p_ctrl = [-8 -10 -12];
K = place(A, B, p_ctrl);

fprintf('=== 4. 관측기 극의 배수 ===\n');
fprintf('     배수    관측기 극점        |L|      오차 수렴시간[s]\n');
fprintf('   -------  --------------  ---------  ----------------\n');
mults = [1 2 3 5 10];
for m = mults
    po = p_ctrl * m;
    Lm = place(A', C', po)';
    Am = A - Lm*C;
    tm = (0:0.001:2)';
    em = initial(ss(Am, zeros(n,1), eye(n), zeros(n,1)), [0.5;0;0], tm);
    k  = find(all(abs(em) < 0.02*max(abs(em(1,:))), 2), 1, 'first');
    if isempty(k), tset = Inf; else, tset = tm(k); end
    fprintf('   %7.0f  %4.0f %4.0f %4.0f   %9.1f  %16.3f\n', ...
            m, po, norm(Lm), tset);
end
fprintf('\n');
fprintf('  배수를 키우면 빨리 수렴하지만 |L| 이 급격히 커집니다.\n');
fprintf('  |L| 이 크다는 것은 **측정값을 그만큼 세게 믿는다**는 뜻입니다.\n');
fprintf('  측정값에 잡음이 있으면 그 잡음도 그만큼 세게 들어옵니다.\n\n');

%% 5. 빠르면 무조건 좋은가 — 잡음
%
%  **오늘의 맞바꿈입니다.** 5주차부터 계속 나온 그 이야기가 여기서도 나옵니다.
%
%  측정값에 잡음을 섞고, 관측기 속도를 바꿔 가며 추정값을 봅니다.

rng(11);
t5   = (0:0.0005:0.5)';
u5   = ones(size(t5));
sig  = 3e-4;                        % 각도 센서 잡음 [rad]
noise = sig*randn(size(t5));

mults5 = [1 3 9];
col    = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13];

% 참값 (잡음 없는 플랜트)
[~, ~, Xt] = lsim(ss(A,B,eye(n),zeros(n,1)), u5, t5, [0;0;0]);

figure('Name', '관측기와 잡음');
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile
plot(t5, Xt(:,1) + noise, 'LineWidth', 0.8, 'Color', [0.6 0.6 0.6]);
hold on; grid on;
plot(t5, Xt(:,1), 'LineWidth', 2.6, 'Color', [0.85 0.2 0.15]);
xlabel('시간 [s]'); ylabel('측정 각도 [rad]');
legend('잡음이 섞인 측정값', '참값', 'Location', 'northwest');
title(sprintf('센서에는 늘 잡음이 있다 (표준편차 %.0e rad)', sig));

nexttile
hold on; grid on;
fprintf('=== 5. 관측기 속도와 잡음 ===\n');
fprintf('     배수      |L|      추정 각속도의 잡음 표준편차\n');
fprintf('   -------  ---------  ---------------------------\n');
for j = 1:numel(mults5)
    po = p_ctrl * mults5(j);
    Lm = place(A', C', po)';
    % 관측기만 따로 돌린다 : 입력은 [u ; y_meas]
    obs = ss(A - Lm*C, [B, Lm], eye(n), zeros(n,2));
    Xh5 = lsim(obs, [u5, Xt(:,1) + noise], t5, [0;0;0]);
    resid = Xh5(:,2) - Xt(:,2);
    plot(t5, Xh5(:,2), 'LineWidth', 1.8, 'Color', col(j,:), ...
         'DisplayName', sprintf('%d 배 (|L| = %.0f)', mults5(j), norm(Lm)));
    fprintf('   %7d  %9.0f  %27.2e\n', mults5(j), norm(Lm), std(resid));
end
plot(t5, Xt(:,2), 'k--', 'LineWidth', 2, 'DisplayName', '참값');
xlabel('시간 [s]'); ylabel('추정 각속도 [rad/s]');
legend('Location', 'northwest');
title('빠르게 만들수록 추정값이 잡음으로 떨린다 — 공짜가 아니다');

fprintf('\n');
fprintf('  --> 관측기를 빠르게 하면 **잡음을 그만큼 크게 증폭**합니다.\n');
fprintf('      13주차에서 "극을 왼쪽으로 보내면 제어입력이 커진다" 고 했습니다.\n');
fprintf('      오늘은 "관측기 극을 왼쪽으로 보내면 잡음이 커진다" 입니다.\n');
fprintf('      **두 대가는 서로 대칭입니다.**\n\n');

%% 6. 이번 실습의 정리
%
%  - 관측기는 **같은 모델을 컴퓨터에서 함께 돌리고, 출력 차이를 보고 고치는 것**
%  - 추정오차는 e' = (A - LC) e 를 따른다. **입력과 무관하다**
%  - L = place(A', C', p_obs)' — 전치 트릭. 13주차와 같은 문제가 된다
%  - 조건은 **가관측**. 12주차에서 확인했다
%  - 관측기 극은 제어기 극보다 **2~5배 빠르게**
%  - 빠를수록 잘 따라잡지만 **잡음을 더 크게 증폭한다.** 공짜가 아니다
%
%  다음 실습 : W14_02_separation.m 에서 분리원리를 확인합니다.

fprintf('=== 정리 ===\n');
fprintf('  관측기는 센서 없이 상태를 만들어 낸다\n');
fprintf('  전치 트릭 L = place(A'', C'', p)'' 하나만 외우면 된다\n');
fprintf('  그런데 제어기와 관측기를 같이 쓰면 어떻게 될까요? -> W14_02\n');
