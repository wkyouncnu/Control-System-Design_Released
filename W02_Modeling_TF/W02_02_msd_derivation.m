%% W02_02_msd_derivation.m
%  2주차 실습 (2) : 물리 법칙에서 전달함수까지, 그리고 극점의 이동
%
%  이 스크립트에서 답할 질문
%    Q1. 물리 법칙에서 전달함수까지 가는 길은 어떤 단계로 되어 있는가? -> 1~3절
%    Q2. 2차 표준형의 wn 과 zeta 는 물리 파라미터와 어떻게 연결되는가? -> 4절
%    Q3. 댐퍼를 세게 하면 극점은 어디로 움직이는가?                    -> 5절
%    Q4. 전달함수로 표현할 수 없는 상황이 있는가?                      -> 7절
%
%  대응하는 강의노트 : W02_LectureNote.mlx
%  대응하는 Simulink : W02_MSD_ThreeWays.slx (W02_03_run_simulink.m 로 실행)
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

%% 1. 1단계 : 물리 법칙에서 미분방정식 세우기
%
%  질량 m 인 물체가 스프링 k 와 댐퍼 b 로 벽에 연결되어 있고,
%  우리가 힘 F(t) 를 가합니다. 변위 x 는 평형위치에서 잰 값입니다.
%
%  자유물체도(free body diagram)를 그리고 물체에 작용하는 힘을 모두 적습니다.
%
%      가한 힘         : +F
%      스프링 복원력   : -k*x      (많이 늘어날수록 세게 당김, 부호는 반대 방향)
%      댐퍼 저항력     : -b*x'     (빠를수록 세게 저항, 부호는 속도 반대 방향)
%
%  뉴턴의 제2법칙 (힘의 합 = 질량 x 가속도) 을 적용하면
%
%      F - k*x - b*x' = m*x''
%
%  항을 정리하면 우리가 아는 형태가 됩니다.
%
%      m*x'' + b*x' + k*x = F          ... (미분방정식)
%
%  여기까지가 "모델링"입니다. 제어공학이 아니라 동역학의 영역입니다.
%  하지만 이 단계가 틀리면 그 뒤의 모든 제어 설계가 무의미해집니다.

m = 1.0;      % 질량 [kg]
b = 0.2;      % 감쇠계수 [N*s/m]
k = 1.0;      % 스프링 상수 [N/m]

fprintf('=== 1단계. 미분방정식 ===\n');
fprintf('  %.1f*x'''' + %.1f*x'' + %.1f*x = F\n\n', m, b, k);

%% 2. 2단계 : 라플라스 변환
%
%  미분방정식을 s 영역으로 옮깁니다. 필요한 성질은 딱 두 개입니다.
%
%      L{x'(t)}  = s*X(s) - x(0)
%      L{x''(t)} = s^2*X(s) - s*x(0) - x'(0)
%
%  전달함수를 구할 때는 초기조건을 모두 0 으로 둡니다. 그러면 간단해집니다.
%
%      L{x'}  = s*X(s)
%      L{x''} = s^2*X(s)
%
%  이제 미분방정식의 각 항을 바꿔 쓰면
%
%      m*s^2*X(s) + b*s*X(s) + k*X(s) = F(s)
%
%  X(s) 로 묶으면
%
%      (m*s^2 + b*s + k) * X(s) = F(s)
%
%  미분이 s 의 곱셈으로 바뀌면서, 미분방정식이 그냥 1차 방정식이 되었습니다.
%  이것이 라플라스 변환을 쓰는 이유입니다.

fprintf('=== 2단계. 라플라스 변환 ===\n');
fprintf('  (%.1f*s^2 + %.1f*s + %.1f) * X(s) = F(s)\n\n', m, b, k);

%% 3. 3단계 : 전달함수
%
%  출력을 입력으로 나누면 끝입니다.
%
%      G(s) = X(s)/F(s) = 1 / (m*s^2 + b*s + k)

G = 1 / (m*s^2 + b*s + k);

fprintf('=== 3단계. 전달함수 ===\n');
G

% 공통 함수로도 같은 것을 얻을 수 있습니다. 앞으로는 이 함수를 쓰겠습니다.
G_lib = plant_msd(m, b, k);
fprintf('  plant_msd 로 만든 것과 같은가? 최대 계수 차이 = %.2e\n\n', ...
        max(abs(cell2mat(tfdata(G)) - cell2mat(tfdata(G_lib)))));

%% 4. 2차 표준형과의 대응
%
%  제어공학에서는 2차 시스템을 항상 이 표준형으로 놓고 이야기합니다.
%
%      G(s) = wn^2 / (s^2 + 2*zeta*wn*s + wn^2)
%
%  우리 전달함수를 s^2 의 계수가 1 이 되도록 정리하면
%
%      G(s) = (1/m) / (s^2 + (b/m)*s + (k/m))
%
%  분모끼리 비교합니다.
%
%      wn^2      = k/m        ->  wn   = sqrt(k/m)
%      2*zeta*wn = b/m        ->  zeta = b / (2*sqrt(m*k))
%
%  물리적으로 읽으면 이렇습니다.
%      wn (고유진동수) : 스프링이 셀수록, 질량이 가벼울수록 빨리 흔들린다.
%      zeta (감쇠비)   : 댐퍼가 셀수록 진동이 빨리 죽는다.
%
%  왜 이 두 숫자로 정리하는가:
%      m, b, k 는 세 개인데 wn, zeta 는 두 개입니다. 응답의 "모양"을 결정하는 데는
%      두 개면 충분하기 때문입니다. 질량이 2배여도 스프링이 2배면 응답 모양은 같습니다.
%      4주차 시간응답 사양은 전부 이 wn, zeta 로 기술됩니다.

wn   = sqrt(k/m);
zeta = b / (2*sqrt(m*k));

fprintf('=== 4단계. 표준형 파라미터 ===\n');
fprintf('  wn   = sqrt(k/m)        = %.4f rad/s\n', wn);
fprintf('  zeta = b/(2*sqrt(m*k))  = %.4f\n', zeta);
fprintf('  damp 명령으로 확인:\n');
damp(G)

%% 5. 댐퍼를 세게 하면 극점은 어디로 가는가
%
%  이번 절이 2주차에서 가장 볼 만한 그림입니다.
%
%  극점은 특성방정식 m*s^2 + b*s + k = 0 의 근이므로 근의 공식을 쓰면
%
%      s = [ -b +- sqrt(b^2 - 4*m*k) ] / (2*m)
%
%  판별식 b^2 - 4*m*k 의 부호에 따라 세 가지로 갈립니다.
%
%      b^2 < 4mk  (zeta < 1) : 근이 복소수      -> 부족감쇠, 진동하며 수렴
%      b^2 = 4mk  (zeta = 1) : 근이 중근(실수)  -> 임계감쇠, 진동 없이 가장 빠르게
%      b^2 > 4mk  (zeta > 1) : 근이 서로 다른 실수 -> 과감쇠, 진동 없지만 느리게
%
%  b 를 0 부터 조금씩 키우면서 극점이 그리는 자취를 따라가 봅시다.
%
%  힌트: 지금 하는 이 작업이 사실 6주차에 배울 "근궤적(root locus)" 입니다.
%        거기서는 b 대신 제어이득 K 를 바꾸는 것만 다릅니다.

b_sweep = linspace(0, 4, 400);
poles_sweep = zeros(2, numel(b_sweep));
for i = 1:numel(b_sweep)
    poles_sweep(:,i) = roots([m b_sweep(i) k]);
end

b_crit = 2*sqrt(m*k);      % 임계감쇠가 되는 b

figure('Name','댐퍼에 따른 극점 이동');
plot(real(poles_sweep(1,:)), imag(poles_sweep(1,:)), '.', 'MarkerSize', 8); hold on;
plot(real(poles_sweep(2,:)), imag(poles_sweep(2,:)), '.', 'MarkerSize', 8);

% 대표적인 네 지점 표시
b_marks = [0.2 1.0 b_crit 3.0];
for bm = b_marks
    pm = roots([m bm k]);
    plot(real(pm), imag(pm), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
    text(real(pm(1))+0.05, imag(pm(1))+0.08, sprintf('b=%.1f', bm), 'FontSize', 9);
end
xline(0, 'k-', 'LineWidth', 1.5); yline(0, 'k:', 'LineWidth', 0.5);
grid on; axis equal;
xlabel('Real'); ylabel('Imag');
title('b 를 0 에서 4 까지 키울 때 극점이 움직이는 길');
xlim([-4 0.5]); ylim([-1.5 1.5]);

fprintf('\n=== 5단계. 극점의 이동 ===\n');
fprintf('  임계감쇠가 되는 b = 2*sqrt(m*k) = %.2f\n', b_crit);
fprintf('  b = 0    : 극점이 허수축 위 (+-j%.2f). 영원히 진동합니다.\n', wn);
fprintf('  b 증가   : 반지름 %.2f 인 원을 따라 왼쪽으로 이동합니다.\n', wn);
fprintf('             (원 위에 있는 동안 wn 은 그대로, zeta 만 커집니다)\n');
fprintf('  b = %.2f : 두 극점이 s = %.2f 에서 만납니다 (임계감쇠).\n', b_crit, -b_crit/(2*m));
fprintf('  b > %.2f : 실축 위에서 좌우로 갈라집니다. 하나는 원점 쪽으로 다시\n', b_crit);
fprintf('             돌아오는데, 이 느린 극점 때문에 과감쇠는 오히려 느려집니다.\n\n');

%% 5-1. 네 가지 감쇠 상태의 응답 비교
%
%  위 그림의 네 지점이 실제로 어떤 응답을 만드는지 봅니다.

t = 0:0.01:30;
labels = {'부족감쇠', '부족감쇠', '임계감쇠', '과감쇠'};

figure('Name','감쇠 상태별 계단응답');
for i = 1:numel(b_marks)
    bi = b_marks(i);
    Gi = 1/(m*s^2 + bi*s + k);
    zi = bi/(2*sqrt(m*k));
    plot(t, step(Gi, t), 'LineWidth', 2); hold on;
end
yline(1/k, 'k--', 'LineWidth', 1.5); grid on;
xlabel('Time [s]'); ylabel('x [m]');
title('댐퍼 값에 따른 계단응답');
legend(arrayfun(@(i) sprintf('b=%.1f (zeta=%.2f, %s)', b_marks(i), ...
       b_marks(i)/(2*sqrt(m*k)), labels{i}), 1:numel(b_marks), ...
       'UniformOutput', false), 'Location','southeast');

fprintf('=== 감쇠 상태별 특성 ===\n');
for i = 1:numel(b_marks)
    bi = b_marks(i);
    Gi = 1/(m*s^2 + bi*s + k);
    info = stepinfo(Gi);
    fprintf('  b=%.1f (zeta=%.2f, %-8s) : 오버슈트 %5.1f %%,  정착시간 %5.1f s\n', ...
            bi, bi/(2*sqrt(m*k)), labels{i}, info.Overshoot, info.SettlingTime);
end
fprintf('  --> 임계감쇠(zeta=1)가 "진동 없이 가장 빠른" 지점입니다.\n');
fprintf('      더 감쇠를 키우면 진동은 여전히 없지만 오히려 느려집니다.\n\n');

%% 6. 정리 : 물리에서 전달함수까지
%
%      물리 법칙 (뉴턴 법칙, 키르히호프 법칙 등)
%            |
%            v
%      미분방정식              <- 여기까지가 동역학
%            |  라플라스 변환 (초기조건 0)
%            v
%      전달함수 G(s)           <- 여기부터가 제어공학
%            |
%            v
%      극점/영점 -> 응답 예측, 안정도 판정, 제어기 설계
%
%  이 길은 어떤 시스템이든 똑같습니다. RC 회로든, DC 모터든, 배의 조종이든
%  1단계의 물리 법칙만 바뀔 뿐 나머지는 완전히 같은 절차입니다.
%  5주차부터 쓸 DC 모터도 이 절차로 유도합니다.

%% 7. 전달함수의 한계 : 초기조건은 어디로 갔는가
%
%  전달함수를 만들 때 우리는 초기조건을 0 으로 두고 버렸습니다.
%  그러면 이런 상황은 어떻게 표현할까요?
%
%      "물체를 0.5 m 당겨 놓고 힘을 전혀 주지 않은 채 놓았다"
%
%  입력 F 가 0 이므로 전달함수로는 X(s) = G(s)*0 = 0 입니다.
%  즉 "아무 일도 안 일어난다"고 답합니다. 명백히 틀렸습니다.
%  실제로는 놓는 순간 진동하며 돌아옵니다.
%
%  전달함수는 입력과 출력의 관계만 담습니다. 시스템 내부가 지금 어떤 상태인지는
%  담지 못합니다. 그래서 필요한 것이 상태공간(state-space) 표현입니다.
%
%  아래에서 상태공간으로 같은 상황을 풀어 봅니다. 자세한 내용은 3주차에서 다룹니다.

A = [0 1; -k/m -b/m];
B = [0; 1/m];
C = [1 0];
D = 0;
sys_ss = ss(A, B, C, D);

x0 = [0.5; 0];                 % 0.5 m 당겨 놓고, 속도는 0 인 상태에서 놓기
t7 = 0:0.01:40;

figure('Name','초기조건 응답');
plot(t7, initial(sys_ss, x0, t7), 'LineWidth', 2); hold on;
plot(t7, step(G, t7)*0, 'k--', 'LineWidth', 2);
yline(0, 'k:'); grid on;
xlabel('Time [s]'); ylabel('x [m]');
title('0.5 m 당겨 놓고 놓았을 때 (입력 F = 0)');
legend('상태공간 (initial)', '전달함수의 답 (항상 0)', 'Location','northeast');

fprintf('=== 7단계. 전달함수가 못 하는 것 ===\n');
fprintf('  전달함수의 답 : x(t) = 0  (입력이 0 이므로)\n');
fprintf('  실제           : 0.5 m 에서 시작해 진동하며 0 으로 수렴\n');
fprintf('  --> 초기조건을 다루려면 상태공간 표현이 필요합니다. 3주차 주제입니다.\n\n');

%% 8. 다음 실습
%
%  W02_03_run_simulink.m
%    같은 MSD 시스템을 Simulink 에서 세 가지 방법으로 만들어 봅니다.
%      (1) 적분기 두 개로 미분방정식을 그대로 구성
%      (2) Transfer Fcn 블록
%      (3) State-Space 블록
%    셋의 응답이 완전히 겹치는 것을 확인하면, "미분방정식 = 전달함수 = 상태공간"
%    이라는 말이 비로소 실감이 납니다.
