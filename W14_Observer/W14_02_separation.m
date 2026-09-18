%% W14_02_separation.m
%  14주차 실습 (2) : 분리원리 — 따로 설계해도 된다
%
%  13주차에서 제어기 K 를, 오늘 앞에서 관측기 L 을 만들었습니다.
%  그럼 둘을 합치면 어떻게 될까요?
%
%    u = -K * xhat        (진짜 x 가 아니라 추정값을 쓴다)
%
%  추정이 틀린 동안에는 제어도 틀립니다. 서로 영향을 주고받을 것 같습니다.
%  그런데 **놀랍게도 서로 간섭하지 않습니다.** 오늘의 하이라이트입니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 확대 시스템의 고유값은 무엇인가?          -> 2절
%    Q2. 왜 분리되는가?                            -> 3절
%    Q3. 관측기 기반 제어기는 무엇과 닮았는가?     -> 4절
%    Q4. 진짜 상태를 쓴 것과 얼마나 다른가?        -> 5절
%
%  돌리면 나오는 것
%    표 3개 + 그림 3장
%    걸리는 시간 : 약 5 초
%
%  대응하는 강의노트 : W14_LectureNote.mlx
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

[Gp, p] = plant_dcmotor('position');
A = p.A;  B = p.B;  C = p.C;  D = p.D;
n = size(A,1);

p_ctrl = [-8 -10 -12];
p_obs  = [-30 -34 -38];
K = place(A, B, p_ctrl);
L = place(A', C', p_obs)';

%% 1. 관측기 기반 제어기
%
%  구성은 이렇습니다.
%
%    관측기 :  xhat' = A xhat + B u + L (y - C xhat)
%    제어기 :  u     = -K xhat + Kr r
%
%  진짜 상태 x 는 아무 데도 안 나옵니다. **우리가 아는 것은 y 와 u 뿐입니다.**
%  그것만으로 제어를 합니다.

fprintf('=== 1. 구성 ===\n');
fprintf('  제어기 극 : %s   ->  K = %s\n', mat2str(p_ctrl), mat2str(round(K,2)));
fprintf('  관측기 극 : %s   ->  L = %s\n\n', mat2str(p_obs), mat2str(round(L.',1)));

%% 2. 확대 시스템의 고유값
%
%  상태를 [x ; xhat] 로 묶으면 전체가 2n 차 시스템이 됩니다.
%  그 고유값이 무엇인지가 오늘의 질문입니다.

Aaug = [A,      -B*K;
        L*C,    A - B*K - L*C];

eig_aug  = sort(eig(Aaug));
eig_ctrl = sort(eig(A - B*K));
eig_obs  = sort(eig(A - L*C));

fprintf('=== 2. 확대 시스템의 고유값 ===\n');
fprintf('  전체 (2n = %d 개) : %s\n', 2*n, mat2str(round(eig_aug.', 3)));
fprintf('  eig(A - B*K)      : %s\n', mat2str(round(eig_ctrl.', 3)));
fprintf('  eig(A - L*C)      : %s\n', mat2str(round(eig_obs.', 3)));
fprintf('  두 목록을 합친 것과의 차이 : %.2e\n\n', ...
        max(abs(eig_aug - sort([eig_ctrl; eig_obs]))));

fprintf('  **정확히 겹칩니다.** 이것이 분리원리입니다.\n');
fprintf('    제어기 극은 K 가 정하고, 관측기 극은 L 이 정합니다.\n');
fprintf('    서로 아무 영향을 안 줍니다. **따로 설계해도 됩니다.**\n\n');

figure('Name', '분리원리');
plot(real(eig_aug), imag(eig_aug), 'o', 'MarkerSize', 15, 'LineWidth', 2.5);
hold on; grid on;
plot(real(eig_ctrl), imag(eig_ctrl), 'x', 'MarkerSize', 12, 'LineWidth', 3);
plot(real(eig_obs), imag(eig_obs), '+', 'MarkerSize', 14, 'LineWidth', 3);
xline(0, 'k-'); yline(0, 'k:');
xlabel('실수부'); ylabel('허수부'); ylim([-2 2]);
legend('확대 시스템 전체의 고유값', 'eig(A - BK) 제어기가 정한 것', ...
       'eig(A - LC) 관측기가 정한 것', 'Location', 'northwest');
title('분리원리 — 정확히 겹친다. 따로 설계해도 된다');

%% 3. 왜 분리되는가 — 좌표를 바꿔 보면
%
%  증명은 좌표변환 한 번이면 끝납니다.
%  상태를 [x ; xhat] 대신 **[x ; e]** 로 잡습니다. 여기서 e = x - xhat 입니다.
%
%    x'  = A x + B u = A x - B K xhat = A x - B K (x - e) = (A - BK) x + B K e
%    e'  = (A - LC) e                      <- 앞 실습에서 유도했습니다
%
%  행렬로 쓰면
%
%      [x]'   [ A-BK    BK  ] [x]
%      [e]  = [  0    A-LC  ] [e]
%
%  **왼쪽 아래가 0 입니다.** 이런 행렬을 블록 상삼각이라 하고,
%  그 고유값은 **대각 블록의 고유값을 합친 것**입니다.
%
%  물리적으로 읽으면 이렇습니다.
%
%    - 추정오차 e 는 제어와 무관하게 스스로 줄어든다 (아랫줄에 x 가 없다)
%    - 그 e 가 위로 새어 들어가 x 를 흔들지만, e 가 죽으면 그 영향도 사라진다
%
%  즉 **오차는 제어를 신경 안 쓰고, 제어는 오차가 죽기를 기다리면 됩니다.**

T = [eye(n), zeros(n); eye(n), -eye(n)];    % [x; xhat] -> [x; e]
Abar = T * Aaug / T;

fprintf('=== 3. 좌표를 바꾸면 ===\n');
fprintf('  [x; e] 좌표에서의 A :\n');
disp(round(Abar, 3));
fprintf('  왼쪽 아래 %dx%d 블록의 최대 절대값 : %.2e  (0 이어야 한다)\n', ...
        n, n, max(max(abs(Abar(n+1:end, 1:n)))));
fprintf('  --> 블록 상삼각. 고유값이 대각 블록으로 쪼개집니다.\n\n');

%% 4. 관측기 기반 제어기는 무엇과 닮았는가
%
%  관측기와 제어기를 합치면 결국 **y 를 받아 u 를 내놓는 전달함수 하나**입니다.
%  그것을 뽑아 보면 재미있는 사실이 나옵니다.

Dc = ss(A - B*K - L*C, L, -K, 0);          % y -> u
fprintf('=== 4. 관측기 기반 제어기의 정체 ===\n');
fprintf('  차수 : %d (플랜트와 같다)\n', order(Dc));
Gd = zpk(minreal(tf(Dc)));
fprintf('  극점 : %s\n', mat2str(round(pole(Gd).', 2)));
fprintf('  영점 : %s\n\n', mat2str(round(zero(Gd).', 2)));

w = logspace(-1, 4, 400);
[m_, ph_] = bode(-Dc, w);
m_ = squeeze(m_);  ph_ = squeeze(ph_);

figure('Name', '관측기 기반 제어기의 주파수응답');
tiledlayout(2, 1, 'TileSpacing', 'compact');
nexttile
semilogx(w, 20*log10(m_), 'LineWidth', 2.4); grid on;
ylabel('크기 [dB]');
title('관측기 기반 제어기 D(s) — Lead 보상기와 닮았다');
nexttile
semilogx(w, ph_, 'LineWidth', 2.4); grid on;
yline(0, 'k--');
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');

fprintf('  위상 곡선을 보십시오. **중간 주파수에서 위상을 올립니다.**\n');
fprintf('  7주차와 11주차의 Lead 보상기가 하던 그 일입니다.\n');
fprintf('  즉 상태공간으로 설계했지만 결과물은 **우리가 아는 그 물건**입니다.\n');
fprintf('  10강 slide 75~77 의 결론이 이것입니다.\n\n');

%% 5. 진짜 상태를 쓴 것과 얼마나 다른가
%
%  가장 실용적인 질문입니다.
%  진짜 x 를 쓸 수 있었다면 얼마나 좋았을까요? 직접 비교합니다.

t   = (0:0.001:1.5)';
Kr  = 1/dcgain(ss(A - B*K, B, C, D));
r   = ones(size(t));

% (a) 진짜 상태를 쓴 경우
y_true = lsim(ss(A - B*K, B*Kr, C, D), r, t);

% (b) 관측기를 쓴 경우 (관측기는 0 에서 출발)
Baug   = [B*Kr; B*Kr];
sysobs = ss(Aaug, Baug, [C, zeros(1,n)], 0);
y_obs  = lsim(sysobs, r, t, zeros(2*n,1));

% (c) 관측기를 쓰고 플랜트에 초기값이 있는 경우 (관측기는 그것을 모른다)
y_obs2 = lsim(sysobs, r, t, [0.3; 0; 0; 0; 0; 0]);

fprintf('=== 5. 진짜 상태 대 추정 상태 ===\n');
fprintf('  (a) 진짜 x 사용, x(0)=0          : 정착 %.3f s\n', ...
        getfield(stepinfo(y_true, t, 1), 'SettlingTime'));
fprintf('  (b) 추정 xhat 사용, x(0)=0       : 정착 %.3f s\n', ...
        getfield(stepinfo(y_obs, t, 1), 'SettlingTime'));
fprintf('  (c) 추정 xhat 사용, x(0)=0.3     : 정착 %.3f s\n', ...
        getfield(stepinfo(y_obs2, t, 1), 'SettlingTime'));
fprintf('  (a) 와 (b) 의 최대 차이 : %.2e\n\n', max(abs(y_true - y_obs)));

figure('Name', '진짜 상태 대 추정 상태');
plot(t, y_true, 'LineWidth', 3); hold on; grid on;
plot(t, y_obs, '--', 'LineWidth', 2.2);
plot(t, y_obs2, ':', 'LineWidth', 2.6);
yline(1, 'k--');
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('진짜 x 사용', '추정 xhat 사용 (x(0)=0)', ...
       '추정 xhat 사용 (x(0)=0.3, 관측기는 모름)', '목표', ...
       'Location', 'southeast');
title('초기값이 맞으면 완전히 같고, 틀리면 잠깐 다르다가 따라잡는다');

fprintf('  읽는 법\n');
fprintf('    (a) 와 (b) 가 **완전히 겹칩니다.** 둘 다 x(0)=0 이라 오차가 없기 때문입니다.\n');
fprintf('    (c) 는 처음에 다릅니다. 관측기가 0.3 을 모르니까요.\n');
fprintf('    그런데 관측기 극이 빨라서 금방 따라잡고, 그 뒤로는 (a) 와 같습니다.\n');
fprintf('    **이것이 분리원리가 실무에서 뜻하는 것입니다.**\n\n');

%% 6. 이번 실습의 정리
%
%  - 관측기 기반 제어기 : u = -K*xhat. 진짜 x 는 안 쓴다
%  - 확대 시스템의 고유값 = eig(A-BK) 와 eig(A-LC) 를 **합친 것**
%  - 증명은 [x; e] 좌표로 바꾸면 블록 상삼각이 되는 것으로 끝
%  - 그래서 **제어기와 관측기를 따로 설계해도 된다** (분리원리)
%  - 합쳐 놓고 보면 결국 **Lead 보상기와 닮은 물건**이다
%  - 초기 추정이 틀려도 관측기가 빨리 따라잡으면 실용상 문제없다
%
%  다음 실습 : W14_03_run_simulink.m 에서 실제와 추정을 나란히 봅니다.

fprintf('=== 정리 ===\n');
fprintf('  분리원리 덕분에 13주차와 14주차를 **따로** 배울 수 있었습니다\n');
fprintf('  이것이 없었다면 K 와 L 을 동시에 풀어야 했을 것입니다\n');
