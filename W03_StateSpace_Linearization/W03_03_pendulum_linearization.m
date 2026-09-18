%% W03_03_pendulum_linearization.m
%  3주차 실습 (3) : 선형화 - 굽은 것을 곧게 펴서 쓰기
%
%  이번 실습이 학기 전반부에서 가장 중요합니다.
%
%  한 줄 요약:
%      세상은 굽어 있는데(비선형) 우리 도구는 곧은 것(선형)만 다룹니다.
%      그래서 관심 있는 지점 근처만 곧게 펴서 씁니다. 이게 선형화입니다.
%
%  대응하는 강의노트 : W03_LectureNote.mlx
%  대응하는 Simulink : W03_Pendulum_NonlinVsLin.slx
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

%% 1. 무엇이 문제인가
%
%  지금까지 배운 것을 떠올려 봅시다.
%      전달함수, 극점, 블록선도, 상태공간...
%  이 도구들은 전부 "선형 시스템"에서만 통합니다.
%
%  그런데 선형이란 게 뭘까요? 아주 간단합니다.
%
%      입력을 2배 넣으면 출력도 정확히 2배가 나온다.
%
%  이게 전부입니다. 그런데 현실은 이렇지 않습니다.
%      - 자동차 액셀을 2배 밟는다고 속도가 2배가 되지 않습니다.
%      - 진자를 2배 기울인다고 되돌아오는 힘이 2배가 되지 않습니다.
%
%  현실은 거의 다 비선형입니다. 그럼 우리가 배운 게 다 쓸모없을까요?
%  아닙니다. 요령이 있습니다.

%% 2. 아이디어 : 좁게 보면 곡선도 직선이다
%
%  지구는 둥급니다. 그런데 동네 지도는 평평하게 그립니다.
%  왜 문제가 안 될까요? 동네는 좁으니까요.
%
%  세계지도를 평평하게 그리면 그린란드가 아프리카만 해집니다. 크게 틀립니다.
%  하지만 우리 동네 정도면 평평하다고 해도 거의 안 틀립니다.
%
%  선형화가 정확히 이겁니다.
%
%      곡선 전체를 직선으로 바꾸는 게 아니라,
%      우리가 관심 있는 한 점 근처만 직선으로 바꿉니다.
%
%  그 점을 동작점(operating point) 또는 평형점이라고 부릅니다.
%
%  아래 그림에서 확인해 봅시다.

x = -2:0.01:2;

figure('Name','곡선을 한 점에서 직선으로');
h1 = plot(x, sin(x), 'LineWidth', 3); hold on;
h2 = plot(x, x, '--', 'LineWidth', 2);
plot(0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor','k');
grid on; ylim([-1.5 1.5]);
xlabel('x [rad]'); ylabel('값');
title('sin(x) 와 직선 x : 원점 근처에서는 거의 같다');
legend([h1 h2], {'sin(x)  (진짜 곡선)', 'x  (직선 근사)'}, 'Location','southeast');

%% 3. 얼마나 좁아야 "좁은" 건가
%
%  말로만 하면 감이 안 오니 숫자로 봅시다.
%  각도별로 sin(θ) 와 θ 가 몇 퍼센트나 차이 나는지 계산합니다.

deg_list = [1 5 10 20 30 45 60 90];

fprintf('=== sin(θ) 를 θ 로 바꿔도 되는가 ===\n');
fprintf('   각도    sin(θ)      θ       오차\n');
fprintf('  ------  --------  --------  -------\n');
for dg = deg_list
    th  = deg2rad(dg);
    err = abs(th - sin(th)) / sin(th) * 100;
    fprintf('  %4d도   %.4f    %.4f    %5.1f %%\n', dg, sin(th), th, err);
end
fprintf('\n');
fprintf('  읽는 법:\n');
fprintf('    10도까지는 오차 0.5%% 입니다. 아무 문제 없습니다.\n');
fprintf('    30도가 되면 5%% 틀립니다. 슬슬 신경 쓰입니다.\n');
fprintf('    60도면 21%% 틀립니다. 이제 못 씁니다.\n\n');
fprintf('  결론: 선형화한 모델은 동작점 근처에서만 믿을 수 있습니다.\n');
fprintf('        얼마나 근처까지 믿을지는 시스템마다 다르니 확인해야 합니다.\n\n');

%% 4. 실제 예 : 진자
%
%  줄 끝에 추가 달린 진자입니다. θ 는 아래쪽 수직에서 잰 각도입니다.
%  즉 가만히 매달려 있으면 θ = 0 입니다.
%
%  운동방정식은 이렇습니다. (강의자료 3_Modeling.pptx 의 Example 3-27 과 같습니다)
%
%      (관성) x (각가속도) = (넣어 준 토크) - (감쇠) - (중력이 되돌리는 토크)
%
%      m*l^2 * θ'' = u - b*θ' - m*g*l*sin(θ)
%                                        ^^^^^^^^
%                                        여기 sin 이 있어서 비선형입니다
%
%  이 sin(θ) 하나 때문에 우리가 배운 도구를 못 씁니다.
%  θ 가 작다고 가정하고 sin(θ) 를 θ 로 바꾸면 선형이 됩니다.
%
%      m*l^2 * θ'' = u - b*θ' - m*g*l*θ        <- 이제 선형!
%
%  이걸 상태공간으로 적으면 (상태는 각도와 각속도, 두 개)
%
%      A = [        0             1     ]
%          [ -m*g*l*cos(θ0)/J   -b/J   ]
%
%  cos(θ0) 가 들어가는 것은 어느 점에서 폈느냐에 따라 기울기가 다르기 때문입니다.
%  θ0 = 0 (매달린 상태)에서는 cos(0) = 1 입니다.

[sysLin, p] = plant_pendulum(0);        % θ0 = 0 에서 선형화

fprintf('=== 진자 파라미터 ===\n');
fprintf('  질량 %.1f kg, 길이 %.1f m, 감쇠 %.1f\n', p.m, p.l, p.b);
fprintf('  동작점 θ0 = %.0f도 (아래로 매달린 상태)\n\n', rad2deg(p.theta0));
fprintf('  선형 모델의 A 행렬 =\n'); disp(p.A);
fprintf('  A 의 고유값 : ');
ev = eig(p.A); fprintf('%+.3f%+.3fj  ', [real(ev).'; imag(ev).']); fprintf('\n');
fprintf('  실수부가 0 입니다. 감쇠가 없어서 영원히 흔들린다는 뜻입니다.\n');
fprintf('  (2주차에서 본 "극점이 허수축 위" 상황과 같습니다)\n\n');

%% 5. 작은 각도로 흔들어 보기 : 잘 맞는다
%
%  이제 진짜 비선형 진자와 선형 근사 모델을 나란히 돌려 봅시다.
%  먼저 작은 각도, 5도에서 놓아 봅니다.
%
%  ode45 는 미분방정식을 수치적으로 풀어 주는 MATLAB 명령입니다.
%  비선형이든 뭐든 상관없이 풀어 줍니다.

t_end = 10;
theta_small = deg2rad(5);

% 비선형 (진짜)
[t_n, x_n] = ode45(@(t,x) p.f(x, 0), [0 t_end], [theta_small; 0]);

% 선형 (근사)
t_l = linspace(0, t_end, 1000)';   % 열벡터로 만들어야 아래 뺄셈이 제대로 됩니다
y_l = initial(sysLin, [theta_small; 0], t_l);

figure('Name','작은 각도 5도');
h1 = plot(t_n, rad2deg(x_n(:,1)), 'LineWidth', 3); hold on;
h2 = plot(t_l, rad2deg(y_l), '--', 'LineWidth', 2);
yline(0,'k:'); grid on;
xlabel('시간 [s]'); ylabel('각도 [도]');
title('5도에서 놓았을 때 : 두 선이 거의 겹친다');
legend([h1 h2], {'비선형 (진짜)', '선형 근사'}, 'Location','northeast');

% 얼마나 차이 나는지 숫자로
y_n_i = interp1(t_n, x_n(:,1), t_l);
fprintf('=== 5도에서 놓았을 때 ===\n');
fprintf('  두 모델의 최대 차이 : %.2f 도\n', rad2deg(max(abs(y_n_i - y_l))));
fprintf('  --> 거의 안 틀립니다. 선형 모델을 써도 됩니다.\n\n');

%% 6. 큰 각도로 흔들어 보기 : 어긋난다
%
%  이번엔 60도에서 놓아 봅니다.
%  3절의 표에서 60도면 21% 틀린다고 했습니다. 결과가 어떨까요?

theta_big = deg2rad(60);

[t_n2, x_n2] = ode45(@(t,x) p.f(x, 0), [0 t_end], [theta_big; 0]);
y_l2 = initial(sysLin, [theta_big; 0], t_l);

figure('Name','큰 각도 60도');
h1 = plot(t_n2, rad2deg(x_n2(:,1)), 'LineWidth', 3); hold on;
h2 = plot(t_l, rad2deg(y_l2), '--', 'LineWidth', 2);
yline(0,'k:'); grid on;
xlabel('시간 [s]'); ylabel('각도 [도]');
title('60도에서 놓았을 때 : 시간이 갈수록 어긋난다');
legend([h1 h2], {'비선형 (진짜)', '선형 근사'}, 'Location','northeast');

y_n2_i = interp1(t_n2, x_n2(:,1), t_l);
fprintf('=== 60도에서 놓았을 때 ===\n');
fprintf('  두 모델의 최대 차이 : %.1f 도\n', rad2deg(max(abs(y_n2_i - y_l2))));
fprintf('  --> 많이 틀립니다.\n\n');
fprintf('  왜 이렇게 벌어지나요?\n');
fprintf('    진짜 진자는 크게 흔들수록 한 번 왕복하는 시간이 길어집니다.\n');
fprintf('    선형 모델은 각도와 상관없이 항상 같은 주기라고 봅니다.\n');
fprintf('    그래서 시간이 갈수록 박자가 어긋나고, 결국 완전히 딴 소리를 합니다.\n\n');

%% 7. 같은 진자, 다른 자리 : 거꾸로 세우면
%
%  여기가 오늘의 하이라이트입니다.
%
%  진자를 거꾸로 세워 봅시다. θ = 180도 입니다.
%  손을 떼지 않으면 그 자세로 가만히 있습니다. 즉 여기도 평형점입니다.
%
%  물리적으로는 완전히 같은 진자입니다. 방정식도 그대로입니다.
%  그런데 이 자리에서 선형화하면 전혀 다른 모델이 나옵니다.
%
%  이유는 A 행렬의 cos(θ0) 입니다.
%      θ0 = 0   이면 cos = +1  ->  중력이 되돌린다   -> 안정
%      θ0 = 180 이면 cos = -1  ->  중력이 넘어뜨린다 -> 불안정
%
%  부호 하나가 뒤집히면서 시스템의 성격이 정반대가 됩니다.

[sysUp, pUp] = plant_pendulum(pi);      % θ0 = 180도 에서 선형화

fprintf('=== 매달린 자세 vs 거꾸로 선 자세 ===\n');
fprintf('  매달린 자세  A(2,1) = %+.2f  -> 고유값 %s\n', ...
        p.A(2,1), mat2str(round(eig(p.A),2)));
fprintf('  거꾸로 자세  A(2,1) = %+.2f  -> 고유값 %s\n', ...
        pUp.A(2,1), mat2str(round(eig(pUp.A),2)));
fprintf('\n');
fprintf('  거꾸로 선 쪽은 고유값 하나가 양수(+%.2f)입니다.\n', max(real(eig(pUp.A))));
fprintf('  2주차에서 배웠듯이 양수 고유값은 발산을 뜻합니다.\n');
fprintf('  즉 조금만 기울어도 그대로 넘어간다는 것입니다. 당연한 결과지요.\n\n');

% 거꾸로 세워 놓고 1도만 기울여 보기
t_u_lin = linspace(0, 3, 500)';
[t_u, x_u] = ode45(@(t,x) p.f(x, 0), [0 3], [pi - deg2rad(1); 0]);
y_u = initial(sysUp, [-deg2rad(1); 0], t_u_lin);

figure('Name','거꾸로 선 진자');
h1 = plot(t_u, rad2deg(x_u(:,1) - pi), 'LineWidth', 3); hold on;
h2 = plot(t_u_lin, rad2deg(y_u), '--', 'LineWidth', 2);
yline(0,'k:'); grid on;
xlabel('시간 [s]'); ylabel('수직에서 벗어난 각도 [도]');
title('거꾸로 세워 놓고 1도만 기울였을 때 : 그대로 넘어간다');
legend([h1 h2], {'비선형 (진짜)', '선형 근사'}, 'Location','southwest');

fprintf('  그림을 보면 처음 한동안은 두 선이 잘 겹칩니다.\n');
fprintf('  아직 각도가 작아서 선형 근사가 통하는 구간입니다.\n');
fprintf('  많이 넘어간 뒤부터는 갈라집니다. 근사가 깨진 것입니다.\n\n');

%% 8. 정리
%
%  1) 세상은 비선형인데 우리 도구는 선형용입니다.
%     그래서 관심 있는 점 근처만 곧게 펴서(선형화) 씁니다.
%
%  2) 진자에서는 sin(θ) 를 θ 로 바꾸는 것이 선형화입니다.
%     10도 이내면 거의 안 틀리고, 60도쯤 되면 못 씁니다.
%
%  3) 선형 모델은 동작점 근처에서만 믿을 수 있습니다.
%     제어기를 설계했으면 반드시 원래 비선형 모델로 검증해야 합니다.
%     이게 실무에서 사고를 막는 습관입니다.
%
%  4) 같은 시스템이라도 어느 점에서 폈느냐에 따라 전혀 다른 모델이 나옵니다.
%     진자를 매달면 안정, 거꾸로 세우면 불안정입니다.
%
%  5) 12~14주차에서는 이 "거꾸로 선 진자"를 넘어지지 않게 잡는 제어기를
%     직접 설계합니다. 오늘 만든 선형 모델이 그때 재료가 됩니다.
%
%  다음 실습 : W03_04_run_simulink.m
%              같은 실험을 Simulink 에서 해 봅니다.
%              비선형 블록과 선형 블록을 나란히 놓고 돌려서
%              각도를 키울 때 두 선이 벌어지는 것을 직접 확인합니다.
