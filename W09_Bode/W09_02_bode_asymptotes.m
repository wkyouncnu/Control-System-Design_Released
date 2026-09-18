%% W09_02_bode_asymptotes.m
%  9주차 실습 (2) : 보드 선도를 손으로 그리는 법 (점근선)
%
%  이 스크립트에서 답할 질문
%    Q1. 전달함수를 어떤 조각으로 쪼개는가?        -> 1절
%    Q2. 조각마다 점근선이 어떻게 생겼는가?        -> 2절
%    Q3. 조각을 더하면 정말 전체가 되는가?         -> 3절
%    Q4. 2차 항의 봉우리는 왜 생기는가?            -> 4절
%    Q5. 손작도가 실제와 얼마나 차이 나는가?       -> 5절
%
%  대응하는 강의노트 : W09_LectureNote.mlx
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 전달함수는 네 가지 조각으로만 이루어진다
%
%  실계수 다항식은 반드시 1차식과 2차식의 곱으로 인수분해됩니다.
%  그래서 전달함수는 결국 아래 네 가지 조각의 곱입니다.
%
%      (1) 상수 K
%      (2) s^n  (원점의 극점 = 적분기, 또는 원점의 영점 = 미분기)
%      (3) 1차  (Ts + 1) 꼴
%      (4) 2차  (s/wn)^2 + 2*zeta*(s/wn) + 1 꼴
%
%  네 조각의 점근선만 외우면 어떤 전달함수든 손으로 그릴 수 있습니다.
%
%  오늘 예로 쓸 것

L = 10/(s*(s+1)*(0.1*s+1));

fprintf('=== 오늘의 예 ===\n');
L
fprintf('  조각으로 쪼개면\n');
fprintf('    상수      10          -> %6.2f dB (일정)\n', 20*log10(10));
fprintf('    적분기    1/s         -> -20 dB/dec 로 계속 내려감\n');
fprintf('    1차 극점  1/(s+1)     -> w = 1 부터 꺾임\n');
fprintf('    1차 극점  1/(0.1s+1)  -> w = 10 부터 꺾임\n\n');

%% 1-1. 주의 — "시정수 꼴" 로 정리하고 시작한다
%
%  (s+1) 과 (0.1s+1) 은 같은 꼴이지만 (s+10) 은 아닙니다.
%  점근선을 그리려면 **상수항이 1** 이 되도록 정리해야 합니다.
%
%      s + 10  =  10*(0.1*s + 1)
%
%  이때 튀어나온 10 은 상수 조각으로 넘어갑니다. 이것을 빠뜨리면
%  그림 전체가 위아래로 어긋납니다. 손작도에서 가장 흔한 실수입니다.

fprintf('=== 시정수 꼴로 정리하기 ===\n');
fprintf('  잘못 :  1/(s+10) 을 "w=10 에서 꺾이는 조각" 으로만 본다\n');
fprintf('  바르게:  1/(s+10) = (1/10) * 1/(0.1*s+1)\n');
fprintf('           -> 상수 0.1 (= %.1f dB) 이 따로 있다\n\n', 20*log10(0.1));

%% 2. 조각마다 점근선
%
%  외울 것은 이것뿐입니다.
%
%    상수 K       : 20*log10(K) 인 수평선.        위상 0도 (K>0)
%    적분기 1/s   : -20 dB/dec 기울기.            위상 -90도 (항상)
%    1차 극점     : 꺾임주파수 전 0 dB, 후 -20 dB/dec.  위상 0 -> -90도
%    1차 영점     : 꺾임주파수 전 0 dB, 후 +20 dB/dec.  위상 0 -> +90도
%    2차 극점     : 꺾임 전 0, 후 -40 dB/dec.     위상 0 -> -180도
%
%  "dec" 은 데케이드, 즉 주파수가 10배가 되는 구간입니다.

w = logspace(-2, 3, 800);

a_gain = 20*log10(10) * ones(size(w));
a_int  = -20*log10(w);
a_p1   = -20*log10(max(w/1,  1));
a_p10  = -20*log10(max(w/10, 1));

figure('Name','조각마다 점근선', 'Position',[80 80 850 420]);
semilogx(w, a_gain, '--', 'LineWidth', 2); hold on; grid on;
semilogx(w, a_int,  '--', 'LineWidth', 2);
semilogx(w, a_p1,   '--', 'LineWidth', 2);
semilogx(w, a_p10,  '--', 'LineWidth', 2);
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]'); ylim([-120 40]);
legend('상수 10', '적분기 1/s', '극점 s+1', '극점 0.1s+1', 'Location','southwest');
title('1단계 — 조각마다 따로 그린다');

%% 3. 더하면 전체가 된다
%
%  로그를 취했으므로 곱이 합이 됩니다. 그냥 세로로 더하면 됩니다.

a_sum = a_gain + a_int + a_p1 + a_p10;
m_real = 20*log10(squeeze(abs(freqresp(L, w))));

figure('Name','점근선의 합 vs 실제', 'Position',[80 80 850 420]);
semilogx(w, a_sum, '--', 'LineWidth', 2.5); hold on; grid on;
semilogx(w, m_real, 'LineWidth', 2);
xline(1,  ':', 'LineWidth', 1.5);
xline(10, ':', 'LineWidth', 1.5);
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]'); ylim([-120 40]);
legend('점근선의 합', '실제 곡선', 'w = 1 (꺾임)', 'w = 10 (꺾임)', ...
       'Location','southwest');
title('2단계 — 더하면 실제와 거의 같다');

fprintf('=== 점근선과 실제의 차이 ===\n');
fprintf('    w[rad/s]   점근선[dB]   실제[dB]   차이[dB]\n');
fprintf('   ---------  -----------  ---------  ---------\n');
for wq = [0.1 0.5 1 2 5 10 20 100]
    as = interp1(log(w), a_sum,  log(wq));
    rl = interp1(log(w), m_real, log(wq));
    fprintf('   %9.2f  %11.2f  %9.2f  %9.2f\n', wq, as, rl, rl-as);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    꺾임주파수에서만 약 3 dB 어긋나고 나머지는 거의 정확합니다.\n');
fprintf('    1차 극점 하나가 꺾임주파수에서 정확히 -3.01 dB 이기 때문입니다.\n');
fprintf('    (|1/(j*1+1)| = 1/sqrt(2) = %.4f -> %.2f dB)\n\n', ...
        1/sqrt(2), 20*log10(1/sqrt(2)));

%% 3-1. 위상도 점근선으로 그린다
%
%  크기만 그릴 줄 알면 반쪽입니다. 10~11 주차에서 실제로 쓰는 것은 위상입니다.
%  위상여유가 거기서 나오기 때문입니다.
%
%  규칙은 크기와 조금 다릅니다. 위상은 꺾임주파수에서 급하게 안 꺾입니다.
%
%    상수      : 항상 0 도
%    적분기 1/s : 항상 -90 도 (주파수와 무관)
%    1 차 극점  : 꺾임주파수의 1/10 에서 시작해 10 배에서 끝나는 -45 도/dec 직선
%                 꺾임주파수 바로 그 자리에서 정확히 -45 도
%    1 차 영점  : 부호만 반대 (0 -> +90 도)
%
%  왜 두 데케이드인가
%    1 차 극점의 위상은 -atan(w/wc) 입니다.
%    w = 0.1*wc 에서 -5.7 도, w = 10*wc 에서 -84.3 도이므로
%    그 바깥은 0 도와 -90 도로 봐도 무방합니다.

La = 10/(s*(s+1)*(0.1*s+1));
wa = logspace(-2, 3, 800);

% 조각마다의 위상 점근선
ramp  = @(wc) -45*min(max(log10(wa/(wc/10)), 0), 2);
ph_int = -90*ones(size(wa));
ph_p1  = ramp(1);      % 극점 s+1
ph_p2  = ramp(10);     % 극점 0.1s+1
ph_sum = ph_int + ph_p1 + ph_p2;
[~, ph_true] = bode(La, wa);  ph_true = squeeze(ph_true).';

figure('Name','위상 점근선');
subplot(2,1,1);
semilogx(wa, zeros(size(wa)), 'LineWidth', 2); hold on; grid on;
semilogx(wa, ph_int, 'LineWidth', 2);
semilogx(wa, ph_p1,  'LineWidth', 2);
semilogx(wa, ph_p2,  'LineWidth', 2);
ylim([-100 20]); ylabel('위상 [도]');
legend('상수', '적분기', '극점 s+1', '극점 0.1s+1', 'Location','southwest');
title('조각마다의 위상 점근선');
subplot(2,1,2);
semilogx(wa, ph_sum, '--', 'LineWidth', 2.5); hold on; grid on;
semilogx(wa, ph_true, 'LineWidth', 2);
yline(-180, 'k:');
ylim([-290 -70]); xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
legend('점근선의 합', '실제', 'Location','southwest');
title('더하면 실제와 거의 같다');

fprintf('=== 위상 점근선과 실제 ===\n');
fprintf('  %-10s %-12s %-12s %s\n', 'w', '점근선[도]', '실제[도]', '차이[도]');
for wq = [0.1 0.316 1 3.162 10 31.6 100]
    pa = -90 - 45*min(max(log10(wq/0.1),0),2) - 45*min(max(log10(wq/1),0),2);
    [~, pt] = bode(La, wq);
    fprintf('  %-10.3f %-12.2f %-12.2f %+.2f\n', wq, pa, squeeze(pt), squeeze(pt)-pa);
end
fprintf('  --> 최대 6.3 도 어긋납니다. 부호가 번갈아 바뀌어 평균적으로는 맞습니다.\n\n');

%% 3-2. 점근선만으로 교차주파수와 위상여유를 읽는다
%
%  이것이 손작도를 배우는 진짜 이유입니다. 컴퓨터 없이 두 숫자를 얻습니다.
%
%    교차주파수 wc : 크기 점근선이 0 dB 를 지나는 곳
%    위상여유 PM   : 그 자리에서 위상을 읽고 180 을 더한 값
%
%  손계산
%    1 < w < 10 구간에서 크기 점근선은  20 - 40*log10(w)
%    이것이 0 이 되는 곳 : log10(w) = 0.5  ->  wc = sqrt(10) = 3.16
%    (구한 값이 정말 1~10 안에 있는지 반드시 확인할 것)
%
%    그 자리의 위상 : -90 - 45*log10(3.16/0.1) - 45*log10(3.16/1)
%                   = -90 - 67.5 - 22.5 = -180 도
%    따라서 PM = 0 도. 거의 불안정합니다.

wc_hand = 10^0.5;
pm_hand = 180 + (-90 - 45*log10(wc_hand/0.1) - 45*log10(wc_hand/1));
[~, pm_m, ~, wc_m] = margin(La);

fprintf('=== 손으로 읽은 값 vs margin ===\n');
fprintf('  교차주파수 : 손 %.3f  vs  margin %.3f rad/s  (차이 %.1f %%)\n', ...
        wc_hand, wc_m, 100*abs(wc_hand-wc_m)/wc_m);
fprintf('  위상여유   : 손 %.1f 도  vs  margin %.2f 도\n', pm_hand, pm_m);
fprintf('  --> 둘 다 "여유가 거의 없다" 는 같은 결론입니다.\n');

figure('Name','손으로 읽은 여유 검산');
margin(La); grid on;
title(sprintf('margin : wc = %.3f rad/s, PM = %.2f 도  (손계산 3.16, 0 도)', wc_m, pm_m));
fprintf('\n');
%% 4. 2차 항 — 봉우리는 왜 생기는가
%
%  2차 극점은 감쇠비에 따라 꺾임주파수 근처에서 **봉우리**가 생깁니다.
%  점근선만 보면 이 봉우리를 놓칩니다.
%
%  왜 생기는가
%
%      2차 표준형에 s = j*wn 을 넣으면 실수부가 서로 상쇄되고
%      허수부 2*zeta 만 남습니다. 즉 |T(j*wn)| = 1/(2*zeta) 입니다.
%      zeta 가 작을수록 이 값이 커집니다. 그것이 봉우리입니다.

wn = 1;
zs = [0.05 0.1 0.3 0.707 1.0];
w2 = logspace(-1, 1, 600);

figure('Name','2차 항의 봉우리', 'Position',[80 80 900 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
for z = zs
    T = wn^2/(s^2 + 2*z*wn*s + wn^2);
    plot(w2, 20*log10(squeeze(abs(freqresp(T, w2)))), 'LineWidth', 2, ...
         'DisplayName', sprintf('\\zeta = %.3g', z));
end
set(gca,'XScale','log');
yline(0,'k--','HandleVisibility','off');
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('Location','southwest');
title('감쇠비가 작을수록 봉우리가 높다');

nexttile; hold on; grid on;
zz = linspace(0.02, 0.75, 200);
plot(zz, 20*log10(1./(2*zz)), 'LineWidth', 2.5);
xline(0.707,'k--');
xlabel('감쇠비 \zeta'); ylabel('w = w_n 에서의 크기 [dB]');
title('봉우리 높이 = 1/(2\zeta),  \zeta > 0.707 이면 봉우리가 없다');

fprintf('=== 2차 항의 봉우리 ===\n');
fprintf('    zeta    w=wn 에서 |T|    dB      공진봉우리 Mr    공진주파수 wr\n');
fprintf('   ------  --------------  ------  ---------------  --------------\n');
for z = zs
    Tz = wn^2/(s^2 + 2*z*wn*s + wn^2);
    val = 1/(2*z);
    if z < 1/sqrt(2) - 1e-3
        Mr = 1/(2*z*sqrt(1-z^2));
        wr = wn*sqrt(1-2*z^2);
        fprintf('   %6.3f  %14.4f  %6.2f  %15.4f  %14.4f\n', z, val, 20*log10(val), Mr, wr);
    else
        fprintf('   %6.3f  %14.4f  %6.2f  %15s  %14s\n', z, val, 20*log10(val), '없음', '-');
    end
end
fprintf('\n');
fprintf('  주의 : "w = wn 에서의 값" 과 "봉우리 최댓값 Mr" 은 다릅니다.\n');
fprintf('         봉우리는 wn 보다 조금 왼쪽(wr)에서 생깁니다.\n');
fprintf('         zeta 가 작으면 둘이 거의 같아집니다.\n\n');

%% 5. 손작도 연습 — 그림만 보고 전달함수를 맞혀 보기
%
%  실무에서는 반대 방향도 자주 합니다.
%  장치의 보드 선도를 실험으로 재고, 거기서 전달함수를 읽어 내는 것입니다.
%
%  읽는 순서
%    (1) 저주파 기울기를 본다        -> 원점 극점 개수 (타입)
%    (2) 저주파 높이를 본다          -> 상수 이득
%    (3) 기울기가 꺾이는 곳을 찾는다 -> 극점·영점 위치
%    (4) 꺾임의 방향과 크기를 본다   -> 극점(-20)인가 영점(+20)인가, 1차인가 2차인가

quiz = { '문제 A', 5/((s+2)*(s+20))
         '문제 B', 100/(s*(s+5))
         '문제 C', 4*(s+1)/((s+0.5)*(s+40)) };

figure('Name','손으로 읽어 보기', 'Position',[80 80 900 420]);
tiledlayout(1,3,'TileSpacing','compact');
for i = 1:3
    nexttile
    Lq = quiz{i,2};
    semilogx(w, 20*log10(squeeze(abs(freqresp(Lq, w)))), 'LineWidth', 2);
    grid on; ylim([-100 60]);
    xlabel('주파수 [rad/s]');
    if i == 1, ylabel('크기 [dB]'); end
    title(quiz{i,1});
end

fprintf('=== 손으로 읽어 보기 (답) ===\n');
for i = 1:3
    Lq = quiz{i,2};
    n0 = sum(abs(pole(Lq)) < 1e-9);              % 원점 극점(적분기) 개수 = 타입
    zq = zero(Lq);
    if isempty(zq), zstr = '없음'; else, zstr = mat2str(round(zq.',3)); end
    fprintf('  %s : 저주파 기울기 %+4d dB per dec, 극점 %s, 영점 %s\n', ...
            quiz{i,1}, int32(-20*n0), mat2str(round(pole(Lq).',3)), zstr);
end
fprintf('\n');

%% 6. 이번 실습의 정리
%
%   (1) 전달함수는 상수·적분기·1차·2차 네 조각의 곱이다
%   (2) 조각마다 점근선을 그리고 **더하면** 전체가 된다
%   (3) 시정수 꼴 (Ts+1) 로 정리하고 시작해야 한다. 상수를 빠뜨리지 말 것
%   (4) 꺾임주파수에서만 약 3 dB 어긋난다
%   (5) 2차 항은 zeta < 0.707 이면 봉우리가 생긴다. 높이는 대략 1/(2*zeta)
%
%  다음 실습
%    W09_03_run_simulink.m — Simulink 로 주파수를 훑어 보드 선도를 직접 측정
