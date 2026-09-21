%% W02_04_ss_tf_conversion.m
%  2주차 실습 (4) : 상태공간과 전달함수 사이를 오가기 — ss2tf, tf2ss
%
%  W02_02 의 7절과 W02_03 에서 우리는 같은 질량-스프링-댐퍼(MSD)를
%  전달함수와 상태공간 두 가지로 적었습니다. 이번 실습에서는 두 표현을
%  서로 **바꾸는** 명령 두 개를 다룹니다.
%
%      ss2tf : 상태공간 (A,B,C,D)  ->  전달함수 (분자, 분모)
%      tf2ss : 전달함수 (분자, 분모) ->  상태공간 (A,B,C,D)
%
%  이 스크립트에서 답할 질문
%    Q1. ss2tf 는 무엇을 계산하는가? 손으로도 같은 답이 나오는가?  -> 2절
%    Q2. 출력 C 를 바꾸면 전달함수의 무엇이 바뀌는가?              -> 3절
%    Q3. tf2ss 가 돌려주는 상태는 위치·속도인가?                    -> 4절
%    Q4. 상태공간 표현은 하나뿐인가?                                -> 5절
%    Q5. 왕복(ss -> tf -> ss)하면 원래 행렬로 돌아오는가?           -> 6절
%    Q6. 변환한 모델에 초기조건을 줄 때 무엇을 조심해야 하는가?     -> 7절
%
%  돌리면 나오는 것
%    명령창 표 6개 (손계산 대 ss2tf, 출력별 전달함수, 행렬 비교, 왕복 결과 등)
%    그림 2장 (세 실현의 출력·상태 비교, 초기조건 좌표 변환)
%    걸리는 시간 : 약 3 초
%
%  대응하는 강의노트 : W02_LectureNote.mlx 의 12-3절 (`tf(sys)`, `ss(G)`)
%  이어지는 내용     : W03_02_state_space.m 의 4절
%
%  제어시스템설계 2주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 출발점 : MSD 의 두 가지 표현
%
%  W02_02 에서 유도한 두 표현을 다시 적습니다.
%
%  (1) 전달함수 (초기조건 0, 라플라스 변환)
%
%          X(s)          1
%          ----  =  -------------
%          F(s)     m s^2 + b s + k
%
%  (2) 상태공간 (상태 x1 = 위치 x, x2 = 속도 x')
%
%          x1' = x2
%          x2' = -(k/m) x1 - (b/m) x2 + (1/m) F
%          y   = x1
%
%      행렬로 묶으면
%
%          A = [  0     1  ]    B = [  0  ]    C = [1 0]    D = 0
%              [ -k/m  -b/m ]        [ 1/m ]
%
%  두 표현 모두 같은 미분방정식 m x'' + b x' + k x = F 에서 나왔습니다.
%  그렇다면 한쪽에서 다른 쪽을 계산으로 얻을 수 있어야 합니다.

[G, p] = plant_msd();            % 기본값 m = 1, b = 0.2, k = 1
m = p.m;   b = p.b;   k = p.k;
A = p.A;   B = p.B;   C = p.C;   D = p.D;

fprintf('=== 1. 출발점 (m = %.1f, b = %.1f, k = %.1f) ===\n', m, b, k);
fprintf('  전달함수 분모 계수 [m b k] = %s\n', mat2str([m b k]));
fprintf('  상태공간 A = %s,  B = %s,  C = %s,  D = %g\n\n', ...
        mat2str(A), mat2str(B), mat2str(C), D);

%% 2. ss2tf — 상태공간에서 전달함수로
%
%  원리
%    상태공간 식을 초기조건 0 으로 라플라스 변환하면
%
%        s X(s) = A X(s) + B U(s)      ->   (sI - A) X(s) = B U(s)
%        Y(s)   = C X(s) + D U(s)
%
%    첫 식에서 X(s) = (sI - A)^-1 B U(s) 이므로 둘째 식에 넣으면
%
%        G(s) = Y(s)/U(s) = C (sI - A)^-1 B + D
%
%    ss2tf 는 바로 이 식을 계산해 분자·분모 계수로 돌려줍니다.
%
%  손으로 한 번 풀어 봅니다 (MSD, 2x2 이므로 손으로 충분합니다)
%
%    1단계  sI - A = [ s      -1      ]
%                    [ k/m   s + b/m  ]
%
%    2단계  det(sI - A) = s(s + b/m) + k/m = s^2 + (b/m)s + k/m
%           --> 이것이 곧 분모(특성다항식)입니다. 극점은 A 의 고유값입니다.
%
%    3단계  2x2 역행렬 공식  [a b; c d]^-1 = [d -b; -c a] / (ad - bc)
%           (sI - A)^-1 = [ s + b/m   1 ] / det(sI - A)
%                         [  -k/m     s ]
%
%    4단계  (sI - A)^-1 B  = [ 1/m ; s/m ] / det(sI - A)
%
%    5단계  C = [1 0] 은 첫째 줄만 고릅니다.
%           G(s) = (1/m) / (s^2 + (b/m)s + k/m) = 1 / (m s^2 + b s + k)
%
%  명령 정리
%    입력  : [num, den] = ss2tf(A, B, C, D)
%            입력이 여러 개면 [num, den] = ss2tf(A, B, C, D, iu) 로 iu 번째 입력을 고릅니다
%    출력  : num, den — s 의 높은 차수부터 나열한 계수 벡터 (tf(num, den) 에 그대로 넣을 수 있음)
%    주의  : (1) 분모는 항상 최고차 계수가 1 로 정규화됩니다 (m 으로 나눈 모양)
%            (2) num 은 den 과 길이를 맞추려고 앞에 0 이 붙어 나옵니다
%            (3) 객체로 다룰 때는 tf(sys) 가 같은 일을 합니다 (강의노트 12-3절)

[num, den] = ss2tf(A, B, C, D);

num_hand = [0 0 1/m];                 % 손계산 결과 (5단계)
den_hand = [1 b/m k/m];

fprintf('=== 2. ss2tf 결과와 손계산 비교 ===\n');
fprintf('  %-10s %-24s %-24s\n', '', '분자 num', '분모 den');
fprintf('  %-10s %-24s %-24s\n', 'ss2tf', mat2str(num, 4), mat2str(den, 4));
fprintf('  %-10s %-24s %-24s\n', '손계산', mat2str(num_hand, 4), mat2str(den_hand, 4));
fprintf('  최대 차이 : 분자 %.1e,  분모 %.1e\n', ...
        max(abs(num - num_hand)), max(abs(den - den_hand)));

G_from_ss = tf(num, den);
fprintf('  원래 G(s) 의 극점     : %s\n', mat2str(sort(pole(G)).', 4));
fprintf('  A 의 고유값           : %s\n', mat2str(sort(eig(A)).', 4));
fprintf('  --> 전달함수의 극점 = A 의 고유값. 2단계의 det(sI - A) 가 그 이유입니다.\n\n');

%% 3. 출력 C 를 바꾸면 무엇이 바뀌는가
%
%  같은 물체라도 "무엇을 재느냐" 에 따라 전달함수가 달라집니다.
%    C = [1 0]  : 위치를 잰다
%    C = [0 1]  : 속도를 잰다  (속도계)
%
%  2절 4단계의 벡터 [1/m ; s/m] 에서 둘째 줄을 고르면 되므로
%
%        V(s)/F(s) = (s/m) / (s^2 + (b/m)s + k/m)
%
%  읽는 법
%    분모 : det(sI - A) 이므로 C 와 무관합니다. 극점은 그대로입니다.
%    분자 : C 가 고르는 줄이 바뀌므로 달라집니다. s = 0 에 영점이 생깁니다.
%           (속도 = 위치의 미분 = 위치 전달함수에 s 를 곱한 것)

[num_v, den_v] = ss2tf(A, B, [0 1], 0);
G_v = tf(num_v, den_v);

fprintf('=== 3. 출력 행렬에 따른 전달함수 ===\n');
fprintf('  %-14s %-20s %-22s %-18s\n', '출력 C', '분자', '분모', '영점');
fprintf('  %-14s %-20s %-22s %-18s\n', '[1 0] 위치', mat2str(num, 4), mat2str(den, 4), '없음');
fprintf('  %-14s %-20s %-22s %-18s\n', '[0 1] 속도', mat2str(num_v, 4), mat2str(den_v, 4), ...
        mat2str(zero(G_v).', 4));
fprintf('  위치 전달함수 x s 와 속도 전달함수의 최대 계수 차이 : %.1e\n', ...
        max(abs(cell2mat(tfdata(minreal(G*s))) - cell2mat(tfdata(minreal(G_v))))));
fprintf('  --> 분모(극점)는 A 가, 분자(영점)는 C 와 B 가 정합니다.\n\n');

%% 4. tf2ss — 전달함수에서 상태공간으로
%
%  원리
%    전달함수에는 "내부 상태가 무엇인가" 에 대한 정보가 없습니다.
%    그래서 tf2ss 는 분모·분자 계수만 보고 정해진 규칙으로 행렬을 채웁니다.
%    이 규칙을 제어기 표준형(controllable canonical form) 이라고 합니다.
%
%    분모를 s^2 + a1 s + a0, 분자를 b0 로 쓰면 (MSD 에서 a1 = b/m, a0 = k/m, b0 = 1/m)
%
%        A = [ -a1  -a0 ]    B = [1]    C = [0  b0]    D = 0
%            [  1    0  ]        [0]
%
%    즉 분모 계수를 부호만 바꿔 A 의 첫 줄에 그대로 옮겨 적습니다.
%
%  이 상태는 무엇인가?
%    보조 변수 z 를  z'' + a1 z' + a0 z = F  로 정의하면
%        상태 = [z' ; z],   출력 y = b0 z = z/m
%    따라서 z = m x 이고
%        z1 = z' = m * (속도),   z2 = z = m * (위치)
%    --> **위치·속도와 순서가 뒤바뀌고 m 배만큼 척도가 바뀐** 상태입니다.
%        물리적 의미가 있는 상태를 원하면 1절처럼 직접 골라야 합니다.
%
%  명령 정리
%    입력  : [Ac, Bc, Cc, Dc] = tf2ss(num, den)
%    출력  : 제어기 표준형 행렬 네 개
%    주의  : (1) 입력 하나짜리(SISO/SIMO) 전용입니다
%            (2) 결과 상태는 물리량이 아닙니다 (위 설명)
%            (3) 객체로 다룰 때의 ss(G) 는 결과 행렬이 tf2ss 와 다를 수 있습니다
%                (MATLAB 이 수치 안정성을 위해 척도를 조정합니다. 5절에서 비교)

[Ac, Bc, Cc, Dc] = tf2ss(num, den);

fprintf('=== 4. tf2ss 결과 (제어기 표준형) ===\n');
fprintf('  Ac = %s\n', mat2str(Ac, 4));
fprintf('  Bc = %s,  Cc = %s,  Dc = %g\n', mat2str(Bc), mat2str(Cc, 4), Dc);
fprintf('  분모 계수 [1 a1 a0] = %s  -->  Ac 첫 줄 = -[a1 a0] = %s\n', ...
        mat2str(den, 4), mat2str(Ac(1,:), 4));
fprintf('  Ac 의 고유값 : %s  (1절 A 의 고유값과 같다)\n\n', mat2str(sort(eig(Ac)).', 4));

%% 5. 상태공간 표현은 하나가 아니다 — 세 가지 실현 비교
%
%  같은 전달함수를 만드는 (A,B,C,D) 는 무수히 많습니다.
%  이것들을 전달함수의 "실현(realization)" 이라고 부릅니다.
%
%  비유 : 같은 게임 세이브 파일을 JSON 으로 저장하든 XML 로 저장하든
%         게임을 불러오면 같은 장면이 나옵니다. 저장 형식(상태 좌표)만 다릅니다.
%
%  두 실현은 가역행렬 T 로 이어집니다.  x_phys = T * x_can  이면
%
%        A_can = T^-1 A_phys T,   B_can = T^-1 B_phys,   C_can = C_phys T
%
%  4절의 관계  z1 = m*속도, z2 = m*위치  를 뒤집으면
%
%        [위치]   [ 0    1/m ] [z1]
%        [속도] = [ 1/m  0   ] [z2]       -->   T = [0 1/m; 1/m 0]
%
%  아래에서 세 실현을 비교합니다.
%    (P) 물리 좌표     : 1절의 A, B, C, D
%    (T) tf2ss 결과    : 4절의 Ac, Bc, Cc, Dc
%    (S) ss(G) 결과    : MATLAB 객체 변환

T = [0 1/m; 1/m 0];
fprintf('=== 5. 좌표 변환 T 로 두 실현이 이어지는지 확인 ===\n');
fprintf('  T^-1 A T  와 Ac 의 최대 차이 : %.1e\n', max(abs(T\A*T - Ac), [], 'all'));
fprintf('  T^-1 B    와 Bc 의 최대 차이 : %.1e\n', max(abs(T\B - Bc)));
fprintf('  C T       와 Cc 의 최대 차이 : %.1e\n\n', max(abs(C*T - Cc)));

sysP = ss(A, B, C, D);
sysT = ss(Ac, Bc, Cc, Dc);
sysS = ss(G);

reals = {'(P) 물리 좌표', sysP; '(T) tf2ss', sysT; '(S) ss(G)', sysS};

fprintf('=== 5-1. 세 실현 비교 ===\n');
fprintf('  %-16s %-30s %-20s %-10s\n', '실현', 'A', '고유값', 'DC 이득');
for i = 1:size(reals,1)
    si = reals{i,2};
    fprintf('  %-16s %-30s %-20s %-10.4f\n', reals{i,1}, mat2str(si.A, 3), ...
            mat2str(sort(eig(si.A)).', 3), dcgain(si));
end

t = (0:0.01:40)';
F = ones(size(t));                                % 1 N 계단 입력
[yP, ~, xP] = lsim(sysP, F, t);
[yT, ~, xT] = lsim(sysT, F, t);
[yS, ~, xS] = lsim(sysS, F, t);

fprintf('  출력 y 의 최대 차이 : P-T %.1e,  P-S %.1e\n', max(abs(yP-yT)), max(abs(yP-yS)));
fprintf('  상태 x 의 최대 차이 : P-T %.2f,  P-S %.2f   (상태는 다르다)\n', ...
        max(abs(xP-xT), [], 'all'), max(abs(xP-xS), [], 'all'));
fprintf('  --> 출력은 같고 내부 상태는 다릅니다. 전달함수는 출력만 보기 때문에\n');
fprintf('      이 차이를 구분하지 못합니다.\n\n');

figure('Name','세 실현의 출력과 상태');
tiledlayout(1, 2, 'TileSpacing','compact');

nexttile
plot(t, yP, 'LineWidth', 3); hold on;
plot(t, yT, '--', 'LineWidth', 2);
plot(t, yS, ':', 'LineWidth', 2);
grid on; xlabel('Time [s]'); ylabel('출력 y = 위치 [m]');
title('출력 : 세 실현이 완전히 겹친다');
legend('(P) 물리 좌표', '(T) tf2ss', '(S) ss(G)', 'Location','southeast');

nexttile
plot(t, xP(:,1), 'LineWidth', 2); hold on;
plot(t, xT(:,1), '--', 'LineWidth', 2);
plot(t, xS(:,1), ':', 'LineWidth', 2);
grid on; xlabel('Time [s]'); ylabel('첫째 상태 x_1');
title('첫째 상태 : 실현마다 뜻이 다르다');
legend('(P) 위치', '(T) m x 속도', '(S) MATLAB 척도 조정', 'Location','southeast');

%% 6. 왕복하면 원래대로 돌아오는가
%
%  ss -> tf 는 답이 하나뿐입니다 (전달함수는 유일합니다).
%  tf -> ss 는 답이 무수히 많은 것 중 하나를 고릅니다.
%  그러므로
%      tf -> ss -> tf  : 원래 전달함수로 돌아온다
%      ss -> tf -> ss  : 원래 행렬로 돌아온다는 보장이 없다

[num2, den2] = ss2tf(Ac, Bc, Cc, Dc);             % tf -> ss -> tf
[A2, B2, C2, D2] = tf2ss(num, den);               % ss -> tf -> ss

fprintf('=== 6. 왕복 결과 ===\n');
fprintf('  tf -> ss -> tf : 분자 차이 %.1e, 분모 차이 %.1e  (돌아온다)\n', ...
        max(abs(num2 - num)), max(abs(den2 - den)));
fprintf('  ss -> tf -> ss : 원래 A = %s\n', mat2str(A, 3));
fprintf('                   왕복 A = %s  (돌아오지 않는다)\n', mat2str(A2, 3));
fprintf('  --> 전달함수로 바꾸는 순간 "상태를 어떻게 골랐는가" 정보가 사라집니다.\n\n');

%% 7. 변환한 모델에 초기조건을 줄 때
%
%  W02_02 의 7절 상황을 다시 봅니다. 물체를 0.5 m 당겨 놓고 힘 없이 놓습니다.
%  물리 좌표에서는 x0 = [0.5 ; 0] (위치 0.5, 속도 0) 입니다.
%
%  tf2ss 로 얻은 모델에 이 값을 그대로 넣으면 어떻게 되는가?
%  그 모델의 상태는 [m*속도 ; m*위치] 이므로 [0.5 ; 0] 은
%  "위치 0, 속도 0.5/m" 을 뜻합니다. 전혀 다른 상황입니다.
%
%  올바른 방법은 좌표를 바꿔 넣는 것입니다.
%        x_can0 = T^-1 * x_phys0

x0_phys = [0.5; 0];
x0_can  = T \ x0_phys;

t7 = (0:0.01:40)';
y_ok    = initial(sysP, x0_phys, t7);             % 기준 (물리 좌표)
y_conv  = initial(sysT, x0_can,  t7);             % 좌표 변환 후
y_wrong = initial(sysT, x0_phys, t7);             % 변환 없이 그대로

fprintf('=== 7. 초기조건과 좌표 ===\n');
fprintf('  물리 좌표 x0      = %s\n', mat2str(x0_phys.'));
fprintf('  표준형 좌표 x0    = T^-1 x0 = %s\n', mat2str(x0_can.'));
fprintf('  %-26s 최대 차이 %.1e  (일치)\n', '좌표 변환 후 넣은 경우', max(abs(y_conv - y_ok)));
fprintf('  %-26s 최대 차이 %.2f m (전혀 다른 응답)\n', '그대로 넣은 경우', max(abs(y_wrong - y_ok)));
fprintf('  --> 변환한 모델의 상태가 무엇인지 모르고 초기조건을 주면 틀립니다.\n\n');

figure('Name','초기조건과 좌표 변환');
plot(t7, y_ok, 'LineWidth', 3); hold on;
plot(t7, y_conv, '--', 'LineWidth', 2);
plot(t7, y_wrong, ':', 'LineWidth', 2);
yline(0, 'k:'); grid on;
xlabel('Time [s]'); ylabel('위치 x [m]');
title('초기조건은 모델의 상태 좌표에 맞춰 넣어야 한다');
legend('물리 좌표 x_0 = [0.5; 0]', 'tf2ss 모델, T^{-1} x_0 로 변환', ...
       'tf2ss 모델, x_0 를 그대로 (잘못)', 'Location','northeast');

%% 8. 이번 실습의 정리
%
%  1) ss2tf 는 G(s) = C (sI - A)^-1 B + D 를 계산합니다.
%     분모 = det(sI - A) 이므로 전달함수의 극점은 A 의 고유값과 같습니다.
%
%  2) 출력 C 를 바꾸면 분자(영점)만 바뀌고 분모(극점)는 그대로입니다.
%     위치 대신 속도를 재면 s = 0 에 영점이 생깁니다.
%
%  3) tf2ss 는 제어기 표준형을 돌려줍니다. 분모 계수가 A 의 첫 줄에 그대로
%     들어가지만, 상태는 위치·속도가 아니라 순서와 척도가 바뀐 변수입니다.
%
%  4) 하나의 전달함수에 대응하는 상태공간 표현(실현)은 무수히 많고,
%     좌표 변환 T 로 서로 이어집니다. 출력은 같고 내부 상태만 다릅니다.
%
%  5) 그래서 ss -> tf -> ss 왕복은 원래 행렬로 돌아오지 않으며,
%     변환한 모델에 초기조건을 줄 때는 좌표를 반드시 맞춰야 합니다.
%
%% 9. 직접 해 볼 것
%
%   (1) 맨 위에서 plant_msd(2, 0.2, 1) 로 m = 2 를 주고 다시 실행하십시오.
%       -> T = [0 0.5; 0.5 0] 이 되어 척도 차이가 눈에 보입니다.
%          5-1절 표에서 (T) 와 (S) 의 A 도 서로 달라집니다.
%
%   (2) 3절에서 C = [k b] 로 바꿔 보십시오. (벽이 받는 힘 = 스프링 힘 + 댐퍼 힘)
%       -> 분자가 b s + k 가 되어 s = -k/b 에 영점이 생깁니다.
%
%   (3) 2절 명령에 D = 1 을 주면 분자가 어떻게 바뀌는지 확인하십시오.
%       -> 분자 = C adj(sI - A) B + D det(sI - A). 분자·분모 차수가 같아집니다.
%
%  다음 실습 : W03_02_state_space.m
%              상태를 고르는 기준(에너지)과 상태공간 모델의 해석을 다룹니다.
