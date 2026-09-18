%% W01_01_open_vs_closed.m
%  1주차 실습 (1) : 개루프 제어와 폐루프 제어는 무엇이 다른가
%
%  이 스크립트에서 답할 질문
%    Q1. 개루프 제어로도 목표값을 정확히 맞출 수 있는가?      -> 2절
%    Q2. 폐루프(비례제어)는 오히려 오차가 크던데?             -> 3절
%    Q3. 그 오차를 없애면 개루프와 폐루프는 똑같아지는가?     -> 4절
%    Q4. 그렇다면 도대체 왜 피드백을 쓰는가?                  -> 5절 (결정적 장면)
%
%  대응하는 강의노트 : W01_LectureNote.mlx
%  대응하는 Simulink : W01_OpenClosed.slx (W01_03_run_simulink.m 로 실행)
%
%  [명령어 사용법이 궁금하면]
%  이 스크립트에 나오는 tf, step, dcgain, feedback, stepinfo, lsim 의
%  원리와 입출력은 W01_LectureNote.mlx 의 1부에 자세히 정리해 두었습니다.
%  각 명령이 무엇을 계산하는지, 무엇을 넣으면 무엇이 나오는지,
%  흔히 하는 실수는 무엇인지를 예제와 함께 설명합니다.
%  MATLAB 안에서 help 로도 볼 수 있습니다.  예:  help feedback
%
%  제어시스템설계 1주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 제어 대상(플랜트) 정의 : 질량-스프링-댐퍼
%
%  질량 m 에 스프링 k 와 댐퍼 b 가 붙어 있습니다.
%  우리는 힘 F 를 넣어서 변위 x 를 원하는 값으로 만들고 싶습니다.
%
%      m*x'' + b*x' + k*x = F     ->     G(s) = X(s)/F(s) = 1/(m*s^2+b*s+k)
%
%  왜 이 시스템을 고르는가: 세상에서 가장 흔한 2차 시스템입니다.
%  자동차 서스펜션, 건물의 흔들림, 로봇 관절의 탄성이 전부 이 꼴입니다.

[G, p] = plant_msd();          % 기본값 m=1, b=0.2, k=1

fprintf('=== 플랜트 정보 ===\n');
fprintf('  m = %.2f kg,  b = %.2f N*s/m,  k = %.2f N/m\n', p.m, p.b, p.k);
fprintf('  고유진동수 wn   = %.3f rad/s\n', p.wn);
fprintf('  감쇠비     zeta = %.3f  (0.1 로 작아서 진동이 오래 남습니다)\n', p.zeta);
fprintf('  DC 이득 G(0)    = %.3f  (1 N 을 계속 주면 %.3f m 밀려서 멈춥니다)\n\n', ...
        dcgain(G), dcgain(G));

t = 0:0.01:100;                 % 시뮬레이션 시간 [s]
r = 1;                         % 목표 변위 1 m

%% 2. 개루프 제어 : 되먹임 없이, 미리 계산해서 넣기
%
%  개루프 제어의 아이디어는 단순합니다.
%  "출력이 얼마가 될지 내가 이미 아니까, 역으로 계산해서 넣자."
%
%  정상상태에서 출력은 y_ss = G(0)*u 이므로,
%  y_ss = r 이 되게 하려면 u = r/G(0) 를 넣으면 됩니다.
%  이 상수를 피드포워드 이득(feedforward gain) Kff 라고 부릅니다.
%
%  중요: 이 계산은 G(0) 를 정확히 안다는 가정 위에 서 있습니다.

Kff = 1 / dcgain(G);           % = k = 1.0

sys_open = Kff * G;                        % 개루프 : r -> y
y_open   = step(r * sys_open, t);

fprintf('=== 2절. 개루프 제어 ===\n');
fprintf('  피드포워드 이득 Kff = %.3f\n', Kff);
fprintf('  정상상태 출력       = %.4f m   (목표 %.1f m)\n', y_open(end), r);
fprintf('  --> 모델이 정확하면 개루프도 목표값에 정확히 도달합니다.\n');
fprintf('      즉 "피드백이 없으면 오차가 난다"는 말은 사실이 아닙니다.\n\n');

figure()
h1 = plot(t, y_open, 'LineWidth', 2); hold on;
h2 = yline(r, 'k--', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('Displacement x [m]');
title('2절. 개루프 제어 : 모델이 정확하면 목표값에 정확히 도달한다');
legend([h1 h2], {'개루프 출력', '목표값 r'}, 'Location', 'southeast');
ylim([0 2]);

%% 3. 폐루프 비례제어(P control) : 오차를 보고 힘을 조절하기
%
%  폐루프 제어는 매 순간 출력을 재서 오차를 계산하고,
%  그 오차에 비례하는 힘을 넣습니다.
%
%      e(t) = r - y(t)          <- 오차
%      u(t) = K * e(t)          <- 오차에 비례하는 제어입력
%
%  폐루프 전달함수는 feedback 명령으로 구합니다.
%
%      T(s) = K*G(s) / (1 + K*G(s))
%
%  정상상태 출력은 T(0) = K*G(0)/(1+K*G(0)) = K/(1+K) 입니다.
%  K 가 클수록 1 에 가까워지지만, 절대로 1 이 되지는 못합니다.
%
%  왜 오차가 남는가 (직관):
%     비례제어는 오차가 있어야만 힘을 냅니다. 오차가 0 이 되면 힘도 0 이 되는데,
%     이 플랜트는 스프링이 있어서 힘이 0 이면 원점으로 되돌아옵니다.
%     즉 "오차가 조금 남아 있어야" 스프링을 버틸 힘이 나옵니다.

K_list = [1 3 9];
colors = lines(numel(K_list));
hP = gobjects(1, numel(K_list));

figure()
fprintf('=== 3절. 폐루프 비례제어 ===\n');
for i = 1:numel(K_list)
    K = K_list(i);

    T = feedback(K*G, 1);              % 폐루프 전달함수
    y = step(r*T, t);

    hP(i) = plot(t, y, 'LineWidth', 2, 'Color', colors(i,:)); hold on;

    info = stepinfo(r*T);
    fprintf('  K = %d :  정상상태 %.4f (이론 %.4f),  오차 %5.1f %%,  오버슈트 %5.1f %%\n', ...
            K, y(end), K/(1+K), 100*(r-y(end))/r, info.Overshoot);
end
hR = yline(r, 'k--', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('Displacement x [m]');
title('3절. 비례제어 : K 를 키우면 오차는 줄지만 진동이 심해진다');
legend([hP hR], [arrayfun(@(K) sprintf('K = %d', K), K_list, 'UniformOutput', false), ...
       {'목표값 r'}], 'Location', 'southeast');
ylim([0 2]);

fprintf('  --> K 를 키우면 오차는 줄지만 오버슈트가 커집니다. 공짜가 없습니다.\n');
fprintf('  --> 여기까지만 보면 개루프가 더 좋아 보입니다. 4절에서 조건을 맞춰 줍니다.\n\n');

%% 4. 공정한 비교를 위해 : 폐루프에도 기준입력 스케일링을 붙이자
%
%  3절의 비교는 사실 불공정했습니다.
%  개루프에는 Kff 라는 보정 상수를 붙여 줬는데 폐루프에는 아무것도 안 붙였으니까요.
%
%  폐루프에도 똑같이 상수를 하나 곱해 정상상태를 맞춰 줍시다.
%
%      Kr = 1 / T(0) = (1+K)/K
%
%  이렇게 하면 폐루프도 정상상태 오차가 0 이 됩니다.
%  (13주차 상태궤환에서 똑같은 아이디어를 Kr 이라는 이름으로 다시 만납니다.)

K  = 9;
T  = feedback(K*G, 1);
Kr = 1 / dcgain(T);                        % 기준입력 스케일링 상수

y_close = step(r*Kr*T, t);

fprintf('=== 4절. 기준입력 스케일링을 붙인 폐루프 ===\n');
fprintf('  K = %d,  Kr = %.4f\n', K, Kr);
fprintf('  정상상태 출력 = %.4f m  --> 개루프와 마찬가지로 오차가 없습니다.\n\n', y_close(end));

figure()
h1 = plot(t, y_open,  'LineWidth', 2); hold on;
h2 = plot(t, y_close, 'LineWidth', 2);
h3 = yline(r, 'k--', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('Displacement x [m]');
title('4절. 조건을 맞추면 정상상태는 개루프나 폐루프나 똑같다');
legend([h1 h2 h3], {'개루프 (Kff)', sprintf('폐루프 (K=%d, Kr=%.2f)', K, Kr), '목표값 r'}, ...
       'Location', 'southeast');
ylim([0 2]);

%% 5. 결정적 장면 : 외란(disturbance)이 들어오면
%
%  4절까지 보면 개루프와 폐루프는 무승부입니다.
%  이제 현실을 넣어 봅시다.
%
%  현실에는 우리가 모르는 힘이 끼어듭니다.
%  바람, 마찰, 누가 툭 미는 힘 같은 것들입니다. 이것을 외란 d 라고 하고,
%  보통 플랜트 입력단에 더해집니다.
%
%      실제 플랜트 입력 = u + d
%
%  이때 출력은 각각 이렇게 됩니다.
%
%    개루프 :  y = G*(Kff*r) + G*d
%              두 번째 항이 그대로 살아 있습니다. 외란이 통째로 출력에 나타납니다.
%
%    폐루프 :  y = Kr*(K*G/(1+K*G))*r + (G/(1+K*G))*d
%              두 번째 항의 분모에 (1+K*G) 가 있습니다.
%              즉 외란의 영향이 (1+K*G) 배만큼 줄어듭니다.
%
%  개루프가 외란을 못 잡는 이유는 단순합니다. 출력을 보지 않으니
%  외란이 들어왔는지조차 모르기 때문입니다.

d   = 0.5;                      % 외란 크기 [N]
t_d = 40;                       % 외란이 들어오는 시각 [s]

u_ref = r * ones(size(t));      % 목표값 신호
u_dis = d * (t >= t_d);         % 외란 신호 (t_d 이후 계속 작용)

% --- 개루프 응답 : 중첩의 원리로 두 입력의 응답을 더합니다 ---
y_open_d  = lsim(Kff*G, u_ref, t) + lsim(G, u_dis, t);

% --- 폐루프 응답 ---
T_r = Kr * feedback(K*G, 1);    % 목표값 -> 출력
T_d = feedback(G, K);           % 외란   -> 출력   ( = G/(1+K*G) )
y_close_d = lsim(T_r, u_ref, t) + lsim(T_d, u_dis, t);

figure()
h1 = plot(t, y_open_d,  'LineWidth', 2); hold on;
h2 = plot(t, y_close_d, 'LineWidth', 2);
h3 = yline(r, 'k--', 'LineWidth', 1.5);
h4 = xline(t_d, 'r:', 'LineWidth', 2);
grid on;
xlabel('Time [s]'); ylabel('Displacement x [m]');
title(sprintf('5절. 외란 d = %.1f N 이 t = %d s 에 들어왔을 때', d, t_d));
legend([h1 h2 h3 h4], {'개루프', sprintf('폐루프 (K = %d)', K), '목표값 r', '외란 유입'}, ...
       'Location', 'southeast');
ylim([0 2]);

e_open  = r - y_open_d(end);
e_close = r - y_close_d(end);

fprintf('=== 5절. 외란이 들어온 뒤의 정상상태 ===\n');
fprintf('  개루프 : %.4f m   (오차 %+.4f m)\n', y_open_d(end),  e_open);
fprintf('  폐루프 : %.4f m   (오차 %+.4f m)\n', y_close_d(end), e_close);
fprintf('  오차가 %.1f 배 줄었습니다.\n', abs(e_open/e_close));
fprintf('  이론값 1 + K*G(0) = %.1f 과 일치합니다.\n\n', 1 + K*dcgain(G));

%% 6. 이번 주차의 결론
%
%  1) 모델이 완벽하고 외란이 없다면 개루프도 충분합니다.
%     실제로 전자레인지 타이머, 신호등, 세탁기 급수는 개루프 제어입니다.
%
%  2) 외란이 있으면 개루프는 손을 쓸 수 없습니다. 출력을 안 보니까요.
%     피드백은 "결과를 보고 고친다"는 점에서 근본적으로 다릅니다.
%     외란 억제비는 1/(1+K*G(0)) 입니다. 루프이득이 클수록 잘 잡습니다.
%
%  3) 비례이득 K 를 키우면
%       - 정상상태 오차가 줄고, 외란을 더 잘 억제한다   (좋음)
%       - 진동(오버슈트)이 심해진다                      (나쁨)
%     이 맞바꿈이 앞으로 15주 내내 따라다닙니다.
%
%  4) 이번 예제에서 K 를 키워도 진동이 줄지 않은 이유:
%     비례제어는 감쇠(damping)를 만들지 못합니다.
%     감쇠를 만들려면 오차의 "변화율"을 봐야 하고, 그것이 미분제어(D)입니다.
%     -> 7주차 PD 제어
%
%  5) 정상상태 오차를 Kr 같은 보정상수 없이 근본적으로 없애려면
%     오차를 "누적"해서 밀어붙여야 합니다. 그것이 적분제어(I)입니다.
%     -> 5주차 정상상태 오차, 11주차 PID
%
%  다음 실습 : W01_02_model_uncertainty.m
%              모델 자체가 틀렸을 때 개루프와 폐루프가 어떻게 갈리는지 봅니다.
