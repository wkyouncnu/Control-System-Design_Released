%% W03_05_linearize_verify.m
%  3주차 실습 (5) : 선형화를 손·기호·수치·Simulink 네 가지로 구하고 검증한다
%
%  이 과목이 배우는 도구(전달함수, 극점, 근궤적, 보드 선도, 상태궤환)는
%  **전부 LTI 시스템에만 적용됩니다.** 그러므로 비선형 플랜트를 다루려면
%  먼저 선형 모델을 만들어야 하고, 그 선형 모델이 **믿을 만한지**를
%  숫자로 확인해야 합니다. 이 스크립트가 그 두 가지를 합니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 평형점(동작점)은 어떻게 찾는가?                  -> 1절
%    Q2. 야코비안을 MATLAB 으로 구하는 방법은?             -> 2~4절
%    Q3. 네 가지 방법의 답이 정말 같은가?                  -> 5절
%    Q4. Simulink 모델을 직접 선형화할 수 있는가?          -> 6절
%    Q5. 이 선형 모델은 몇 도까지 믿어도 되는가?           -> 7절
%
%  돌리면 나오는 것
%    표 4 개 + 그림 2 장
%    걸리는 시간 : 약 20 초 (Simulink 선형화가 대부분)
%
%  대응하는 강의노트 : W03_LectureNote.mlx 의 9-1 ~ 9-4 절, 13-1 ~ 13-3 절
%
%  제어시스템설계 3주차 | 충남대학교 자율운항시스템공학과

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

%% 0. 대상 시스템
%
%  단진자의 비선형 상태방정식입니다. 상태는 두 개입니다.
%
%      x1 = theta       (연직 아래에서 잰 각도)
%      x2 = theta_dot   (각속도)
%
%      x1' = x2
%      x2' = ( u - b*x2 - m*g*l*sin(x1) ) / J,      J = m*l^2
%
%  오른쪽 식에 sin 이 들어 있어 **비선형**입니다.
%  이 식 하나 때문에 지금까지 배운 도구를 그대로 쓸 수 없습니다.

m = 0.5;  l = 0.3;  b = 0.15;  g = 9.81;  J = m*l^2;
f = @(x,u) [ x(2) ; ( u - b*x(2) - m*g*l*sin(x(1)) ) / J ];

fprintf('\n대상 : 단진자  m = %.2f kg, l = %.2f m, b = %.2f, J = %.4f\n', m, l, b, J);

%% 1. 먼저 평형점을 찾는다
%
%  선형화는 **한 점 근처**에서만 성립합니다. 그러므로 그 점을 먼저 정해야 합니다.
%  아무 점이나 쓰지 않고 보통 **평형점**을 씁니다.
%
%  평형점의 정의는 한 줄입니다.
%
%      f(x0, u0) = 0        즉 가만히 두어도 상태가 변하지 않는 점
%
%  진자에서 이 식을 풀면
%
%      x2 = 0                        (각속도가 0)
%      u0 = m*g*l*sin(x1)            (중력 토크를 정확히 상쇄하는 토크)
%
%  u0 = 0 으로 두면 sin(x1) = 0 이므로 x1 = 0 또는 x1 = pi 입니다.
%  **평형점이 두 개**라는 뜻이고, 이것이 12절의 출발점입니다.

u0   = 0;
gEq  = @(th) u0 - m*g*l*sin(th);          % 알짜 토크. 이것이 0 인 곳이 평형점
%  [주의] 여기서 `fsolve` 를 쓰지 않습니다. `fsolve` 는 Optimization Toolbox 가
%         있어야 도는데, 미지수가 하나뿐인 문제에는 core MATLAB 의 `fzero` 로 충분합니다.
%         실습실 PC 에 없는 툴박스를 쓰면 그 줄에서 스크립트가 멈춥니다.
%
%  `fzero` 명령 정리
%   - 원리 — 부호가 바뀌는 구간을 좁혀 가며 f(x)=0 인 x 를 찾는다
%   - 입력 — fzero(함수핸들, 출발점) 또는 fzero(함수핸들, [a b]) 로 구간을 준다
%   - 출력 — 근 하나. **출발점 근처의 근**을 준다
%   - 주의 — 근이 여럿이면 출발점을 바꿔 가며 여러 번 불러야 한다

th_a = fzero(gEq, 0.4);                   % 0 근처에서 출발
th_b = fzero(gEq, 3.0);                   % pi 근처에서 출발

fprintf('\n=== 1. 평형점 (u0 = %.2f N*m) ===\n', u0);
fprintf('  출발 0.4 rad -> theta0 = %8.4f rad = %6.1f deg\n', th_a, rad2deg(th_a));
fprintf('  출발 3.0 rad -> theta0 = %8.4f rad = %6.1f deg\n', th_b, rad2deg(th_b));
fprintf('  둘 다 f(x0,u0) = 0 을 만족합니다. 평형점은 하나가 아닙니다.\n');

%  토크를 넣으면 평형점 자체가 옮겨 갑니다.
u0_shift = 0.6;
th_shift = fzero(@(th) u0_shift - m*g*l*sin(th), 0.4);
fprintf('  u0 = %.2f N*m 로 바꾸면 theta0 = %.1f deg 로 이동합니다.\n', ...
        u0_shift, rad2deg(th_shift));

%% 2. 방법 A — 손으로 편미분한 야코비안
%
%  테일러 전개에서 1차 항만 남기면 다음과 같습니다.
%
%      d(dx)/dt = A*dx + B*du,      dx = x - x0,   du = u - u0
%
%      A(i,j) = df_i/dx_j |(x0,u0)        B(i) = df_i/du |(x0,u0)
%
%  진자에 대해 직접 미분하면
%
%      A = [        0                 1    ]      B = [  0  ]
%          [ -m*g*l*cos(th0)/J      -b/J   ]          [ 1/J ]
%
%  cos(th0) 가 들어가는 것이 핵심입니다. **어느 점에서 폈느냐**에 따라
%  이 성분의 부호가 바뀌고, 그 부호 하나가 안정과 불안정을 가릅니다.

th0 = 0;                                   % 매달린 평형점
x0  = [th0; 0];

A_hand = [        0                 1   ;
          -m*g*l*cos(th0)/J      -b/J  ];
B_hand = [0; 1/J];

%% 3. 방법 B — Symbolic Math Toolbox 의 jacobian
%
%  `jacobian` 명령 정리
%
%   - 원리 — 기호식 벡터 f 를 기호변수 벡터 x 로 편미분한 행렬을 만든다
%   - 입력 — jacobian(f, x). f 는 심볼릭 벡터, x 는 심볼릭 변수 벡터
%   - 출력 — 크기 (length(f) x length(x)) 인 심볼릭 행렬
%   - 주의 — 결과는 여전히 **기호식**이다. 동작점 값을 넣으려면 `subs` 를 쓰고,
%            숫자로 바꾸려면 `double` 을 한 번 더 씌운다
%
%  손으로 미분한 것과 다른 점은 **틀릴 수가 없다**는 것뿐입니다.
%  상태가 여섯 개, 여덟 개로 늘어나면 손 미분은 실수하기 매우 쉽습니다.

%  [주의] 이 절만 Symbolic Math Toolbox 가 필요합니다.
%         없는 PC 에서도 스크립트가 끝까지 돌도록 아래처럼 확인하고 건너뜁니다.
%         나머지 절(손 미분, 수치 미분, Simulink 선형화)은 툴박스가 없어도 됩니다.
hasSym = license('test','Symbolic_Toolbox') && ~isempty(which('syms'));

if hasSym
    syms th w uu real
    f_sym = [ w ; ( uu - b*w - m*g*l*sin(th) ) / J ];

    A_sym_expr = jacobian(f_sym, [th w]);
    B_sym_expr = jacobian(f_sym, uu);

    A_sym = double(subs(A_sym_expr, [th w uu], [th0 0 u0]));
    B_sym = double(subs(B_sym_expr, [th w uu], [th0 0 u0]));

    fprintf('\n=== 3. 기호 미분이 준 A 행렬 (식 그대로) ===\n');
    disp(A_sym_expr);
else
    A_sym = nan(2,2);  B_sym = nan(2,1);
    fprintf('\n=== 3. 기호 미분 ===\n');
    fprintf('  Symbolic Math Toolbox 가 없어 이 절은 건너뜁니다.\n');
    fprintf('  손 미분과 수치 미분만으로도 5절의 대조는 그대로 됩니다.\n');
end

%% 4. 방법 C — 수치 미분 (중심 차분)
%
%  기호식조차 없을 때(예: 플랜트가 컴파일된 함수나 실험 데이터일 때)
%  쓰는 방법입니다. 정의 그대로 계산합니다.
%
%      df/dx ~ ( f(x+h) - f(x-h) ) / (2h)
%
%  **중심 차분**을 쓰는 이유는 전진 차분보다 오차가 훨씬 작기 때문입니다.
%  전진 차분의 오차는 h 에 비례하고, 중심 차분은 h^2 에 비례합니다.
%  h 는 너무 크면 근사가 나쁘고 너무 작으면 반올림 오차가 커집니다.
%  배정밀도에서는 1e-6 근처가 무난합니다.

h = 1e-6;
A_num = zeros(2,2);
for j = 1:2
    e = zeros(2,1);  e(j) = h;
    A_num(:,j) = ( f(x0+e, u0) - f(x0-e, u0) ) / (2*h);
end
B_num = ( f(x0, u0+h) - f(x0, u0-h) ) / (2*h);

%% 5. 네 방법을 대조한다 (Simulink 는 6절에서 합류)
%
%  **같은 답이 나와야 합니다.** 다르면 어느 하나가 틀린 것입니다.
%  이런 대조를 습관으로 만들면 부호 실수를 초기에 잡을 수 있습니다.

fprintf('\n=== 5. A 행렬 대조 (동작점 theta0 = %.1f deg) ===\n', rad2deg(th0));
fprintf('  %-12s %s\n', '손 미분',   mat2str(round(A_hand,6)));
fprintf('  %-12s %s\n', '기호 미분', mat2str(round(A_sym,6)));
fprintf('  %-12s %s\n', '수치 미분', mat2str(round(A_num,6)));
if hasSym
    fprintf('  최대 차이 : 손-기호 %.3e,  손-수치 %.3e\n', ...
            max(abs(A_hand(:)-A_sym(:))), max(abs(A_hand(:)-A_num(:))));
else
    fprintf('  최대 차이 : 손-수치 %.3e   (기호 미분은 툴박스가 없어 건너뜀)\n', ...
            max(abs(A_hand(:)-A_num(:))));
end

fprintf('\n=== 5-1. B 행렬 대조 ===\n');
fprintf('  %-12s %s\n', '손 미분',   mat2str(round(B_hand,6)));
fprintf('  %-12s %s\n', '기호 미분', mat2str(round(B_sym,6)));
fprintf('  %-12s %s\n', '수치 미분', mat2str(round(B_num,6)));

%% 6. 방법 D — Simulink 모델을 그대로 선형화한다
%
%  실무에서 플랜트 모델은 식이 아니라 **Simulink 블록선도**로 옵니다.
%  블록이 수백 개면 손으로 미분할 수 없습니다. 그때 쓰는 것이 `linearize` 입니다.
%
%  `linio` 명령 정리
%
%   - 원리 — 모델의 어느 신호를 입력으로 보고 어느 신호를 출력으로 볼지 표시한다
%   - 입력 — linio('블록경로', 포트번호, 종류). 종류는 'input' 또는 'output'
%   - 출력 — 선형화 입출력점 객체. 배열로 모아 `linearize` 에 넘긴다
%   - 주의 — 블록 **경로**와 **출력 포트 번호**를 준다. 신호 이름이 아니다
%
%  `linearize` 명령 정리
%
%   - 원리 — 지정한 동작점에서 모델 전체를 수치 선형화해 ss 객체를 만든다
%   - 입력 — linearize(모델이름, io) 또는 linearize(모델이름, io, op)
%   - 출력 — 상태공간 모델 (ss)
%   - 주의 — op 를 주지 않으면 **모델의 초기조건**을 동작점으로 씁니다.
%            그러므로 적분기 초기값을 평형점으로 맞춰 두어야 의미가 있습니다

model = 'W03_Pendulum_NonlinVsLin';
here  = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
if ~bdIsLoaded(model), load_system(fullfile(here, [model '.slx'])); end

theta0   = th0;          % 적분기 초기값 = 동작점
u_torque = u0;
t_end    = 10;
assignin('base','m',m); assignin('base','l',l); assignin('base','b',b);
assignin('base','g',g); assignin('base','theta0',theta0);
assignin('base','u_torque',u_torque); assignin('base','t_end',t_end);

%  [주의] 이 절은 Simulink Control Design 이 있어야 돕니다.
%         10주차에서도 쓰는 도구이므로 실습실 PC 에 있어야 하지만,
%         없더라도 스크립트가 여기서 멈추지 않도록 확인하고 건너뜁니다.
hasSCD = license('test','Simulink_Control_Design') && ~isempty(which('linearize'));

sysHand = ss(A_hand, B_hand, [1 0], 0);

if hasSCD
    io(1) = linio([model '/입력 토크'], 1, 'input');
    io(2) = linio([model '/적분 각속도에서 각도 비선형'], 1, 'output');

    sysSL = linearize(model, io);

    fprintf('\n=== 6. Simulink linearize 결과 ===\n');
    fprintf('  입력  : %s 의 1번 출력 포트\n', '입력 토크');
    fprintf('  출력  : %s 의 1번 출력 포트\n', '적분 각속도에서 각도 비선형');
    fprintf('  극점  : %s\n', mat2str(round(sort(pole(sysSL)).', 4)));
    fprintf('  손계산 극점 : %s\n', mat2str(round(sort(pole(sysHand)).', 4)));
    fprintf('  전달함수가 같은가 (norm 차이) : %.3e\n', norm(sysSL - sysHand, inf));
else
    fprintf('\n=== 6. Simulink linearize ===\n');
    fprintf('  Simulink Control Design 이 없어 이 절은 건너뜁니다.\n');
    fprintf('  손계산 극점만 보입니다 : %s\n', ...
            mat2str(round(sort(pole(sysHand)).', 4)));
end
%% 6-1. 동작점을 바꾸면 결과도 바뀐다
%
%  같은 모델을 **거꾸로 선 자세**에서 선형화합니다.
%  블록은 하나도 안 바꾸고 적분기 초기값만 pi 로 둡니다.

if hasSCD
    assignin('base','theta0', pi);
    sysUp = linearize(model, io);
    assignin('base','theta0', theta0);         % 원래대로 되돌린다

    fprintf('\n=== 6-1. 동작점을 pi 로 바꾸면 ===\n');
    fprintf('  매달린 자세 극점 : %s\n', mat2str(round(sort(pole(sysSL)).', 4)));
    fprintf('  거꾸로 자세 극점 : %s\n', mat2str(round(sort(pole(sysUp)).', 4)));
    fprintf('  거꾸로 자세에는 우반면 극점이 있습니다 -> 불안정\n');
    fprintf('  같은 모델, 같은 블록입니다. 바뀐 것은 동작점 하나뿐입니다.\n');
else
    [~, pUpChk] = plant_pendulum(pi);
    fprintf('\n=== 6-1. 동작점을 pi 로 바꾸면 ===\n');
    fprintf('  (툴박스가 없어 손계산 A 로 대신 보입니다)\n');
    fprintf('  매달린 자세 고유값 : %s\n', mat2str(round(sort(eig(A_hand)).', 4)));
    fprintf('  거꾸로 자세 고유값 : %s\n', mat2str(round(sort(eig(pUpChk.A)).', 4)));
    fprintf('  거꾸로 자세에는 우반면 고유값이 있습니다 -> 불안정\n');
end

%% 7. 선형 모델을 정량적으로 검증한다
%
%  여기까지는 "선형 모델을 만들었다" 일 뿐입니다.
%  **믿어도 되는 범위를 숫자로 정하는 것**이 검증입니다.
%
%  절차
%    (1) 같은 초기조건을 비선형 모델과 선형 모델에 각각 준다
%    (2) 두 응답의 최대 차이를 비선형 응답의 크기로 나눈다 (상대오차)
%    (3) 초기각을 키워 가며 이 오차가 기준(예: 5 %)을 넘는 지점을 찾는다
%
%  이 지점이 **선형 설계가 유효한 범위**이고, 설계가 끝난 뒤에는
%  제어기를 반드시 비선형 모델에 붙여 이 범위 안에 머무는지 확인해야 합니다.

sysLin = ss(A_hand, B_hand, [1 0], 0);
degs   = 2:2:80;
eRel   = zeros(size(degs));
tEnd   = 3;
tg     = linspace(0, tEnd, 1200)';
odeopt = odeset('RelTol',1e-8, 'AbsTol',1e-10);

for i = 1:numel(degs)
    xi = [deg2rad(degs(i)); 0];
    [tn, xn] = ode45(@(tt,x) f(x,u0), [0 tEnd], xi, odeopt);
    yn = interp1(tn, xn(:,1), tg, 'linear');
    yl = initial(sysLin, xi, tg);
    eRel(i) = 100*max(abs(yn - yl))/max(abs(yn));
end

d5 = interp1(eRel, degs, 5, 'linear');

fprintf('\n=== 7. 선형 모델의 유효 범위 ===\n');
fprintf('  %-12s %-14s\n', '초기각[deg]', '최대 상대오차[%]');
for dd = [10 20 30 40 50 60 70]
    fprintf('  %-12d %-14.2f\n', dd, interp1(degs, eRel, dd));
end
fprintf('  상대오차 5 %% 를 넘는 지점 : %.0f deg\n', d5);
fprintf('  --> 이 진자에서는 약 %.0f deg 안쪽이면 선형 모델을 써도 됩니다.\n', d5);

figure('Name','선형 모델의 유효 범위');
plot(degs, eRel, 'LineWidth', 2.5); hold on; grid on
yline(5, 'r--', 'LineWidth', 1.8);
xline(d5, 'r:', 'LineWidth', 1.8);
xlabel('초기 각도 [deg]'); ylabel('최대 상대오차 [%]');
title(sprintf('선형 모델은 약 %.0f도까지 오차 5 %% 이내', d5));
legend('실제 오차','5 % 기준','Location','northwest');

%% 7-1. 정적 오차와 동적 오차는 다르다
%
%  9절에서 sin(theta) 를 theta 로 바꿀 때의 오차가 30 도에서 약 5 % 라고 했습니다.
%  그런데 7절의 응답 오차는 그보다 **더 큰 각도까지 버팁니다.**
%
%  이유는 이렇습니다.
%
%   - 9절의 오차는 **한 점에서 함수값을 비교**한 정적 오차입니다
%   - 7절의 오차는 그 함수 오차가 **적분되어 응답으로 나타난 결과**입니다
%   - 진자는 한 주기 동안 각도가 커졌다 작아졌다 하므로,
%     최대 각도에서만 오차가 크고 대부분의 시간에는 작습니다
%
%  **그래서 유효 범위는 반드시 응답으로 확인해야 합니다.**
%  함수 오차만 보고 판단하면 지나치게 보수적인 답이 나옵니다.

thStatic = fzero(@(x) abs(sin(x)-x)/abs(sin(x)) - 0.05, 0.5);
fprintf('\n=== 7-1. 두 기준의 비교 ===\n');
fprintf('  sin 함수 자체의 오차가 5 %% 가 되는 각도 : %.0f deg\n', rad2deg(thStatic));
fprintf('  응답의 상대오차가 5 %% 가 되는 각도      : %.0f deg\n', d5);
fprintf('  --> 정적 기준이 더 보수적입니다. 설계 초기에는 이쪽을 쓰고,\n');
fprintf('      최종 확인은 응답으로 하십시오.\n');

figure('Name','비선형과 선형 응답 비교');
show = [10 40 70];
col  = lines(3);
hold on; grid on
for i = 1:3
    xi = [deg2rad(show(i)); 0];
    [tn, xn] = ode45(@(tt,x) f(x,u0), [0 tEnd], xi, odeopt);
    plot(tn, rad2deg(xn(:,1)), 'LineWidth', 2.5, 'Color', col(i,:), ...
         'DisplayName', sprintf('%d도 비선형', show(i)));
    plot(tg, rad2deg(initial(sysLin, xi, tg)), '--', 'LineWidth', 1.8, ...
         'Color', col(i,:), 'DisplayName', sprintf('%d도 선형', show(i)));
end
xlabel('시간 [s]'); ylabel('각도 [deg]');
legend('Location','northeast','NumColumns',2);
title('초기각이 커질수록 두 응답의 박자가 어긋난다');

%% 8. 정리
%
%  - 선형화는 **동작점을 먼저 정하는 것**에서 시작한다. 평형점은 f(x0,u0)=0 의 해다
%  - 야코비안은 손·기호·수치·Simulink 네 가지로 구할 수 있고 **답은 같아야 한다**
%  - 상태가 많아지면 손 미분은 실수하기 쉬우므로 `jacobian` 이나 `linearize` 를 쓴다
%  - 같은 모델이라도 **동작점이 다르면 완전히 다른 선형 모델**이 나온다
%  - 선형 모델을 만든 것으로 끝이 아니다. **유효 범위를 숫자로 정해야** 한다
%  - 이 과목의 모든 설계 도구는 LTI 를 전제하므로, 선형 모델이 **기준 모델**이 된다

fprintf('\n=== 8. 정리 ===\n');
fprintf('  1) 평형점을 먼저 찾는다        : f(x0,u0) = 0\n');
fprintf('  2) 야코비안으로 A, B 를 만든다  : 네 방법의 답이 같아야 한다\n');
fprintf('  3) 동작점이 다르면 모델도 다르다 : 매달림은 안정, 거꾸로는 불안정\n');
fprintf('  4) 유효 범위를 숫자로 정한다     : 이 진자는 약 %.0f deg\n', d5);
fprintf('  5) 설계 후 비선형 모델로 되돌아가 검증한다\n\n');

%% 9. 직접 해 볼 것
%
%  (1) 6절에서 `theta0` 를 pi/2 로 두고 선형화해 보십시오.
%      이때는 평형점이 아니므로 A 의 (2,1) 성분이 0 이 됩니다.
%      그런데 이 자세를 유지하려면 토크 u0 = m*g*l 이 필요합니다.
%      `u_torque` 를 그 값으로 맞추고 다시 선형화하면 무엇이 달라집니까?
%
%  (2) 감쇠 b 를 0 으로 두고 7절을 다시 돌려 보십시오.
%      유효 범위가 넓어집니까, 좁아집니까? 왜 그러한가?
%
%  (3) 4절의 h 를 1e-2, 1e-6, 1e-12 로 바꿔 가며 수치 미분 오차를 보십시오.
%      가장 작은 h 가 가장 정확하지 않은 이유를 설명하십시오.
