%% W03_04_run_simulink.m
%  3주차 실습 (4) : Simulink 에서 비선형과 선형을 나란히 돌려 보기
%
%  모델 W03_Pendulum_NonlinVsLin.slx 를 열어 보십시오.
%
%      >> open_system('W03_Pendulum_NonlinVsLin')
%
%  위아래 두 경로가 블록 구성이 완전히 똑같습니다.
%  딱 하나, 위쪽에만 sin 블록이 있습니다.
%
%      위쪽 (진짜 진자) : 중력 토크 = m*g*l*sin(각도)
%      아래쪽 (선형 근사): 중력 토크 = m*g*l*각도
%
%  즉 선형화란 이 sin 블록을 떼어내는 일입니다. 그게 전부입니다.
%  각도를 키워 가며 두 결과가 언제부터 갈라지는지 확인해 봅시다.
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

model = 'W03_Pendulum_NonlinVsLin';

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
%  모델 블록에는 숫자가 아니라 변수 이름이 적혀 있으므로
%  실행 전에 이 변수들을 만들어 두어야 합니다.

[~, p] = plant_pendulum(0);       % 매달린 자세에서 선형화한 진자

m = p.m;    % 추 질량 [kg]
l = p.l;    % 막대 길이 [m]
b = p.b;    % 감쇠계수
g = p.g;    % 중력가속도 [m/s^2]

u_torque = 0;      % 토크는 주지 않습니다. 그냥 놓기만 합니다.
t_end    = 10;     % 시뮬레이션 시간 [s]

fprintf('=== 진자 파라미터 ===\n');
fprintf('  질량 %.1f kg, 길이 %.1f m, 감쇠 %.1f\n\n', m, l, b);

%% 2. 여러 각도로 놓아 보기
%
%  5도, 20도, 60도, 100도 에서 각각 놓아 보고
%  비선형과 선형이 얼마나 벌어지는지 봅니다.

angle_list = [5 20 60 100];

figure('Name','각도별 비선형 vs 선형');
tiledlayout(2, 2, 'TileSpacing','compact');

fprintf('=== 각도별 비교 ===\n');
fprintf('  놓은 각도   최대 차이   판정\n');
fprintf('  ---------  ---------  ----------------\n');

for i = 1:numel(angle_list)
    theta0 = deg2rad(angle_list(i));       % <- 모델의 적분기 초기값으로 들어갑니다

    out = sim(model);

    % 두 결과를 같은 시간 격자로 옮겨서 비교
    t = (0:0.01:t_end)';
    y_nl  = interp1(out.theta_nl.Time,  squeeze(out.theta_nl.Data),  t);
    y_lin = interp1(out.theta_lin.Time, squeeze(out.theta_lin.Data), t);

    err_deg = rad2deg(max(abs(y_nl - y_lin)));

    if     err_deg < 1,   verdict = '거의 같음 (써도 됨)';
    elseif err_deg < 10,  verdict = '조금 다름';
    else,                 verdict = '많이 다름 (못 씀)';
    end
    fprintf('  %5d도     %6.1f도    %s\n', angle_list(i), err_deg, verdict);

    nexttile
    plot(t, rad2deg(y_nl),  'LineWidth', 2.5); hold on;
    plot(t, rad2deg(y_lin), '--', 'LineWidth', 2);
    yline(0, 'k:'); grid on;
    title(sprintf('%d도에서 놓았을 때 (차이 %.1f도)', angle_list(i), err_deg));
    if i > 2, xlabel('시간 [s]'); end
    if mod(i,2) == 1, ylabel('각도 [도]'); end
    if i == 1, legend('비선형 (진짜)', '선형 근사', 'Location','southeast'); end
end
fprintf('\n');

%% 3. 결과를 어떻게 읽을 것인가
%
%  5도  : 두 선이 겹쳐서 하나로 보입니다. 선형 모델을 마음 놓고 써도 됩니다.
%  20도 : 아직 비슷하지만 뒤로 갈수록 살짝 어긋납니다.
%  60도 : 확실히 벌어집니다. 주기가 눈에 띄게 다릅니다.
%  100도: 완전히 딴 소리를 합니다.
%
%  왜 이렇게 되는가:
%      진짜 진자는 크게 흔들수록 한 번 왕복하는 시간이 길어집니다.
%      크게 벌어진 지점에서는 중력이 되돌리는 힘이 생각만큼 크지 않기 때문입니다.
%      (sin(60도) = 0.87 로, 60도(=1.05 라디안)보다 한참 작습니다)
%
%      선형 모델은 이걸 모릅니다. 각도가 얼마든 항상 같은 주기라고 봅니다.
%      그래서 시간이 갈수록 박자가 어긋나고 결국 완전히 갈라집니다.

%% 4. 이것이 실무에서 뜻하는 것
%
%  선형 모델로 제어기를 설계했다고 합시다.
%  그 제어기는 "각도가 작게 유지되는 동안"만 제대로 동작합니다.
%
%  그래서 실무 순서는 항상 이렇습니다.
%
%      1) 비선형 모델을 만든다
%      2) 동작점 근처에서 선형화한다
%      3) 선형 모델로 제어기를 설계한다   <- 여기서 우리가 배운 도구를 씁니다
%      4) 설계한 제어기를 다시 비선형 모델에 붙여서 검증한다   <- 절대 빼먹지 말 것
%
%  4번을 빼먹으면 시뮬레이션에서는 멀쩡한데 실제로는 터지는 일이 생깁니다.
%  이 모델처럼 비선형과 선형을 나란히 놓고 확인하는 습관이 그래서 중요합니다.

%% 5. 직접 해 볼 것
%
%   (1) angle_list 에 150 을 넣어 보십시오.
%       -> 진짜 진자는 거의 한 바퀴 돌 뻔하고, 선형 모델은 딴 세상 이야기를 합니다.
%
%   (2) b = 0.05 로 감쇠를 넣어 보십시오.
%       -> 둘 다 진동이 잦아듭니다. 그런데도 초반 차이는 그대로입니다.
%          감쇠는 비선형성을 없애 주지 않습니다.
%
%   (3) 모델을 열고 위쪽의 sin 블록을 지운 뒤 선으로 이어 보십시오.
%       -> 두 경로가 완전히 같아져서 각도를 아무리 키워도 겹칩니다.
%          sin 블록 하나가 전부였다는 것을 확인하는 실험입니다.
%
%   (4) 반대로 아래쪽 경로에 sin 블록을 추가하면?
%       -> 이번엔 두 경로가 둘 다 비선형이 되어 항상 겹칩니다.
%
%  모델 열기:
%      >> open_system('W03_Pendulum_NonlinVsLin')
