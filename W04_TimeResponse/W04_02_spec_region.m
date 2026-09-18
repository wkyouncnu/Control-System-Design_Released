%% W04_02_spec_region.m
%  4주차 실습 (2) : 사양을 s 평면의 "영역" 으로 그리기
%
%  W04_01 에서 사양을 숫자(zeta, wn)로 바꾸는 법을 배웠습니다.
%  이번에는 그 숫자를 s 평면 위의 **영역**으로 그립니다.
%
%  왜 영역으로 그리는가
%    제어기 설계란 결국 "극점을 어디에 놓을 것인가" 를 정하는 일입니다.
%    사양을 영역으로 그려 두면 "이 안에만 들어오면 합격" 이 되어
%    설계가 눈으로 하는 작업이 됩니다.
%    6주차 근궤적에서 이 영역 위에 궤적을 겹쳐 그리게 됩니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 오버슈트 조건은 s 평면에서 어떤 모양인가?   -> 2절
%    Q2. 정착시간 조건은?                            -> 3절
%    Q3. 둘을 합치면?                                -> 4절
%    Q4. 사양이 빡세지면 영역이 어떻게 변하는가?     -> 5절
%
%  대응하는 강의노트 : W04_LectureNote.mlx
%
%  제어시스템설계 4주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 극점 위치를 두 가지로 읽기
%
%  부족감쇠 2차 시스템의 극점은 이렇게 씁니다.
%
%      s = -zeta*wn +- j*wn*sqrt(1-zeta^2)
%
%  이 점을 극좌표로 보면 훨씬 편합니다.
%
%      원점까지의 거리 = wn
%      음의 실축에서 잰 각도 = acos(zeta)
%
%  즉 s 평면에서
%
%      원점에서 멀수록      -> wn 이 크다   -> 빠르다
%      실축에서 벌어질수록  -> zeta 가 작다 -> 많이 진동한다
%
%  이 두 문장만 알면 오늘 내용의 절반은 끝난 것입니다.

wn_demo   = 3;
zeta_demo = 0.5;
p_demo = -zeta_demo*wn_demo + 1j*wn_demo*sqrt(1-zeta_demo^2);

fprintf('=== 극점 읽기 ===\n');
fprintf('  zeta = %.2f, wn = %.2f 일 때\n', zeta_demo, wn_demo);
fprintf('  극점        = %.3f + %.3fj\n', real(p_demo), imag(p_demo));
fprintf('  원점까지 거리 = %.3f   (= wn)\n', abs(p_demo));
fprintf('  실축에서의 각도 = %.1f 도  (= acos(zeta) = %.1f 도)\n\n', ...
        180 - rad2deg(angle(p_demo)), rad2deg(acos(zeta_demo)));

%% 2. 오버슈트 조건 : 부채꼴
%
%  오버슈트는 zeta 만으로 정해집니다. 그리고 zeta 는 각도로 나타납니다.
%
%      zeta >= zeta_min   <=>   각도 <= acos(zeta_min)
%
%  따라서 오버슈트 조건은 s 평면에서 **원점을 꼭짓점으로 하는 부채꼴** 안쪽입니다.
%  부채꼴이 좁을수록 (각도가 작을수록) 덜 진동합니다.
%
%  아래에서 여러 오버슈트 사양에 해당하는 직선을 그려 봅니다.

os_list = [5 10 20 40];

figure('Name','오버슈트 조건');
r = linspace(0, 6, 100);
for os = os_list
    zmin = spec2pole(os, 1);           % ts 는 여기서 쓰지 않으므로 아무 값
    th = acos(zmin);
    plot(-r*cos(th),  r*sin(th), 'LineWidth', 2); hold on;
    plot(-r*cos(th), -r*sin(th), 'LineWidth', 2, 'HandleVisibility','off');
end
xline(0,'k-','LineWidth',1.5); yline(0,'k:');
grid on; axis equal; xlim([-6 1]); ylim([-5 5]);
xlabel('Real'); ylabel('Imag');
title('오버슈트 조건 : 이 직선보다 안쪽(실축 쪽)이어야 한다');
legend(arrayfun(@(o) sprintf('%d %% 한계', o), os_list, ...
       'UniformOutput', false), 'Location','southwest');

fprintf('=== 오버슈트 조건 ===\n');
fprintf('  오버슈트[%%]   필요한 zeta   실축과의 각도[도]\n');
fprintf('  -----------  ------------  ----------------\n');
for os = os_list
    zmin = spec2pole(os, 1);
    fprintf('  %11d  %12.4f  %16.1f\n', os, zmin, rad2deg(acos(zmin)));
end
fprintf('  --> 오버슈트를 줄이려면 극점을 실축 쪽으로 붙여야 합니다.\n\n');

%% 3. 정착시간 조건 : 수직선
%
%  정착시간은 극점의 실수부만으로 정해집니다.
%
%      ts = 4/(zeta*wn) = 4/|실수부|
%
%  따라서 정착시간 조건은
%
%      |실수부| >= 4/ts
%
%  즉 s 평면에서 **어떤 수직선보다 왼쪽**이어야 합니다.
%  빠른 응답을 원할수록 이 수직선이 왼쪽으로 밀려납니다.

ts_list = [1 2 4 8];

figure('Name','정착시간 조건');
for tsx = ts_list
    xline(-4/tsx, 'LineWidth', 2, ...
          'Label', sprintf('t_s = %d s', tsx), 'LabelOrientation','horizontal');
    hold on;
end
xline(0,'k-','LineWidth',1.5); yline(0,'k:');
grid on; xlim([-6 1]); ylim([-4 4]);
xlabel('Real'); ylabel('Imag');
title('정착시간 조건 : 이 수직선보다 왼쪽이어야 한다');

fprintf('=== 정착시간 조건 ===\n');
fprintf('  정착시간[s]   필요한 |실수부|\n');
fprintf('  -----------  ---------------\n');
for tsx = ts_list
    fprintf('  %11.0f  %15.2f\n', tsx, 4/tsx);
end
fprintf('  --> 빠르게 하려면 극점을 왼쪽으로 밀어야 합니다.\n\n');

%% 4. 두 조건을 합치면 : 쐐기 모양 영역
%
%  오버슈트 조건(부채꼴)과 정착시간 조건(수직선)을 동시에 만족하는 영역은
%  왼쪽 아래위로 열린 쐐기 모양이 됩니다.
%
%  이 영역 안에 지배극점이 들어오면 사양을 만족합니다.
%
%  MATLAB 에는 이 영역을 그려 주는 명령이 있습니다.
%
%      sgrid(zeta, wn)
%
%  다만 sgrid 는 wn 을 "반지름 원" 으로 그립니다.
%  정착시간 조건(수직선)과는 조금 다르지만, 원이 수직선보다 보수적이라
%  실용상 문제가 없습니다. 6주차에서 계속 쓰게 됩니다.

P_OS = 10;  ts = 2;
[zeta_min, wn_min] = spec2pole(P_OS, ts);

figure('Name','사양 영역');

% 조건을 만족하는 영역을 색칠
th = acos(zeta_min);
xv = linspace(-8, -4/ts, 200);
yv_up = -xv*tan(th);
fill([xv fliplr(xv)], [yv_up -fliplr(yv_up)], [0.85 0.95 0.85], ...
     'EdgeColor','none'); hold on;

% 경계선
rr = linspace(0, 9, 100);
plot(-rr*cos(th),  rr*sin(th), 'r-',  'LineWidth', 2);
plot(-rr*cos(th), -rr*sin(th), 'r-',  'LineWidth', 2, 'HandleVisibility','off');
xline(-4/ts, 'b-', 'LineWidth', 2);

% 목표 극점
[~,~,s_t] = spec2pole(P_OS, ts);
plot(real(s_t),  imag(s_t), 'kp', 'MarkerSize', 16, 'MarkerFaceColor','y');
plot(real(s_t), -imag(s_t), 'kp', 'MarkerSize', 16, 'MarkerFaceColor','y', ...
     'HandleVisibility','off');

xline(0,'k-','LineWidth',1.5); yline(0,'k:');
grid on; axis equal; xlim([-8 1]); ylim([-6 6]);
xlabel('Real'); ylabel('Imag');
title(sprintf('사양 영역 : 오버슈트 %.0f%% 이하, 정착시간 %.0fs 이하', P_OS, ts));
legend('만족 영역', sprintf('오버슈트 경계 (\\zeta = %.3f)', zeta_min), ...
       sprintf('정착시간 경계 (실수부 = %.1f)', -4/ts), '두 조건이 딱 맞는 극점', ...
       'Location','southwest');

fprintf('=== 사양 영역 ===\n');
fprintf('  오버슈트 %.0f %% 이하 -> zeta >= %.4f -> 각도 <= %.1f 도\n', ...
        P_OS, zeta_min, rad2deg(th));
fprintf('  정착시간 %.0f s 이하  -> |실수부| >= %.2f\n', ts, 4/ts);
fprintf('  --> 초록색 영역 안에 지배극점이 들어오면 합격입니다.\n\n');

%% 5. 영역 안의 여러 점을 실제로 확인
%
%  영역 안의 점과 밖의 점을 골라 실제 응답을 확인해 봅니다.
%  영역 안이면 사양을 만족하고, 밖이면 못 만족해야 합니다.

cand = { -2.0 + 2.7j,  '영역 안 (경계)'
         -3.0 + 2.0j,  '영역 안 (여유)'
         -1.0 + 2.0j,  '영역 밖 (느림)'
         -2.0 + 5.0j,  '영역 밖 (진동)' };

fprintf('=== 후보 극점 검증 ===\n');
fprintf('  극점             구분              오버슈트   정착시간   판정\n');
fprintf('  ---------------  ----------------  --------  --------  ------\n');

t = 0:0.005:5;
figure('Name','후보 극점의 실제 응답');
for i = 1:size(cand,1)
    p = cand{i,1};
    Gc = (abs(p)^2) / (s^2 - 2*real(p)*s + abs(p)^2);   % 이 극점을 갖는 2차 시스템
    info = stepinfo(Gc);
    ok = (info.Overshoot <= P_OS + 0.5) && (info.SettlingTime <= ts + 0.05);
    if ok, mark = '합격'; else, mark = '불합격'; end
    fprintf('  %+.1f %+.1fj      %-16s  %7.1f %%  %7.2f s  %s\n', ...
            real(p), imag(p), cand{i,2}, info.Overshoot, info.SettlingTime, mark);
    plot(t, step(Gc, t), 'LineWidth', 2); hold on;
end
yline(1,'k--'); yline(1+P_OS/100, 'r:', 'LineWidth', 1.5);
xline(ts, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('출력');
title('후보 극점들의 실제 응답');
legend(cand(:,2), 'Location','southeast');
fprintf('\n');

%% 6. 사양이 빡세지면 어떻게 되는가
%
%  오버슈트를 줄이면 부채꼴이 좁아지고,
%  정착시간을 줄이면 수직선이 왼쪽으로 갑니다.
%  둘 다 하면 영역이 왼쪽 구석으로 밀려나면서 좁아집니다.
%
%  실무에서 이것이 뜻하는 바
%
%      영역이 좁아질수록 만족시키기 어려워집니다.
%      극점을 왼쪽 멀리 보내려면 큰 제어이득이 필요하고,
%      큰 이득은 큰 제어입력을 뜻합니다.
%      결국 구동기 한계에 부딪힙니다.
%
%  즉 사양을 무한정 빡세게 요구할 수 없습니다.
%  이 한계를 계산하는 것이 6~7주차 설계의 실제 내용입니다.

specs = [20 4; 10 2; 5 1];

fprintf('=== 사양이 빡세질수록 ===\n');
fprintf('  오버슈트  정착시간   필요 zeta   필요 |실수부|   필요 wn\n');
fprintf('  --------  --------  ---------  -------------  --------\n');
for i = 1:size(specs,1)
    [zm, wm] = spec2pole(specs(i,1), specs(i,2));
    fprintf('  %6.0f %%  %6.1f s  %9.4f  %13.2f  %8.2f\n', ...
            specs(i,1), specs(i,2), zm, 4/specs(i,2), wm);
end
fprintf('  --> 사양이 빡세질수록 wn 이 커집니다. 더 큰 이득이 필요하다는 뜻입니다.\n\n');

%% 7. 이번 실습의 정리
%
%  1) 극점을 극좌표로 읽으면 편하다.
%       원점까지 거리 = wn (빠르기)
%       실축과의 각도 = acos(zeta) (진동)
%
%  2) 사양은 s 평면의 영역이 된다.
%       오버슈트 조건 -> 부채꼴 (각도 제한)
%       정착시간 조건 -> 수직선 (실수부 제한)
%       둘을 합치면 왼쪽으로 열린 쐐기 모양
%
%  3) 지배극점이 이 영역 안에 들어오면 사양을 만족한다.
%
%  4) MATLAB 에서는 sgrid(zeta, wn) 으로 이 영역을 그린다. 6주차부터 계속 쓴다.
%
%  5) 사양이 빡세질수록 영역이 좁아지고 더 큰 이득이 필요해진다.
%     결국 구동기 한계에 부딪히므로, 사양은 무한정 요구할 수 없다.
%
%  다음 실습 : W04_03_run_simulink.m
%              Simulink 에서 zeta 와 wn 을 바꿔 가며 응답을 직접 확인합니다.
