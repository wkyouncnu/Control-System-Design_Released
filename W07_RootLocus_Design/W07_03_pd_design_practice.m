%% W07_03_pd_design_practice.m
%  7주차 실습 (3) : PD 설계 연습 - 영점을 어디에 놓을 것인가
%
%  W07_02 에서 PD 제어기가 궤적을 왼쪽으로 당긴다는 것을 배웠습니다.
%  이제 실제로 설계해 봅니다. 비례제어와 달리 고를 것이 **둘**입니다.
%
%      D(s) = K (s + z)      z 를 어디에? K 는 얼마로?
%
%  둘을 한꺼번에 풀 수는 없습니다. 그래서 이렇게 합니다.
%
%      1) z 후보를 몇 개 정한다
%      2) 각 z 마다 근궤적을 그리고 사양을 만족하는 K 구간을 찾는다
%      3) 표를 만들어 비교하고 고른다
%
%  이 스크립트에서 답할 질문
%    Q1. 영점 위치를 바꾸면 무엇이 달라지는가?     -> 2절
%    Q2. 영점을 플랜트 극점 위에 놓으면?           -> 3절
%    Q3. PD 로 정상상태 오차를 없앨 수 있는가?     -> 4절
%
%  적분기가 있는 3차 플랜트(타입 1)의 PD 설계는 W07_04 의 3절에서
%  제어입력 한계와 함께 다룹니다.
%
%  대응하는 강의노트 : W07_LectureNote.mlx
%  대응하는 Simulink : W07_Design_Verify.slx
%
%  제어시스템설계 7주차 | 충남대학교 자율운항시스템공학과

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

%% 1. PD 설계에서 영점이 하는 일
%
%  PD 제어기는 개루프에 영점 하나를 더합니다.
%
%      L(s) = K (s + z) G(s)
%
%  영점은 궤적을 자기 쪽으로 끌어당깁니다. 자석이라고 생각하십시오.
%  영점이 왼쪽에 있으면 궤적이 왼쪽으로 휩니다. 왼쪽 = 빠르고 안정.
%
%  그런데 어디까지 왼쪽으로 옮겨야 좋을까요? 세 가지가 부딪힙니다.
%
%    - z 가 작으면 (원점 가까이)  : 궤적이 크게 휘지만 느린 영점이 응답을 늘어뜨린다
%    - z 가 크면   (멀리 왼쪽)    : 미분 성질이 강해져 제어입력이 커진다
%    - z 를 플랜트 극점에 맞추면  : 그 극점이 사라진다 (3절에서 다룸)
%
%  숫자로 확인합니다.

%% 1-1. 영점 위치를 계산으로 정한다 — 각도 부족
%
%  2 절부터는 영점 후보를 여러 개 놓고 표로 비교합니다.
%  그런데 그 후보를 처음에 어떻게 잡을까요? 감으로 잡지 않아도 됩니다.
%
%  6주차 1-1 절의 각도 조건을 뒤집어 쓰면 계산으로 나옵니다.
%
%    1) 사양에서 목표 극점 sd 를 정한다        (spec2pole)
%    2) 그 점에서 플랜트의 각을 잰다            ∠G(sd)
%    3) -180 도에 모자란 각을 구한다            phi
%    4) 그 각을 내는 영점 위치를 구한다          z = sigma_d + wd/tan(phi)
%    5) 크기 조건으로 이득을 구한다              K = 1/|C(sd)G(sd)|
%
%  4 단계 식은 그림에서 바로 나옵니다. 목표 극점을 sd = -sigma_d + j*wd,
%  영점을 -z 라 하면 영점에서 sd 로 가는 벡터가 (z - sigma_d) + j*wd 이므로
%
%      tan(phi) = wd / (z - sigma_d)
%
%  입니다. 여기서 z 를 풀면 위 식이 됩니다.

Gpd  = 1/(s*(s+4));
POS0 = 16;  ts0 = 1;

[zeta0, wn0] = spec2pole(POS0, ts0);
sig0 = zeta0*wn0;
wd0  = wn0*sqrt(1 - zeta0^2);
sd0  = -sig0 + 1i*wd0;

angG0 = rad2deg(angle(evalfr(Gpd, sd0)));
phi0  = mod(-180 - angG0, 360);
z0    = sig0 + wd0/tand(phi0);
C0    = s + z0;
K0    = 1/abs(evalfr(C0*Gpd, sd0));

fprintf('=== 각도 부족으로 PD 설계 ===\n');
fprintf('  1) 사양 %%OS=%g, ts=%g  ->  zeta=%.4f, wn=%.4f\n', POS0, ts0, zeta0, wn0);
fprintf('     목표 극점 sd = %.4f %+.4fj\n', real(sd0), imag(sd0));
fprintf('  2) 극점 각의 합 = %.2f 도\n', sum(rad2deg(angle(sd0 - pole(Gpd).'))));
fprintf('  3) 보태야 할 각 = %.2f 도\n', phi0);
fprintf('  4) 영점 위치    = %.4f\n', -z0);
fprintf('  5) 이득 K       = %.4f\n', K0);
fprintf('     -> C(s) = %.3f(s + %.3f),  즉 Kp = %.3f, Kd = %.3f\n', ...
        K0, z0, K0*z0, K0);

T0 = feedback(K0*C0*Gpd, 1);
fprintf('\n  확인 : 폐루프 극점 %s\n', mat2str(round(pole(T0).', 4)));
fprintf('         목표 극점    %s\n', mat2str(round([sd0 conj(sd0)], 4)));
i0 = stepinfo(T0);
fprintf('         실측 : 오버슈트 %.2f %%, 정착시간 %.3f s\n', i0.Overshoot, i0.SettlingTime);

figure('Name','각도 부족으로 설계한 PD');
rlocus(C0*Gpd); hold on; grid on;
plot(real(sd0), imag(sd0), 'p', 'MarkerSize', 14, 'LineWidth', 1.5, ...
     'MarkerFaceColor', [0.93 0.69 0.13], 'MarkerEdgeColor', 'k');
plot(real(pole(T0)), imag(pole(T0)), 'ms', 'MarkerSize', 10, 'LineWidth', 2);
xlim([-20 2]); ylim([-10 10]);
title('별 = 목표 극점, 사각 = 실제 폐루프 극점 (겹쳐야 성공)');

%% 1-2. 극점은 맞았는데 오버슈트가 사양보다 큰 이유
%
%  위 결과를 보면 극점은 목표 자리에 정확히 갔는데 오버슈트가 사양보다 큽니다.
%  설계가 틀린 것이 아닙니다.
%
%  %OS 공식은 극점 두 개만 있고 영점이 없는 표준 2차 시스템에서 나온 것인데,
%  우리가 방금 영점을 하나 넣었기 때문입니다.
%
%    - 극점 배치 : 각도 조건과 크기 조건이 보장한다 -> 정확히 맞는다
%    - 오버슈트  : 영점이 더 키운다 -> 공식보다 커진다
%
%  그래서 실무에서는 목표를 조금 보수적으로 잡고 되풀이합니다.

fprintf('\n=== 목표를 낮춰 잡고 되풀이하면 ===\n');
fprintf('  %-10s %-10s %-8s %-12s %s\n', '목표 %OS', '영점', 'K', '실측 %OS', '실측 ts');
for POSt = [16 12 9]
    [zt, wt] = spec2pole(POSt, ts0);
    sdt = -zt*wt + 1i*wt*sqrt(1-zt^2);
    pht = mod(-180 - rad2deg(angle(evalfr(Gpd, sdt))), 360);
    zt2 = zt*wt + wt*sqrt(1-zt^2)/tand(pht);
    Ct  = s + zt2;
    Kt  = 1/abs(evalfr(Ct*Gpd, sdt));
    it  = stepinfo(feedback(Kt*Ct*Gpd, 1));
    fprintf('  %-10d %-10.3f %-8.3f %-12.2f %.3f s\n', ...
            POSt, -zt2, Kt, it.Overshoot, it.SettlingTime);
end
fprintf('  --> 목표를 12 %% 로 잡으면 실측이 사양 16 %% 안에 들어옵니다.\n\n');
%% 2. 예제 D - 영점 위치 세 개를 비교한다
%
%      G(s) = 1 / ((s+1)(s+4)) ,   D(s) = K (s + z)
%
%      요구 : 오버슈트 10 % 이하
%             정착시간 2.5 초 이하
%             제어입력 |u| <= 10       <- 구동기 한계
%
%  후보 : z = 1, 3, 6

GD = 1/((s+1)*(s+4));
zc = [1 3 6];
Kv = linspace(0.2, 40, 400);

fprintf('=== 예제 D : G = 1/((s+1)(s+4)) 에 PD ===\n');
fprintf('  요구 : OS <= 10 %%, ts <= 2.5 s, |u| <= 10\n\n');
fprintf('    z    만족 K 구간      고른 K   OS[%%]   ts[s]   오차    max|u|\n');
fprintf('  -----  --------------  -------  ------  ------  ------  -------\n');

pickD = [];
for i = 1:numel(zc)
    z  = zc(i);
    Ti = rl_scan(s+z, GD, Kv, true);
    ok = Ti.stable & Ti.OS <= 10 & Ti.ts <= 2.5 & Ti.umax <= 10;
    if ~any(ok)
        fprintf('  %5d  만족하는 K 없음\n', z);
        continue
    end
    sub = Ti(ok, :);
    [~, j] = min(sub.ess);              % 같은 조건이면 오차가 작은 쪽
    fprintf('  %5d  %6.2f ~ %5.2f  %7.2f  %6.2f  %6.2f  %6.4f  %7.2f\n', ...
            z, min(sub.K), max(sub.K), sub.K(j), sub.OS(j), sub.ts(j), ...
            sub.ess(j), sub.umax(j));
    pickD(end+1, :) = [z sub.K(j) sub.OS(j) sub.ts(j) sub.ess(j) sub.umax(j)]; %#ok<SAGROW>
end

[~, jb] = min(pickD(:,5));
zD = pickD(jb,1);  KD = pickD(jb,2);
fprintf('\n  --> 오차가 가장 작은 조합 : z = %g , K = %.2f\n', zD, KD);
fprintf('\n  표를 읽는 법\n');
fprintf('    - 세 경우 모두 max|u| 가 9 를 넘습니다. 즉 K 의 위쪽 한계를 정한 것은\n');
fprintf('      오버슈트가 아니라 **구동기 한계 10** 입니다\n');
fprintf('    - 같은 제어입력 예산 안에서 오차를 결정하는 것은 Kp = K*z/4 입니다.\n');
fprintf('      z = 1 : Kp = %.2f   z = 6 : Kp = %.2f  -> 6 배 차이\n', ...
        pickD(1,2)*pickD(1,1)/4, pickD(end,2)*pickD(end,1)/4);
fprintf('    - 그래서 영점을 왼쪽으로 옮길수록 같은 힘으로 더 정확해집니다\n\n');

tD = linspace(0, 3, 800)';
figure('Name','예제 D','Position',[80 80 1050 380]);
tiledlayout(1,3,'TileSpacing','compact');

nexttile
rlocus(GD*(s+zc(1))); hold on;
rlocus(GD*(s+zc(3)));
xlim([-12 1]); ylim([-8 8]); grid on;
title(sprintf('영점 z = %d 와 z = %d 의 궤적', zc(1), zc(3)));

nexttile
hold on; grid on;
for i = 1:size(pickD,1)
    Ci = pickD(i,2)*(s + pickD(i,1));
    plot(tD, step(feedback(Ci*GD,1), tD), 'LineWidth', 2, ...
         'DisplayName', sprintf('z = %g, K = %.1f', pickD(i,1), pickD(i,2)));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); title('계단응답');
legend('Location','southeast');

nexttile
hold on; grid on;
for i = 1:size(pickD,1)
    Ci = pickD(i,2)*(s + pickD(i,1));
    [ui, ~] = ctrl_input(Ci, GD, tD);
    plot(tD, ui, 'LineWidth', 2, 'DisplayName', sprintf('z = %g', pickD(i,1)));
end
yline(10,'r--','DisplayName','구동기 한계');
xlabel('시간 [s]'); ylabel('제어입력 u'); title('제어입력 (한계 10)');
legend('Location','northeast');

%% 3. 예제 D-1 - 영점을 플랜트 극점 위에 놓으면
%
%  z = 4 로 두면 제어기 영점이 플랜트 극점 s = -4 와 정확히 겹칩니다.
%
%      L(s) = K (s+4) / ((s+1)(s+4)) = K / (s+1)
%
%  개루프가 1차로 줄어듭니다. 폐루프는 K/(s+1+K), 즉 진동이 아예 없습니다.
%  종이 위에서는 최고의 설계입니다.

zX = 4;
LX = minreal((s+zX)*GD);
fprintf('=== 예제 D-1 : 영점으로 플랜트 극점 상쇄 (z = %d) ===\n', zX);
fprintf('  약분한 개루프 : \n'); LX %#ok<NOPTS>

KX = 7;
TX = feedback(KX*(s+zX)*GD, 1);
iX = stepinfo(TX);
fprintf('  K = %d 일 때 : OS = %.2f %%, ts = %.3f s, 오차 = %.4f\n', ...
        KX, iX.Overshoot, iX.SettlingTime, 1-dcgain(TX));

%  상쇄가 정확히 맞지 않으면? 실제 극점이 -4 가 아니라 -3 이었다고 해 봅니다.
GD_real  = 1/((s+1)*(s+3));
TX_real  = feedback(KX*(s+zX)*GD_real, 1);
iXr      = stepinfo(TX_real);
fprintf('  실제 극점이 -3 이었다면 : OS = %.2f %%, ts = %.3f s, 오차 = %.4f\n', ...
        iXr.Overshoot, iXr.SettlingTime, 1-dcgain(TX_real));
fprintf('  폐루프 극점 : %s   <- 여전히 좌반면, 여전히 멀쩡합니다\n\n', ...
        mat2str(round(pole(TX_real)', 3)));

%% 3-1. 그런데 절대로 하면 안 되는 상쇄가 하나 있습니다
%
%  플랜트에 **불안정한 극점**(우반면 극점)이 있을 때 그것을 영점으로 지우는 것입니다.
%
%      G(s) = 1 / ((s-1)(s+4))     s = +1 이 불안정 극점
%      D(s) = K (s - 1)            그 자리에 영점을 놓아 지운다
%
%  종이 위에서 약분하면 개루프가 K/(s+4) 가 되어 아주 안정해 보입니다.
%  계단응답을 그려 봐도 멀쩡합니다. 그래서 더 무섭습니다.

G_unst = 1/((s-1)*(s+4));
C_bad  = 5*(s-1);
T_bad  = feedback(C_bad*G_unst, 1);    % 지령 -> 출력
S_bad  = feedback(G_unst, C_bad);      % 플랜트 입력 외란 -> 출력

t_bad = linspace(0, 8, 600)';
y_bad = step(T_bad, t_bad);
d_bad = step(0.01*S_bad, t_bad);       % 크기 0.01 짜리 아주 작은 외란

fprintf('=== 절대 금지 : 불안정 극점 상쇄 ===\n');
fprintf('  손으로 약분하면 : L = K/(s+4)  ->  아주 안정해 보인다\n');
fprintf('  폐루프 극점     : %s   <- s = +1 이 그대로 남아 있다\n', ...
        mat2str(round(pole(T_bad)', 3)));
fprintf('  그런데 지령 -> 출력 계단응답은 8 초 뒤 %.3f 로 멀쩡합니다\n\n', y_bad(end));

fprintf('  왜 멀쩡해 보이는가\n');
fprintf('    제어기 영점이 그 불안정 극점을 정확히 가려 버렸기 때문입니다.\n');
fprintf('    지령에서 출력으로 가는 길에서만 안 보이는 것이지,\n');
fprintf('    시스템 안에서는 여전히 살아 있습니다.\n\n');

fprintf('  가려진 것을 드러내는 법 : 아주 작은 외란을 하나 넣어 본다\n');
fprintf('    플랜트 입력에 크기 0.01 짜리 외란만 넣으면\n');
fprintf('    8 초 뒤 출력 : %.2f   -> 외란의 %.0f 배로 커졌습니다\n', ...
        d_bad(end), d_bad(end)/0.01);
fprintf('    실제 장치에는 외란도 있고 초기값도 있습니다. 반드시 터집니다.\n\n');

figure('Name','불안정 극점 상쇄','Position',[160 160 900 360]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
plot(t_bad, y_bad, 'LineWidth', 2); grid on;
xlabel('시간 [s]'); ylabel('출력'); title('지령 응답 : 멀쩡해 보인다');
nexttile
plot(t_bad, d_bad, 'LineWidth', 2, 'Color', [0.85 0.2 0.2]); grid on;
xlabel('시간 [s]'); ylabel('출력'); title('크기 0.01 외란 : 발산한다');

fprintf('  정리\n');
fprintf('    - 안정한 극점 상쇄 : 유용한 기법. 어긋나도 크게 나빠지지 않는다\n');
fprintf('    - 불안정한 극점 상쇄 : 절대 금지.\n');
fprintf('      계단응답만 보면 속습니다. 반드시 폐루프 극점을 직접 확인하십시오\n\n');

%% 4. 예제 E - PD 로 정상상태 오차를 없앨 수 있는가
%
%  W07_01 의 예제 C 를 다시 가져옵니다.
%
%      G(s) = 5 / ((s+1)(s+2)(s+5))
%      요구 : 계단 오차 5 % 이하 + 오버슈트 20 % 이하
%
%  비례제어로는 불가능했습니다 (오차가 요구하는 이득이 안정 한계를 넘음).
%  PD 를 붙이면 궤적이 왼쪽으로 가니 이득을 더 쓸 수 있습니다.
%  그러면 오차도 줄겠지요. 정말 그런지 봅니다.

GE = 5/((s+1)*(s+2)*(s+5));
fprintf('=== 예제 E : 예제 C 를 PD 로 다시 ===\n');
fprintf('  요구 : 오차 <= 0.05 , 오버슈트 <= 20 %%\n\n');
fprintf('    z     오차 0.05 를 만족하는 K   그때 오버슈트[%%]  지배극점 감쇠비\n');
fprintf('  -----  -------------------------  ----------------  ---------------\n');

zE = [0.5 1 1.5 2 3];
for z = zE
    Te = rl_scan(s+z, GE, linspace(2, 200, 400));
    ok = Te.stable & Te.ess <= 0.05;
    if ~any(ok)
        fprintf('  %5.1f  없음\n', z);
        continue
    end
    sub = Te(ok, :);
    [~, j] = min(sub.OS);
    fprintf('  %5.1f  %8.1f ~ %-8.1f        %10.2f       %10.3f\n', ...
            z, min(sub.K), max(sub.K), sub.OS(j), sub.zeta(j));
end

fprintf('\n  ** 오버슈트가 20 %% 아래로 내려가는 조합이 하나도 없습니다. **\n\n');

%% 4-1. 왜 감쇠비는 1 인데 오버슈트가 40 % 인가
%
%  위 표의 z = 0.5 행과 z = 1.5 행을 보십시오.
%  지배극점의 감쇠비가 1(= 실극점, 진동 없음)인데 오버슈트가 40 % 입니다.
%  4주차 공식이라면 감쇠비 1 은 오버슈트 0 이어야 합니다.
%
%  범인은 **영점** 입니다. 직접 확인합니다.

zz = 1.5; Kz = 26;
TE = feedback(Kz*(s+zz)*GE, 1);
fprintf('=== 감쇠비와 오버슈트가 어긋나는 이유 (z = %.1f, K = %d) ===\n', zz, Kz);
fprintf('  폐루프 극점 : %s\n', mat2str(round(pole(TE)', 3)));
fprintf('  폐루프 영점 : %s\n', mat2str(round(zero(TE)', 3)));
fprintf('  실측 오버슈트 : %.2f %%\n', getfield(stepinfo(TE),'Overshoot')); %#ok<GFLD>

% 같은 극점, 영점만 없앤 시스템과 비교
TE_nz = zpk([], pole(TE), 1);
TE_nz = TE_nz / dcgain(TE_nz);
fprintf('  같은 극점에서 영점만 지우면 : %.2f %%\n', getfield(stepinfo(TE_nz),'Overshoot')); %#ok<GFLD>
fprintf('  --> 오버슈트 %.0f %% 는 전부 영점이 만든 것입니다.\n\n', ...
        getfield(stepinfo(TE),'Overshoot')); %#ok<GFLD>

tE = linspace(0, 3, 800)';
figure('Name','영점이 만드는 오버슈트','Position',[100 100 900 380]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
plot(tE, step(TE, tE), 'LineWidth', 2); hold on;
plot(tE, step(TE_nz, tE), 'LineWidth', 2);
yline(1,'k--'); grid on;
xlabel('시간 [s]'); ylabel('출력');
legend('영점 있음 (실제)','영점 없음 (같은 극점)','목표','Location','southeast');
title('오버슈트를 만든 것은 극점이 아니라 영점');
nexttile
pzmap(TE); grid on;
title('폐루프 극점(x)과 영점(o)');

fprintf('  기억할 것\n');
fprintf('    감쇠비 -> 오버슈트 공식은 "극점 2 개, 영점 0 개" 일 때만 맞습니다.\n');
fprintf('    영점이 지배극점 가까이 있으면 오버슈트가 크게 늘어납니다.\n');
fprintf('    그래서 6단계 검증(stepinfo)이 반드시 필요합니다.\n\n');

%% 4-2. 오차는 PD 의 일이 아니다 - PI 로 풀기
%
%  PD 가 오차를 못 줄이는 이유는 간단합니다.
%
%      PD 는 시스템 타입을 바꾸지 못한다.
%
%  타입 0 은 PD 를 붙여도 타입 0 입니다. 오차는 1/(1+Kp) 로 남습니다.
%  Kp 를 20 배로 만들려면 이득을 20 배 써야 하고, 그러면 오버슈트가 터집니다.
%
%  오차를 없애는 방법은 하나뿐입니다. **적분기를 넣는다.**
%
%      PI 제어기 :  C(s) = K (s + a) / s
%
%  원점의 극점이 타입을 0 에서 1 로 올립니다. 계단 오차는 정확히 0 이 됩니다.

fprintf('=== 예제 E 의 정답 : PI 제어기 ===\n');
fprintf('    a      만족 K 구간       고른 K   OS[%%]   ts[s]    오차     max|u|\n');
fprintf('  -----  ----------------  --------  ------  ------  --------  -------\n');

pickE = [];
for a = [0.5 0.8 1.0]
    Ta = rl_scan((s+a)/s, GE, linspace(0.2, 25, 400), true);
    ok = Ta.stable & Ta.OS <= 20 & Ta.ts <= 6;
    if ~any(ok), fprintf('  %5.2f  없음\n', a); continue; end
    sub = Ta(ok,:);
    [~, j] = min(sub.ts);
    fprintf('  %5.2f  %6.2f ~ %-7.2f  %8.2f  %6.2f  %6.2f  %8.5f  %7.2f\n', ...
            a, min(sub.K), max(sub.K), sub.K(j), sub.OS(j), sub.ts(j), sub.ess(j), sub.umax(j));
    pickE(end+1,:) = [a sub.K(j) sub.OS(j) sub.ts(j) sub.umax(j)]; %#ok<SAGROW>
end

[~, jE] = min(pickE(:,3));
aE = pickE(jE,1);  KE = pickE(jE,2);
C_PI = KE*(s+aE)/s;
fprintf('\n  --> 고른 설계 : C(s) = %.2f (s + %.1f) / s\n', KE, aE);
fprintf('      오버슈트 %.2f %%, 정착시간 %.2f s, **오차 0**, 최대입력 %.2f\n\n', ...
        pickE(jE,3), pickE(jE,4), pickE(jE,5));

% P / PD / PI 세 설계를 한 그림에
TP_best = rl_scan(1, GE, linspace(0.2, 25, 500));
okP = TP_best.stable & TP_best.OS <= 20;
subP = TP_best(okP,:); [~, jP] = min(subP.ess);
KP = subP.K(jP);

tE2 = linspace(0, 8, 1000)';
figure('Name','P vs PD vs PI','Position',[120 120 950 400]);
plot(tE2, step(feedback(KP*GE,1), tE2), 'LineWidth', 2); hold on;
plot(tE2, step(TE, tE2), 'LineWidth', 2);
plot(tE2, step(feedback(C_PI*GE,1), tE2), 'LineWidth', 2.5);
yline(1, 'k--'); yline(0.95, 'r:'); grid on;
xlabel('시간 [s]'); ylabel('출력'); ylim([0 1.6]);
legend(sprintf('P     K = %.2f      (오차 %.0f %%)', KP, 100*subP.ess(jP)), ...
       sprintf('PD   z = %.1f K = %d  (오버슈트 %.0f %%)', zz, Kz, getfield(stepinfo(TE),'Overshoot')), ... %#ok<GFLD>
       sprintf('PI    a = %.1f K = %.2f (오차 0)', aE, KE), ...
       '목표', '오차 5 %% 선', 'Location','southeast');
title('오차는 적분기의 일, 과도응답은 미분의 일');

fprintf('  세 설계 비교\n');
fprintf('    P  : 오버슈트는 지켰지만 오차 %.0f %%\n', 100*subP.ess(jP));
fprintf('    PD : 오차는 지켰지만 오버슈트 %.0f %%\n', getfield(stepinfo(TE),'Overshoot')); %#ok<GFLD>
fprintf('    PI : 둘 다 지켰고 오차는 정확히 0\n');
fprintf('    --> 사양을 보고 도구를 고르십시오. 오차 사양이면 적분기입니다.\n\n');

%% 6. 이번 실습의 정리
%
%  PD 설계는 z 와 K 를 함께 고르는 일입니다. 정답이 하나가 아닙니다.
%  그래서 **표를 만들어 비교하고, 고른 이유를 말할 수 있어야** 합니다.
%
%  얻은 지침 네 가지
%
%    1) 같은 제어입력 예산 안에서는 영점을 왼쪽으로 옮길수록
%       필요한 이득이 줄고 정확도는 올라간다. 다만 무한정은 아니다.
%       z 가 너무 크면 사양을 만족하는 K 구간 자체가 사라진다
%       (이 한계는 W07_04 의 3-2 절에서 숫자로 확인합니다)
%
%    2) 영점을 플랜트 극점에 맞추면 그 극점이 사라진다.
%       안정한 극점이면 유용한 기법이고 어긋나도 큰일이 아니다.
%       그러나 불안정한 극점(우반면)을 상쇄하는 것은 절대 금지다.
%       종이 위에서만 사라지고 실제로는 그대로 발산한다
%
%    3) 감쇠비만 보고 오버슈트를 판단하면 안 된다.
%       영점이 가까우면 감쇠비 1 에서도 오버슈트가 40 % 나온다.
%       반드시 stepinfo 로 실측할 것
%
%    4) 오차 사양은 PD 로 풀지 말 것. 적분기(PI)를 쓰는 것이 정답이다.
%       PD 는 과도응답, PI 는 정상상태. 도구가 다르다
%
%  다음 실습 : W07_04_input_constrained.m
%              제어입력 한계를 정면으로 놓고 설계합니다.

fprintf('=== 정리 ===\n');
fprintf('  예제 D : 같은 제어입력 예산이면 z 가 클수록 정확하다 -> z = %g 선택\n', zD);
fprintf('  예제 E : PD 는 오차를 못 줄인다. 오차 사양은 PI 의 몫\n');
fprintf('\n  다음 : 제어입력 한계를 사양에 넣고 설계한다 -> W07_04\n');
