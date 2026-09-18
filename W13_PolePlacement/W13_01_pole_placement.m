%% W13_01_pole_placement.m
%  13주차 실습 (1) : 극배치 — 극점을 원하는 자리에 정확히 놓기
%
%  이 스크립트에서 답할 질문
%    Q1. 상태궤환이란 무엇인가?                  -> 1절
%    Q2. K 를 손으로 어떻게 구하는가?            -> 2절
%    Q3. place 와 acker 는 무엇이 다른가?        -> 3절
%    Q4. 근궤적과 무엇이 다른가?                 -> 4절
%    Q5. 극을 아무 데나 놓아도 되는가?           -> 5절
%
%  돌리면 나오는 것
%    표 3개 (손계산 대 place, place 대 acker, 극 위치별 대가)
%    + 그림 3장 (극점 이동, 근궤적과의 비교, 제어입력)
%    걸리는 시간 : 약 5 초
%
%  대응하는 강의노트 : W13_LectureNote.mlx
%  대응하는 Simulink : W13_PolePlacement.slx
%
%  제어시스템설계 13주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 상태궤환 — 출력이 아니라 상태를 되먹인다
%
%  지금까지 열두 주 동안 되먹인 것은 **출력 y** 하나였습니다.
%
%      u = C(s) * (r - y)
%
%  상태궤환은 **상태 전부**를 되먹입니다.
%
%      u = -K x + Kr r          K = [k1 k2 ... kn]  (행벡터)
%
%  이것을 상태방정식에 넣으면
%
%      x' = A x + B(-K x + Kr r) = (A - B K) x + B Kr r
%
%  즉 **A 가 A - B*K 로 바뀝니다.**
%  우리가 K 를 고르면 A - B*K 의 고유값을 정할 수 있다는 뜻입니다.
%
%  여기서 12주차의 조건이 나옵니다 — **가제어여야 한다.**
%  가제어가 아니면 그 모드의 고유값은 K 를 어떻게 해도 안 움직입니다.

[Gp, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);

fprintf('=== 1. 오늘의 플랜트 : DC 모터 위치제어 ===\n');
fprintf('  A = %s\n', mat2str(round(p.A, 4)));
fprintf('  B = %s\n', mat2str(round(p.B, 4)));
fprintf('  C = %s\n', mat2str(p.C));
fprintf('  개루프 고유값 : %s\n', mat2str(round(eig(p.A).', 4)));
fprintf('  --> 원점에 극점이 하나 있습니다. 적분기입니다 (5주차의 타입 1)\n\n');
fprintf('  rank(ctrb) = %d / %d  ->  가제어. 극배치를 할 수 있습니다\n\n', ...
        rank(ctrb(p.A, p.B)), size(p.A,1));

%% 2. K 를 손으로 구하기 — 계수비교법
%
%  절차는 세 줄입니다.
%
%    1) 원하는 극점으로 **원하는 특성다항식**을 만든다
%          (s+8)(s+10)(s+12) = s^3 + 30 s^2 + 296 s + 960
%
%    2) A - B*K 의 특성다항식을 K 의 원소로 적는다
%          det(sI - A + BK) = s^3 + (...)s^2 + (...)s + (...)
%
%    3) 두 다항식의 **계수를 하나씩 맞춘다**
%
%  미지수 개수(K 의 원소 n 개)와 방정식 개수(계수 n 개)가 같으므로
%  **답이 정확히 하나** 나옵니다. 이것이 극배치가 되는 이유입니다.

p_des = [-8 -10 -12];
den_des = poly(p_des);

fprintf('=== 2. 계수비교법 ===\n');
fprintf('  원하는 극점 : %s\n', mat2str(p_des));
fprintf('  원하는 특성다항식 계수 : %s\n', mat2str(round(den_des, 4)));
fprintf('  즉  s^3 + %.0f s^2 + %.0f s + %.0f = 0\n\n', den_des(2:4));

% 손으로 하는 것과 같은 계산을 기호 없이 수치로
% (A - B*K 의 특성다항식 계수가 K 에 선형이므로 선형연립방정식이 된다)
n = size(p.A, 1);
K_hand = zeros(1, n);
M = zeros(n, n);  b0 = zeros(n, 1);
c0 = poly(p.A);                       % K = 0 일 때의 계수
for j = 1:n
    e = zeros(1, n); e(j) = 1;
    cj = poly(p.A - p.B*e);
    M(:, j) = (cj(2:end) - c0(2:end)).';   % K_j 가 1 증가할 때 계수 변화
end
b0 = (den_des(2:end) - c0(2:end)).';
K_hand = (M \ b0).';

fprintf('  손계산(계수비교) K = %s\n', mat2str(round(K_hand, 4)));

K_place = place(p.A, p.B, p_des);
fprintf('  place 로 구한 K = %s\n', mat2str(round(K_place, 4)));
fprintf('  두 답의 최대 차이 : %.2e\n', max(abs(K_hand - K_place)));
fprintf('  --> 같은 답입니다. 공식이 맞다는 확인입니다.\n\n');

fprintf('  검증 : eig(A - B*K) = %s\n', ...
        mat2str(round(sort(eig(p.A - p.B*K_place)).', 4)));
fprintf('  --> 원하던 자리에 정확히 놓였습니다.\n\n');

%% 3. place 와 acker — 무엇이 다른가
%
%  두 명령 모두 같은 일을 합니다. 그런데 쓰는 자리가 다릅니다.
%
%  place(A, B, p)
%    - 수치적으로 **안정적**이다. 고차 시스템에서도 믿을 만하다
%    - 입력이 여러 개(다입력)여도 된다
%    - **중근을 허용하지 않는다.** p = [-2 -2] 는 오류
%
%  acker(A, B, p)
%    - Ackermann 공식을 그대로 쓴다. **중근도 된다**
%    - **단일입력만** 된다
%    - 차수가 높아지면 수치오차가 커진다 (10차 이상은 위험)
%
%  실무 규칙 — **기본은 place, 중근이 꼭 필요하면 acker**

fprintf('=== 3. place 와 acker ===\n');
K_ack = acker(p.A, p.B, p_des);
fprintf('  서로 다른 극점 %s\n', mat2str(p_des));
fprintf('    place : %s\n', mat2str(round(K_place, 4)));
fprintf('    acker : %s\n', mat2str(round(K_ack, 4)));
fprintf('    차이  : %.2e  (같은 답)\n\n', max(abs(K_place - K_ack)));

p_rep = [-10 -10 -10];
fprintf('  중근이 있는 극점 %s\n', mat2str(p_rep));
try
    K_p2 = place(p.A, p.B, p_rep);
    fprintf('    place : %s\n', mat2str(round(K_p2, 4)));
catch ME
    fprintf('    place : 오류! -> %s\n', ME.message);
end
K_a2 = acker(p.A, p.B, p_rep);
fprintf('    acker : %s\n', mat2str(round(K_a2, 4)));
fprintf('    검증  : eig = %s\n', mat2str(round(sort(eig(p.A - p.B*K_a2)).', 3)));
fprintf('  --> 중근이 필요하면 acker 를 쓰십시오.\n\n');

%% 4. 근궤적과 무엇이 다른가 — 오늘의 핵심
%
%  6~7주차에서는 이득 K 하나를 바꿨습니다. 그러면 극점이 **정해진 길**
%  위를 움직였고, 그 길이 원하는 자리를 안 지나면 방법이 없었습니다.
%
%  상태궤환은 다릅니다. K 가 **벡터**이므로 자유도가 상태 개수만큼 있습니다.
%  그래서 극점 n 개를 **각각 원하는 자리에 정확히** 놓을 수 있습니다.
%
%  아래 그림에서 근궤적(길)과 극배치로 간 자리를 겹쳐 봅니다.

figure('Name', '근궤적 대 극배치');
hold on; grid on;

% 비례제어의 근궤적
Kv = linspace(0, 400, 3000);
[num, den] = tfdata(Gp, 'v');
pad = [zeros(1, numel(den)-numel(num)) num];
R = zeros(numel(den)-1, numel(Kv));
for j = 1:numel(Kv), R(:,j) = roots(den + Kv(j)*pad); end
for r = 1:size(R,1)
    h = plot(real(R(r,:)), imag(R(r,:)), '-', 'LineWidth', 2, ...
             'Color', [0.60 0.60 0.60]);
    if r == 1, set(h,'DisplayName','비례제어의 근궤적 (갈 수 있는 길)');
    else,      set(h,'HandleVisibility','off'); end
end
plot(real(eig(p.A)), imag(eig(p.A)), 'x', 'MarkerSize', 15, 'LineWidth', 3, ...
     'Color', [0.00 0.45 0.74], 'DisplayName', '개루프 극점');
plot(p_des, zeros(size(p_des)), 'o', 'MarkerSize', 13, 'LineWidth', 3, ...
     'Color', [0.85 0.20 0.15], 'DisplayName', '상태궤환으로 놓은 자리');
xline(0, 'k-', 'LineWidth', 1.6, 'HandleVisibility','off');
yline(0, 'k:', 'HandleVisibility','off');
xlim([-16 4]); ylim([-8 8]);
xlabel('실수부'); ylabel('허수부');
legend('Location','northwest');
title('회색 길 위가 아니어도 갈 수 있다 — 이것이 극배치');

fprintf('=== 4. 근궤적과의 차이 ===\n');
fprintf('  비례제어 : 극점이 회색 길 위에서만 움직인다. 자유도 1 개\n');
fprintf('  상태궤환 : 극점 %d 개를 각각 정할 수 있다. 자유도 %d 개\n', n, n);
fprintf('  --> 원하는 자리가 길 위에 없어도 됩니다.\n\n');

%% 5. 극을 아무 데나 놓아도 되는가 — 대가
%
%  수학적으로는 **어디든** 놓을 수 있습니다. 가제어이기만 하면요.
%  그런데 물리적으로는 대가가 있습니다.
%
%  극을 왼쪽으로 보낼수록
%    - 응답이 빨라진다                    <- 좋다
%    - K 가 커진다                        <- 그래서
%    - **제어입력이 커진다**              <- 구동기가 못 낸다
%
%  6주차의 포화, 7주차의 Lead 대가와 **정확히 같은 이야기**입니다.

a_list = 4:4:24;
t = (0:0.002:2)';
fprintf('=== 5. 극을 왼쪽으로 보낼수록 ===\n');
fprintf('     극점 위치         |K|      정착시간[s]   최대 제어입력[V]\n');
fprintf('   ---------------  --------  ------------  ------------------\n');
UM = zeros(size(a_list));  TS = zeros(size(a_list));
for i = 1:numel(a_list)
    a = a_list(i);
    [K, ~, info] = fsfb_design(sys, [-a -a-2 -a-4], t);
    UM(i) = info.umax;  TS(i) = info.ts;
    fprintf('   %4.0f %4.0f %4.0f     %8.1f  %12.3f  %18.1f\n', ...
            -a, -a-2, -a-4, norm(K), info.ts, info.umax);
end
fprintf('\n');

figure('Name', '극배치의 대가');
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
plot(a_list, TS, 'o-', 'LineWidth', 2.4, 'MarkerSize', 8); grid on;
xlabel('가장 오른쪽 극점의 |실수부|'); ylabel('정착시간 [s]');
title('왼쪽으로 보낼수록 빨라진다');

nexttile
semilogy(a_list, UM, 'o-', 'LineWidth', 2.4, 'MarkerSize', 8, ...
         'Color', [0.85 0.20 0.15]); grid on;
yline(24, 'k--', 'LineWidth', 1.8);
text(a_list(2), 30, '24 V 드라이버 한계', 'FontSize', 11, 'FontWeight','bold');
xlabel('가장 오른쪽 극점의 |실수부|'); ylabel('최대 제어입력 [V]  (로그)');
title('그런데 제어입력이 폭증한다');

fprintf('  극점 위치를 %d 에서 %d 로 옮기면\n', a_list(1), a_list(end));
fprintf('    정착시간   %.3f -> %.3f s  (%.1f 배 빨라짐)\n', ...
        TS(1), TS(end), TS(1)/TS(end));
fprintf('    제어입력   %.1f -> %.1f V   (%.1f 배 커짐)\n', ...
        UM(1), UM(end), UM(end)/UM(1));
fprintf('  --> **빨라지는 것보다 제어입력이 훨씬 빨리 커집니다.**\n');
fprintf('      정착시간은 %.1f 배 좋아졌는데 전압은 %.0f 배 들었습니다.\n', ...
        TS(1)/TS(end), UM(end)/UM(1));
ok24 = find(UM <= 24, 1, 'last');
if isempty(ok24)
    fprintf('      24 V 드라이버로는 이 표의 **어느 것도 못 씁니다.**\n');
    fprintf('      가장 느린 %s 조차 %.0f V 를 요구합니다.\n', ...
            mat2str([-a_list(1) -a_list(1)-2 -a_list(1)-4]), UM(1));
    fprintf('      극을 더 원점 가까이 잡거나, 지령을 계단이 아니라\n');
    fprintf('      **완만한 곡선으로 바꿔 주어야** 합니다.\n\n');
else
    fprintf('      24 V 드라이버라면 %d 근처까지가 한계입니다.\n\n', a_list(ok24));
end

%% 6. 이번 실습의 정리
%
%  - 상태궤환 u = -Kx 는 A 를 A - B*K 로 바꾼다
%  - K 는 계수비교법으로 손계산할 수 있고, place / acker 가 대신 해 준다
%  - place 는 중근 불가, acker 는 단일입력만. **기본은 place**
%  - 근궤적과 달리 극점을 **정해진 길 밖에도** 놓을 수 있다
%  - 단, 가제어여야 한다 (12주차)
%  - **극을 왼쪽으로 보낼수록 제어입력이 폭증한다.** 공짜가 아니다
%
%  다음 실습 : W13_02_reference_tracking.m 에서 정상상태 오차를 다룹니다.

fprintf('=== 정리 ===\n');
fprintf('  극배치는 극점을 원하는 자리에 정확히 놓는다\n');
fprintf('  조건은 가제어. 대가는 제어입력\n');
fprintf('  그런데 아직 문제가 하나 남았습니다 -> W13_02 로\n');
