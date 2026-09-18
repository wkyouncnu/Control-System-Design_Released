%% W11_02_lag_and_pi.m
%  11주차 실습 (2) : PI 와 Lag — 반대 방향의 도구
%
%  이 스크립트에서 답할 질문
%    Q1. PI 는 무엇을 고치고 무엇을 망치는가?      -> 1절
%    Q2. 적분기의 위치(1/Ti)를 어디에 두는가?      -> 2절
%    Q3. Lag 는 PI 와 무엇이 다른가?               -> 3절
%    Q4. Lag 설계 절차는?                          -> 4절
%    Q5. Lead 와 Lag 를 어떻게 고르는가?           -> 5절
%
%  대응하는 강의노트 : W11_LectureNote.mlx
%
%  제어시스템설계 11주차 | 충남대학교 자율운항시스템공학과

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

%% 1. PI 제어 — 강의자료 예제 7-4
%
%  Lead 는 **위상**을 벌었습니다. PI 와 Lag 는 **저주파 이득**을 법니다.
%
%  PI 제어기
%
%      D(s) = K*(1 + 1/(Ti*s)) = K*(Ti*s + 1)/(Ti*s)
%
%  원점에 극점이 하나 생기므로 **시스템 타입이 하나 올라갑니다.**
%  그래서 계단 입력에 대한 정상상태 오차가 0 이 됩니다.
%
%  대가는 무엇인가 — **저주파에서 위상을 90도까지 깎습니다.**
%  적분기가 원래 그렇습니다. 그래서 위상여유가 줄어듭니다.

G = 1/((s+1)*(s/5+1));         % 강의자료 예제 7-4 의 플랜트 (타입 0)

fprintf('=== 오늘의 플랜트 (타입 0) ===\n');
G
fprintf('  직류이득 %.4f -> 비례제어만으로는 계단 오차가 남습니다.\n\n', dcgain(G));

K = 10;
[~, pm_p] = margin(K*G);
e_ss = 1/(1 + dcgain(K*G));
fprintf('=== 비례제어 K = %d ===\n', K);
fprintf('  위상여유 %.2f 도\n', pm_p);
fprintf('  계단 정상상태 오차 %.4f  (= 1/(1+Kp), Kp = %.2f)\n', e_ss, dcgain(K*G));
fprintf('  --> 오차가 %.1f %% 남습니다. 없애려면 적분기가 필요합니다.\n\n', 100*e_ss);

%% 2. 적분기를 어디에 둘 것인가 — 1/Ti 의 위치
%
%  PI 의 영점은 s = -1/Ti 입니다. 이 위치가 설계의 전부입니다.
%
%    1/Ti 가 교차주파수보다 **훨씬 아래**  ->  교차주파수 근처에서는
%                                             적분기의 위상 깎임이 이미 끝나 있다
%                                             위상여유를 거의 안 잃는다
%    1/Ti 가 교차주파수에 **가까우면**    ->  위상을 크게 깎아
%                                             위상여유가 확 줄어든다
%
%  실무 지침은 **한 데케이드 아래** 입니다.

[~, ~, ~, wcp_p] = margin(K*G);
fprintf('=== 1/Ti 위치에 따른 위상여유 ===\n');
fprintf('  비례제어의 교차주파수 wcp = %.3f rad s^-1\n\n', wcp_p);
fprintf('     1 나누기 Ti    wcp 대비    위상여유[도]   계단 오차   오버슈트[%%]\n');
fprintf('   -------------  ----------  ------------  ----------  ------------\n');
for invTi = [0.1 0.6 1.5 3 6]
    Ti = 1/invTi;
    D_pi = K*(1 + 1/(Ti*s));
    [~, pmx] = margin(D_pi*G);
    Tcl = feedback(D_pi*G, 1);
    ii  = stepinfo(Tcl);
    fprintf('   %13.2f  %10.2f  %12.2f  %10.4f  %12.2f\n', ...
            invTi, invTi/wcp_p, pmx, 1-dcgain(Tcl), ii.Overshoot);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    어느 경우든 계단 오차는 0 입니다. 적분기가 있으니 당연합니다.\n');
fprintf('    그런데 1/Ti 를 교차주파수 가까이 올리면 위상여유가 급격히 줄어듭니다.\n');
fprintf('    강의자료 예제 7-4 도 정확히 이 이야기입니다.\n');
fprintf('      1/Ti = 0.6 (한 데케이드 아래) -> 위상여유 48 도에서 42 도로 조금만 줄어듦\n');
fprintf('      1/Ti = 3   (가까이)           -> 위상여유가 21 도로 확 줄어듦\n\n');

t = (0:0.01:6)';
figure('Name','PI 의 1/Ti 위치', 'Position',[80 80 950 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t, step(feedback(K*G,1), t), 'k--', 'LineWidth', 2, 'DisplayName','비례제어 (오차 남음)');
for invTi = [0.6 1.5 3]
    D_pi = K*(1 + invTi/s);
    [~, pmx] = margin(D_pi*G);
    plot(t, step(feedback(D_pi*G,1), t), 'LineWidth', 2, ...
         'DisplayName', sprintf('1/Ti = %.1f  (PM %.0f도)', invTi, pmx));
end
yline(1,'k:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('적분기를 넣으면 오차는 0. 대신 진동이 늘 수 있다');

nexttile
w = logspace(-2, 2, 500);
semilogx(w, unwrap(squeeze(angle(freqresp(K*G, w))))*180/pi, 'k--', 'LineWidth', 2); hold on; grid on;
for invTi = [0.6 1.5 3]
    D_pi = K*(1 + invTi/s);
    semilogx(w, unwrap(squeeze(angle(freqresp(D_pi*G, w))))*180/pi, 'LineWidth', 2);
end
yline(-180,'k:'); xline(wcp_p, ':', 'LineWidth', 1.8);
xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
legend('비례제어','1/Ti = 0.6','1/Ti = 1.5','1/Ti = 3.0','-180도','교차주파수', ...
       'Location','southwest');
title('1/Ti 가 교차주파수에 가까우면 위상을 많이 깎는다');

%% 3. Lag 는 PI 와 무엇이 다른가
%
%  PI 는 **원점에** 극점을 둡니다. 저주파 이득이 무한대가 되어 오차가 0 이 됩니다.
%  그런데 원점 극점은 불안정한 극점이라, 제어기 자체가 불안정합니다.
%  (7주차에서 배운 것과 같은 이야기입니다.)
%
%  Lag 는 그 극점을 **원점 아주 가까이**에 두되 원점은 아닙니다.
%
%      D(s) = K*(T*s + 1)/(beta*T*s + 1),     beta > 1
%
%    - 저주파 이득 : K (유한하다. 오차가 0 은 아니지만 아주 작다)
%    - 고주파 이득 : K/beta (1/beta 배로 줄어든다)
%
%  즉 **Lag 는 고주파를 낮추는 것**입니다. 저주파를 올리는 것이 아닙니다.
%  결과는 같습니다. 상대적으로 저주파가 높아지니까요.

beta_demo = 10;  T_demo = 1;
D_lag = (T_demo*s + 1)/(beta_demo*T_demo*s + 1);
D_pi_demo = (T_demo*s + 1)/(T_demo*s);

w = logspace(-3, 2, 600);
figure('Name','PI 와 Lag 비교', 'Position',[80 80 950 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
semilogx(w, 20*log10(squeeze(abs(freqresp(D_pi_demo, w)))), 'LineWidth', 2.2); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(D_lag, w)))), 'LineWidth', 2.2);
yline(0,'k--'); yline(-20*log10(beta_demo),'r:');
xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB]');
legend('PI (저주파에서 무한대)', 'Lag (고주파를 1/beta 로)', '0 dB', ...
       sprintf('-%.0f dB', 20*log10(beta_demo)), 'Location','southwest');
title('PI 는 저주파를 올리고, Lag 는 고주파를 내린다');

nexttile
semilogx(w, squeeze(angle(freqresp(D_pi_demo, w)))*180/pi, 'LineWidth', 2.2); hold on; grid on;
semilogx(w, squeeze(angle(freqresp(D_lag, w)))*180/pi, 'LineWidth', 2.2);
yline(0,'k--');
xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
legend('PI', 'Lag', 'Location','southeast');
title('둘 다 위상을 깎는다. 그래서 교차주파수에서 멀리 둔다');

fprintf('=== PI 와 Lag 의 저주파·고주파 이득 ===\n');
fprintf('                저주파 (w = 0.001)    고주파 (w = 100)\n');
fprintf('   ----------  --------------------  ------------------\n');
fprintf('   PI          %20.1f  %18.4f\n', ...
        abs(freqresp(D_pi_demo, 0.001)), abs(freqresp(D_pi_demo, 100)));
fprintf('   Lag         %20.4f  %18.4f\n', ...
        abs(freqresp(D_lag, 0.001)), abs(freqresp(D_lag, 100)));
fprintf('   --> Lag 의 고주파 이득은 정확히 1/beta = %.2f 입니다.\n\n', 1/beta_demo);

%% 4. Lag 설계 — 강의자료 예제 7-5
%
%      G(s) = 100/((s+1)*(0.2*s+1))
%      요구 : 위상여유 >= 40도, 계단 오차 <= 0.01
%
%  절차
%    1단계  정상상태 사양으로 K 를 정한다
%    2단계  위상이 -180 + PM_req + 여유분 이 되는 주파수를 찾는다  -> wc_new
%    3단계  그 자리의 크기가 A dB 이면 beta = 10^(A/20)
%    4단계  영점을 한 데케이드 아래에 :  T = 10/wc_new
%    5단계  검증

G2 = 100/((s+1)*(0.2*s+1));

fprintf('=== Lag 설계 : 강의자료 예제 7-5 ===\n');
fprintf('  플랜트 G = 100/((s+1)(0.2s+1)), 직류이득 %.1f\n', dcgain(G2));
fprintf('  계단 오차 = 1/(1+Kp) 이므로 0.01 이하이려면 Kp >= 99\n');
fprintf('  이미 Kp = %.0f 이므로 K = 1 로 충분합니다.\n', dcgain(G2));

K2 = 1;
[~, pm_before, ~, wcp_before] = margin(K2*G2);
fprintf('  그런데 그때 위상여유가 %.2f 도밖에 안 됩니다. (요구 40)\n\n', pm_before);

[D2, i2] = lag_design(K2, G2, 40, 8);

fprintf('  설계 결과\n');
fprintf('    새 교차주파수 wc_new = %.3f rad s^-1  (원래 %.3f)\n', i2.wc_new, wcp_before);
fprintf('    그 자리에서 낮춰야 할 크기 = %.2f dB\n', i2.attn_dB);
fprintf('    beta = %.3f , T = %.4f\n', i2.beta, i2.T);
fprintf('    영점 s = %.4f , 극점 s = %.5f\n', i2.zero, i2.pole);
fprintf('    위상여유 %.2f -> %.2f 도\n\n', i2.PM_before, i2.PM_after);

ii_b = stepinfo(feedback(K2*G2,1));
ii_a = stepinfo(feedback(D2*G2,1));
fprintf('              위상여유[도]   오버슈트[%%]   정착시간[s]   계단 오차\n');
fprintf('   ---------  ------------  ------------  -----------  ----------\n');
fprintf('   보상 전    %12.2f  %12.2f  %11.3f  %10.5f\n', ...
        i2.PM_before, ii_b.Overshoot, ii_b.SettlingTime, 1-dcgain(feedback(K2*G2,1)));
fprintf('   Lag 적용   %12.2f  %12.2f  %11.3f  %10.5f\n', ...
        i2.PM_after, ii_a.Overshoot, ii_a.SettlingTime, 1-dcgain(feedback(D2*G2,1)));
fprintf('\n');
ii_b2 = stepinfo(feedback(K2*G2,1));
ii_a2 = stepinfo(feedback(D2*G2,1));
fprintf('  상승시간과 대역폭까지 보면\n');
fprintf('              상승시간[s]   대역폭[rad s^-1]\n');
fprintf('   ---------  -----------  -----------------\n');
fprintf('   보상 전    %11.4f  %17.2f\n', ii_b2.RiseTime, bandwidth(feedback(K2*G2,1)));
fprintf('   Lag 적용   %11.4f  %17.2f\n\n', ii_a2.RiseTime, bandwidth(feedback(D2*G2,1)));

fprintf('  읽는 법\n');
fprintf('    오버슈트가 크게 줄었습니다. 대가는 **느려진 것**입니다.\n');
fprintf('    상승시간이 %.1f 배 길어졌고 대역폭은 %.1f 배로 좁아졌습니다.\n', ...
        ii_a2.RiseTime/ii_b2.RiseTime, ...
        bandwidth(feedback(D2*G2,1))/bandwidth(feedback(K2*G2,1)));
fprintf('    정착시간만 보면 오히려 좋아졌는데, 진동이 사라졌기 때문입니다.\n');
fprintf('    **한 숫자만 보고 판단하면 안 된다**는 좋은 예입니다.\n');
fprintf('    정상상태 오차는 그대로입니다. 저주파 이득을 안 건드렸으니까요.\n\n');

t2 = (0:0.005:4)';
figure('Name','Lag 설계 결과', 'Position',[80 80 950 440]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile
w2 = logspace(-2, 3, 600);
semilogx(w2, 20*log10(squeeze(abs(freqresp(K2*G2, w2)))), 'LineWidth', 2); hold on; grid on;
semilogx(w2, 20*log10(squeeze(abs(freqresp(D2*G2, w2)))), 'LineWidth', 2);
yline(0,'k--'); xline(i2.wc_new, ':', 'LineWidth', 1.8);
ylabel('크기 [dB]'); ylim([-60 60]);
legend('보상 전','Lag 적용','0 dB','새 교차주파수','Location','southwest');
title('고주파만 낮춘다. 저주파는 그대로');

nexttile
plot(t2, step(feedback(K2*G2,1), t2), 'LineWidth', 2); hold on; grid on;
plot(t2, step(feedback(D2*G2,1), t2), 'LineWidth', 2);
yline(1,'k--'); xlabel('시간 [s]'); ylabel('출력');
legend('보상 전','Lag 적용','Location','southeast');
title(sprintf('위상여유 %.0f -> %.0f 도', i2.PM_before, i2.PM_after));

nexttile
semilogx(w2, unwrap(squeeze(angle(freqresp(K2*G2, w2))))*180/pi, 'LineWidth', 2); hold on; grid on;
semilogx(w2, unwrap(squeeze(angle(freqresp(D2*G2, w2))))*180/pi, 'LineWidth', 2);
yline(-180,'k--'); xline(i2.wc_new, ':', 'LineWidth', 1.8);
xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
title('교차주파수가 왼쪽으로 가면 위상여유가 늘어난다');

nexttile
u_b2 = step(feedback(K2, G2), t2);
u_a2 = step(feedback(D2, G2), t2);
plot(t2, u_b2, 'LineWidth', 2); hold on; grid on;
plot(t2, u_a2, 'LineWidth', 2);
xlabel('시간 [s]'); ylabel('제어입력 u');
legend(sprintf('보상 전 (최대 %.2f)', max(abs(u_b2))), ...
       sprintf('Lag 적용 (최대 %.2f)', max(abs(u_a2))), 'Location','northeast');
title('Lag 는 제어입력을 오히려 줄인다');

%% 5. Lead 와 Lag 를 어떻게 고르는가
%
%  둘은 목적이 반대입니다. 표로 정리하면 이렇습니다.
%
%     항목            Lead                    Lag
%     -------------  ----------------------  ----------------------
%     하는 일        위상을 올린다            고주파 크기를 낮춘다
%     교차주파수     오른쪽으로 (빨라진다)    왼쪽으로 (느려진다)
%     대역폭         넓어진다                 좁아진다
%     잡음           **취약해진다**           **강해진다**
%     제어입력       커진다                   작아진다
%     정상상태 오차  거의 그대로              (Lag 자체는 그대로)
%
%  고르는 기준
%
%    빠르게 하고 싶다                 -> Lead
%    잡음이 심하다 / 구동기가 약하다  -> Lag
%    둘 다 필요하다                   -> Lead-Lag (PID 와 같은 역할)

fprintf('=== Lead 와 Lag 를 같은 플랜트에 ===\n');
G3 = 1/(s*(s+1));
K3 = 10;

[Dl, il] = lead_design(K3, G3, 55, 5);
[Dg, ig] = lag_design(K3, G3, 55, 8);

t3 = (0:0.01:8)';
fprintf('               위상여유[도]   대역폭[rad s^-1]   정착시간[s]   최대 |u|\n');
fprintf('   ---------  ------------  -----------------  -----------  ---------\n');
cases = { '보상 전', tf(K3); 'Lead', Dl; 'Lag', Dg };
for i = 1:3
    Ci = cases{i,2};
    [~, pmi] = margin(Ci*G3);
    Ti = feedback(Ci*G3, 1);
    ji = stepinfo(Ti);
    ui = step(feedback(Ci, G3), t3);
    fprintf('   %-9s  %12.2f  %17.3f  %11.2f  %9.1f\n', ...
            cases{i,1}, pmi, bandwidth(Ti), ji.SettlingTime, max(abs(ui)));
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    Lead 는 대역폭을 넓혀 빠르게 만들지만 제어입력이 커집니다.\n');
fprintf('    Lag 는 대역폭을 좁혀 느려지지만 제어입력이 작습니다.\n');
fprintf('    **같은 위상여유를 서로 다른 대가로 얻은 것입니다.**\n\n');

figure('Name','Lead vs Lag', 'Position',[80 80 950 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
for i = 1:3
    plot(t3, step(feedback(cases{i,2}*G3,1), t3), 'LineWidth', 2, 'DisplayName', cases{i,1});
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('같은 위상여유를 목표로 했을 때');
nexttile; hold on; grid on;
for i = 1:3
    plot(t3, step(feedback(cases{i,2}, G3), t3), 'LineWidth', 2, 'DisplayName', cases{i,1});
end
xlabel('시간 [s]'); ylabel('제어입력 u'); legend('Location','northeast');
title('대가는 제어입력에서 갈린다');

%% 6. 이번 실습의 정리
%
%   (1) PI 는 타입을 올려 계단 오차를 0 으로 만든다. 대신 위상을 깎는다
%   (2) 1/Ti 는 교차주파수보다 **한 데케이드 아래**에 둔다
%   (3) Lag 는 저주파를 올리는 것이 아니라 **고주파를 내리는** 것이다
%   (4) Lag 설계 : wc_new 찾기 -> beta 계산 -> T = 10/wc_new
%   (5) Lead 는 빠르게, Lag 는 조용하게. 대가가 서로 다르다
%
%  다음 실습
%    W11_03_pid_tuning.m — PID 와 자동 튜닝
