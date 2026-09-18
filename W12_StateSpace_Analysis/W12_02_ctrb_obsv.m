%% W12_02_ctrb_obsv.m
%  12주차 실습 (2) : 가제어성과 가관측성 — 할 수 있는가 없는가
%
%  이 스크립트에서 답할 질문
%    Q1. 가제어성이란 무엇인가?                    -> 1절
%    Q2. 가제어가 아니면 실제로 무슨 일이 생기는가? -> 2절
%    Q3. 가관측성이란 무엇인가?                    -> 3절
%    Q4. 진자에서 무엇을 재야 하는가?              -> 4절
%    Q5. 상쇄가 일어나면 무엇이 사라지는가?        -> 5절
%
%  돌리면 나오는 것
%    표 4개 (가제어/가관측 판정, 진자 측정 선택, 상쇄 예)
%    + 그림 3장 (가제어 비교, 가관측 비교, 진자 극점)
%    걸리는 시간 : 약 5 초
%
%  왜 이것을 먼저 하는가
%    13주차에서 극배치를 합니다. 그런데 **가제어가 아니면 극배치가 불가능**합니다.
%    14주차에서 관측기를 만듭니다. **가관측이 아니면 관측기가 불가능**합니다.
%    즉 오늘 배우는 두 판정이 다음 두 주의 입장권입니다.
%
%  대응하는 강의노트 : W12_LectureNote.mlx
%  대응하는 Simulink : W12_StateSpace_Modes.slx
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
s = tf('s');

%% 1. 가제어성 — 입력으로 모든 상태를 움직일 수 있는가
%
%  정의는 이렇습니다.
%
%    어떤 초기 상태에서 출발하든, 유한한 시간 안에 원하는 상태로
%    데려갈 수 있는 입력이 존재하면 그 시스템은 **가제어**(controllable) 하다.
%
%  판정은 행렬 하나의 계수(rank)를 보면 끝납니다.
%
%    Cm = [B  AB  A^2 B  ...  A^(n-1) B]      (n x n 행렬)
%    rank(Cm) = n  이면 가제어
%
%  왜 이 행렬인가 — 직관적으로 보면
%    B      : 입력이 지금 당장 미는 방향
%    A*B    : 그 밀린 것이 다음 순간 흘러가는 방향
%    A^2*B  : 또 그다음 방향
%    ...
%  즉 **입력 하나로 만들어 낼 수 있는 방향을 전부 모은 것**입니다.
%  그 방향들이 상태공간 전체를 덮으면(rank = n) 어디든 갈 수 있습니다.

A  = [-1  0;
       0 -2];        % 두 상태가 서로 **연결되어 있지 않다** (대각 행렬)

Bg = [1; 1];         % 두 상태를 모두 민다      -> 가제어
Bb = [1; 0];         % 첫 상태만 민다           -> 가제어 아님

fprintf('=== 1. 가제어성 판정 ===\n');
fprintf('  A = %s   (대각행렬이므로 두 상태가 서로 영향을 안 준다)\n\n', mat2str(A));

for k = 1:2
    if k == 1, B = Bg; nm = 'B = [1;1]'; else, B = Bb; nm = 'B = [1;0]'; end
    Cm = ctrb(A, B);
    r  = rank(Cm);
    fprintf('  %s\n', nm);
    fprintf('    ctrb(A,B) = %s\n', mat2str(Cm));
    fprintf('    rank = %d / %d  ->  %s\n\n', r, size(A,1), ...
            local_yn(r == size(A,1), '가제어', '가제어 아님'));
end

fprintf('  왜 B = [1;0] 이 안 되는가\n');
fprintf('    A 가 대각행렬이라 x2 는 x1 과 아무 관계가 없습니다.\n');
fprintf('    그런데 입력도 x2 를 안 밉니다. 그러면 x2 를 움직일 방법이 없습니다.\n\n');

%% 2. 가제어가 아니면 실제로 어떻게 되는가
%
%  판정만 하고 넘어가면 와닿지 않습니다. 직접 돌려 봅시다.
%  두 경우에 같은 계단 입력을 넣고 상태 두 개를 모두 그립니다.

t  = (0:0.01:5)';
u  = ones(size(t));
x0 = [0; 0];

figure('Name', '가제어성 : 입력이 상태를 움직이는가');
tiledlayout(1, 2, 'TileSpacing', 'compact');

for k = 1:2
    if k == 1, B = Bg; nm = 'B = [1;1]'; else, B = Bb; nm = 'B = [1;0]'; end
    sysk = ss(A, B, eye(2), [0;0]);
    [~, ~, X] = lsim(sysk, u, t, x0);

    nexttile
    plot(t, X(:,1), 'LineWidth', 2.2); hold on; grid on;
    plot(t, X(:,2), 'LineWidth', 2.2);
    xlabel('시간 [s]'); ylabel('상태');
    ylim([-0.1 1.1]);
    r = rank(ctrb(A, B));
    title(sprintf('%s : rank = %d  ->  %s', nm, r, ...
          local_yn(r == 2, '가제어', '가제어 아님')));
    if k == 1
        legend('x_1', 'x_2', 'Location', 'southeast');
    else
        legend('x_1', 'x_2 (꿈쩍도 않는다)', 'Location', 'east');
    end
end

fprintf('=== 2. 실제 응답 ===\n');
fprintf('  오른쪽 그림에서 x2 가 0 에 붙어 있습니다.\n');
fprintf('  입력을 아무리 크게 넣어도, 아무리 오래 넣어도 마찬가지입니다.\n');
fprintf('  **13주차의 극배치는 이런 상태의 극점을 옮길 수 없습니다.**\n\n');

%% 3. 가관측성 — 출력만 보고 상태를 알아낼 수 있는가
%
%  정의는 가제어성과 짝을 이룹니다.
%
%    유한한 시간 동안 출력 y(t) 와 입력 u(t) 를 지켜본 것만으로
%    초기 상태 x(0) 를 알아낼 수 있으면 **가관측**(observable) 하다.
%
%  판정 행렬도 짝입니다.
%
%    Om = [C; CA; CA^2; ... ; CA^(n-1)]       (n x n 행렬)
%    rank(Om) = n  이면 가관측
%
%  직관
%    C      : 지금 보이는 것
%    C*A    : 그 보이는 값의 변화율에 담긴 정보
%    C*A^2  : 또 그 변화율
%  즉 **출력과 그 미분들을 다 모으면 상태를 복원할 수 있는가**를 묻는 것입니다.

Cg = [1 1];          % 두 상태가 섞여 나온다   -> 가관측
Cb = [1 0];          % 첫 상태만 보인다        -> 가관측 아님

fprintf('=== 3. 가관측성 판정 ===\n');
for k = 1:2
    if k == 1, C = Cg; nm = 'C = [1 1]'; else, C = Cb; nm = 'C = [1 0]'; end
    Om = obsv(A, C);
    r  = rank(Om);
    fprintf('  %s\n', nm);
    fprintf('    obsv(A,C) = %s\n', mat2str(Om));
    fprintf('    rank = %d / %d  ->  %s\n\n', r, size(A,1), ...
            local_yn(r == size(A,1), '가관측', '가관측 아님'));
end

% 초기조건 두 개를 서로 다르게 주고 출력이 구별되는지 본다
figure('Name', '가관측성 : 출력이 상태를 구별하는가');
tiledlayout(1, 2, 'TileSpacing', 'compact');
x0a = [1; 0];
x0b = [1; 1];

for k = 1:2
    if k == 1, C = Cg; nm = 'C = [1 1]'; else, C = Cb; nm = 'C = [1 0]'; end
    ya = initial(ss(A, Bg, C, 0), x0a, t);
    yb = initial(ss(A, Bg, C, 0), x0b, t);

    nexttile
    plot(t, ya, 'LineWidth', 2.5); hold on; grid on;
    plot(t, yb, '--', 'LineWidth', 2.5);
    xlabel('시간 [s]'); ylabel('출력 y');
    r = rank(obsv(A, C));
    title(sprintf('%s : rank = %d  ->  %s', nm, r, ...
          local_yn(r == 2, '두 상태가 구별된다', '겹친다. 구별 불가')));
    legend('x(0) = [1;0]', 'x(0) = [1;1]', 'Location', 'northeast');
end

fprintf('  오른쪽 그림에서 두 선이 완전히 겹칩니다.\n');
fprintf('  출력만 봐서는 x2 가 0 인지 1 인지 알 수가 없습니다.\n');
fprintf('  **14주차의 관측기는 이런 상태를 추정할 수 없습니다.**\n\n');

%% 4. 진자에서 — 무엇을 재야 하는가
%
%  이제 실제 플랜트로 옵니다. 12~14주차의 주인공은 **거꾸로 선 진자**입니다.
%  상태는 두 개입니다.
%
%    x1 = 각도(기울어진 정도),  x2 = 각속도
%
%  센서를 하나만 달 수 있다면 무엇을 재야 할까요?
%  각도계? 자이로(각속도계)? 둘 다 되나요?

[sysUp, pUp] = plant_pendulum(pi);      % 거꾸로 선 자세에서 선형화

fprintf('=== 4. 거꾸로 선 진자 ===\n');
fprintf('  A = %s\n', mat2str(round(pUp.A, 4)));
fprintf('  B = %s\n', mat2str(round(pUp.B, 4)));
fprintf('  고유값 = %s\n', mat2str(round(eig(pUp.A).', 4)));
fprintf('  --> 고유값 하나가 양수입니다. 개루프가 **불안정**합니다.\n\n');

fprintf('  가제어성 : rank(ctrb) = %d / 2  ->  %s\n', ...
        rank(ctrb(pUp.A, pUp.B)), ...
        local_yn(rank(ctrb(pUp.A, pUp.B)) == 2, '가제어', '가제어 아님'));
fprintf('  --> 토크 하나로 두 상태를 다 움직일 수 있습니다. 13주차 진행 가능.\n\n');

Cs = { '각도만 잰다   C = [1 0]',   [1 0]
       '각속도만 잰다 C = [0 1]',   [0 1]
       '둘 다 잰다    C = eye(2)',  eye(2) };

fprintf('  센서 선택별 가관측성\n');
fprintf('    %-28s  rank   판정\n', '측정');
fprintf('    %-28s  ----   --------\n', '----');
for k = 1:size(Cs,1)
    r = rank(obsv(pUp.A, Cs{k,2}));
    fprintf('    %-28s  %4d   %s\n', Cs{k,1}, r, ...
            local_yn(r == 2, '가관측', '가관측 아님'));
end
fprintf('\n');
fprintf('  결론 : 각도 하나만 재도 가관측입니다.\n');
fprintf('    각도를 보고 있으면 그 변화율에서 각속도를 **유추**할 수 있으니까요.\n');
fprintf('    그래서 14주차에서 각도계 하나로 관측기를 만듭니다.\n\n');

% 극점을 그림으로
figure('Name', '거꾸로 선 진자의 극점');
pl = eig(pUp.A);
plot(real(pl), imag(pl), 'x', 'MarkerSize', 18, 'LineWidth', 3.5, ...
     'Color', [0.85 0.20 0.15]); hold on; grid on;
xline(0, 'k-', 'LineWidth', 2);
yline(0, 'k:');
xlim([-8 8]); ylim([-3 3]);
xlabel('실수부'); ylabel('허수부');
title(sprintf('거꾸로 선 진자 : 극점 %s — 하나가 우반면', ...
      mat2str(round(pl.', 2))));
text(real(pl(pl>0)), 0.6, '이것 때문에 넘어진다', 'FontSize', 12, ...
     'FontWeight', 'bold', 'Color', [0.85 0.20 0.15], ...
     'HorizontalAlignment', 'center');

%% 5. 상쇄가 일어나면 무엇이 사라지는가
%
%  가제어·가관측이 깨지는 가장 흔한 원인은 **극점과 영점의 상쇄**입니다.
%  7주차에서 "불안정한 극점을 상쇄하면 절대 안 된다" 고 했던 것의 이유가
%  여기서 정확히 나옵니다.

Ac = [-1 0; 0 -2];  Bc = [1; 1];  Cc = [1 0];
sys_full = ss(Ac, Bc, Cc, 0);

fprintf('=== 5. 상쇄와 최소실현 ===\n');
fprintf('  원래 상태공간 : 상태 %d 개, 고유값 %s\n', ...
        size(Ac,1), mat2str(round(eig(Ac).', 3)));

Gc = tf(sys_full);
fprintf('  전달함수로 바꾸면\n');
Gc
fprintf('  전달함수의 극점 : %s\n', mat2str(round(pole(Gc).', 3)));
fprintf('  --> 고유값은 2 개인데 극점은 %d 개입니다.\n', numel(pole(Gc)));
fprintf('      C = [1 0] 이라 x2 가 출력에 안 나오므로 그 모드가 사라졌습니다.\n\n');

sys_min = minreal(sys_full);
fprintf('  minreal 로 줄이면 상태가 %d 개가 됩니다.\n', size(sys_min.A,1));
fprintf('  줄어든 만큼이 바로 **가제어도 가관측도 아닌 부분**입니다.\n\n');

fprintf('  실무에서 이것이 무서운 이유\n');
fprintf('    전달함수만 보면 사라진 모드가 안 보입니다.\n');
fprintf('    그 모드가 **불안정**하면, 계단응답은 멀쩡한데 실제로는 발산합니다.\n');
fprintf('    7주차에서 본 그 함정이 상태공간에서는 이렇게 설명됩니다.\n\n');

%% 6. 이번 실습의 정리
%
%  - 가제어성 : rank(ctrb(A,B)) = n.  **입력으로 모든 상태를 움직일 수 있는가**
%  - 가관측성 : rank(obsv(A,C)) = n.  **출력만 보고 모든 상태를 알아낼 수 있는가**
%  - 가제어가 아니면 13주차 극배치가 불가능하다
%  - 가관측이 아니면 14주차 관측기가 불가능하다
%  - 거꾸로 선 진자는 가제어이고, **각도 하나만 재도 가관측**이다
%  - 상쇄가 일어나면 그 모드가 전달함수에서 사라진다. 없어진 것이 아니다
%
%  다음 실습 : W12_03_run_simulink.m 에서 Simulink 로 모드를 봅니다.

fprintf('=== 정리 ===\n');
fprintf('  가제어 -> 13주차 극배치 가능\n');
fprintf('  가관측 -> 14주차 관측기 가능\n');
fprintf('  거꾸로 선 진자는 둘 다 만족합니다. 다음 두 주를 진행할 수 있습니다.\n');

% ---------------------------------------------------------------
function s = local_yn(tf_, yes, no)
if tf_, s = yes; else, s = no; end
end
