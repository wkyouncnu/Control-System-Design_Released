%% W11_01_lead_design.m
%  11주차 실습 (1) : 주파수영역 Lead 보상기 설계
%
%  이 스크립트에서 답할 질문
%    Q1. 설계 절차는 무엇인가?                     -> 1절
%    Q2. PD 로 하면 왜 안 되는가?                  -> 2절
%    Q3. Lead 설계 5단계를 손으로 해 보면?          -> 3절
%    Q4. 강의자료 예제 7-2 를 재현할 수 있는가?     -> 4절
%    Q5. 한 단으로 안 되면 어떻게 하는가?           -> 5절
%    Q6. DC 모터에 적용하면?                        -> 6절
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

%% 1. 주파수영역 설계의 순서
%
%  7주차 근궤적 설계와 목적은 같습니다. 순서만 다릅니다.
%
%    근궤적       : 사양 -> 목표 극점 -> 궤적이 지나가게 만든다
%    주파수영역   : 사양 -> 목표 위상여유와 교차주파수 -> 보드 선도를 그렇게 만든다
%
%  주파수영역 설계는 항상 이 순서입니다.
%
%    1단계  **정상상태 사양**으로 이득 K 를 먼저 정한다
%           (이것은 저주파 이득이 정한다. 5주차의 오차상수)
%    2단계  그 K 로 위상여유를 재 본다
%    3단계  모자란 위상을 계산한다
%    4단계  그만큼 올려 주는 보상기를 설계한다
%    5단계  검증한다 (margin, step, 그리고 반드시 제어입력)
%
%  **1단계가 먼저인 이유** — 정상상태 사양은 저주파가 정하고, 위상여유는
%  교차주파수 근처가 정합니다. 서로 다른 주파수 대역이라 순서를 지키면
%  뒤 단계가 앞 단계를 망치지 않습니다.

%% 1-1. 강의자료 예제 7-1 의 설정
%
%      G(s) = 1 / (s*(s+1))
%      요구 : 단위 램프 입력에 대한 정상상태 오차 <= 0.01
%             위상여유 >= 50도

G = 1/(s*(s+1));

%% 1-2. 1단계 : 정상상태 사양으로 K 정하기
%
%  타입 1 시스템이므로 램프 오차는 1/Kv 입니다.
%
%      Kv = lim(s -> 0) s*K*G(s) = K
%
%  따라서 오차 0.01 이하이려면 K >= 100 입니다.

Kv_req = 1/0.01;
K = Kv_req;

fprintf('=== 1단계 : 정상상태 사양으로 K 정하기 ===\n');
fprintf('  요구 램프 오차 <= 0.01\n');
fprintf('  Kv = lim s*K*G = K 이므로 K >= %.0f\n', Kv_req);
fprintf('  K = %.0f 로 정합니다.\n', K);
fprintf('  확인 : Kv = %.2f, 램프 오차 = %.4f\n\n', ...
        dcgain(s*K*G), 1/dcgain(s*K*G));

%% 1-3. 2단계 : 그 K 로 위상여유를 재 본다

[gm0, pm0, ~, wcp0] = margin(K*G);
fprintf('=== 2단계 : 현재 위상여유 ===\n');
fprintf('  K = %.0f 일 때\n', K);
fprintf('    위상여유 %.2f 도   (요구 50 이상)\n', pm0);
fprintf('    교차주파수 %.3f rad s^-1\n', wcp0);
ii0 = stepinfo(feedback(K*G,1));
fprintf('    오버슈트 %.1f %%, 정착시간 %.2f s\n', ii0.Overshoot, ii0.SettlingTime);
fprintf('  --> 정상상태는 만족하지만 **위상여유가 턱없이 부족합니다.**\n');
fprintf('      이대로면 심하게 진동합니다.\n\n');

%% 2. PD 로 하면 왜 안 되는가
%
%  가장 먼저 떠오르는 것은 PD 입니다. 미분항이 위상을 올려 주기 때문입니다.
%
%      D(s) = K*(Td*s + 1)
%
%  실제로 위상여유는 좋아집니다. 그런데 문제가 있습니다.
%
%      **고주파에서 크기가 무한히 커집니다.**
%
%  크기가 20 dB/dec 로 계속 올라가므로 고주파 잡음이 그대로 증폭됩니다.
%  7주차에서 근궤적으로 배운 것과 정확히 같은 문제입니다.

w = logspace(-1, 4, 800);
figure('Name','PD 의 문제', 'Position',[80 80 900 470]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(w, 20*log10(squeeze(abs(freqresp(K*G, w)))), 'LineWidth', 2); hold on; grid on;
for Td = [0.05 0.1 0.2]
    D_pd = K*(Td*s + 1);
    semilogx(w, 20*log10(squeeze(abs(freqresp(D_pd*G, w)))), 'LineWidth', 1.8, ...
             'DisplayName', sprintf('PD  Td = %.2f', Td));
end
yline(0,'k--','HandleVisibility','off');
ylabel('크기 [dB]'); ylim([-80 80]);
legend('P 만 (K = 100)', 'PD  Td = 0.05', 'PD  Td = 0.10', 'PD  Td = 0.20', ...
       'Location','southwest');
title('PD 는 고주파에서 크기가 계속 올라간다 — 잡음이 증폭된다');

nexttile
semilogx(w, unwrap(squeeze(angle(freqresp(K*G, w))))*180/pi, 'LineWidth', 2); hold on; grid on;
for Td = [0.05 0.1 0.2]
    D_pd = K*(Td*s + 1);
    semilogx(w, unwrap(squeeze(angle(freqresp(D_pd*G, w))))*180/pi, 'LineWidth', 1.8);
end
yline(-180,'k--');
xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
title('위상은 확실히 올라간다. 이 부분만 취하고 싶다');

fprintf('=== PD 의 효과와 대가 ===\n');
fprintf('     Td      위상여유[도]   w = 1000 에서의 크기[dB]\n');
fprintf('   -------  -------------  ------------------------\n');
fprintf('   %7s  %13.2f  %24.2f\n', '없음', pm0, ...
        20*log10(abs(freqresp(K*G, 1000))));
for Td = [0.05 0.1 0.2]
    D_pd = K*(Td*s + 1);
    [~, pm_] = margin(D_pd*G);
    fprintf('   %7.2f  %13.2f  %24.2f\n', Td, pm_, ...
            20*log10(abs(freqresp(D_pd*G, 1000))));
end
fprintf('   --> 위상여유는 좋아지지만 고주파 크기가 함께 커집니다.\n');
fprintf('       Lead 는 **위상만 취하고 고주파 크기는 제한**한 것입니다.\n\n');

%% 3. Lead 설계 5단계
%
%  Lead 보상기는 이렇게 생겼습니다.
%
%      D(s) = K * (T*s + 1) / (alpha*T*s + 1),     0 < alpha < 1
%
%  PD 에 극점을 하나 붙인 것입니다. 그 극점이 고주파 크기를 1/alpha 배에서
%  멈추게 합니다.
%
%  설계는 다섯 단계입니다.
%
%    1단계  K 를 정한다                    (이미 했습니다. K = 100)
%    2단계  현재 위상여유를 잰다            (이미 했습니다. 5.7도)
%    3단계  모자란 각 phi 를 구한다
%             phi = PM_req - PM_now + 여유분(5~10도)
%    4단계  alpha = (1 - sin phi)/(1 + sin phi)
%    5단계  |K*G| 가 10*log10(alpha) dB 인 주파수를 wm 으로 잡고
%             T = 1/(wm*sqrt(alpha))

PM_req = 50;
extra  = 5;
phi    = PM_req - pm0 + extra;
alpha  = (1 - sind(phi))/(1 + sind(phi));

fprintf('=== 3~4단계 : 손으로 계산 ===\n');
fprintf('  요구 위상여유 %.0f 도, 현재 %.2f 도\n', PM_req, pm0);
fprintf('  모자란 각 phi = %.0f - %.2f + %.0f = %.2f 도\n', PM_req, pm0, extra, phi);
fprintf('  alpha = (1 - sin phi)/(1 + sin phi) = %.4f\n', alpha);
fprintf('  Lead 가 wm 에서 올려 주는 크기 = %.2f dB\n\n', -10*log10(alpha));

%% 3-1. 5단계에서 왜 그 주파수를 고르는가
%
%  Lead 는 wm = 1/(T*sqrt(alpha)) 에서
%
%    - 위상을 가장 많이 올린다 (정확히 phi 만큼)
%    - 크기를 1/sqrt(alpha) 배 (= -10*log10(alpha) dB) 올린다
%
%  보상 후 **그 주파수가 새 교차주파수(0 dB)가 되기를** 원합니다.
%  그러려면 보상 전 크기가 그만큼 아래에 있어야 합니다.
%  즉 |K*G| = 10*log10(alpha) dB 인 곳을 찾으면 됩니다.

target_dB = 10*log10(alpha);
m_KG = 20*log10(squeeze(abs(freqresp(K*G, w))));
idx  = find(m_KG >= target_dB, 1, 'last');
wm   = exp(interp1(m_KG(idx:idx+1), log(w(idx:idx+1)), target_dB));
T    = 1/(wm*sqrt(alpha));

fprintf('=== 5단계 : wm 과 T ===\n');
fprintf('  |K*G| 가 %.2f dB 인 주파수 wm = %.3f rad s^-1\n', target_dB, wm);
fprintf('  T = 1/(wm*sqrt(alpha)) = %.4f\n', T);
fprintf('  보상기의 영점 s = %.3f , 극점 s = %.3f\n\n', -1/T, -1/(alpha*T));

D_hand = K*(T*s + 1)/(alpha*T*s + 1);

%% 3-2. 공통 함수로 같은 일을 한 줄에
%
%  위의 다섯 단계를 lead_design 이 그대로 수행합니다.
%  손계산과 같은 값이 나오는지 확인합니다.

[D, info] = lead_design(K, G, PM_req, extra);

fprintf('=== 손계산 vs lead_design ===\n');
fprintf('           alpha        T         wm     설계후 PM[도]\n');
fprintf('  ------  --------  ---------  --------  -------------\n');
[~, pm_hand] = margin(D_hand*G);
fprintf('  손계산  %8.4f  %9.4f  %8.3f  %13.2f\n', alpha, T, wm, pm_hand);
fprintf('  함수    %8.4f  %9.4f  %8.3f  %13.2f\n\n', ...
        info.alpha, info.T, info.wm, info.PM_after);

%% 4. 검증 — 강의자료 예제 7-2 재현
%
%  강의자료 8강에서는 T = 0.17, alpha = 0.13 을 얻었습니다.
%  우리 계산과 비교해 봅시다. (손작도로 읽은 값이라 조금 다릅니다.)

D_ppt = K*(0.17*s + 1)/(0.13*0.17*s + 1);

fprintf('=== 강의자료 예제 7-2 와 비교 ===\n');
fprintf('             alpha       T      위상여유[도]   오버슈트[%%]   정착시간[s]\n');
fprintf('  ---------  ------  --------  ------------  ------------  -----------\n');
cands = { '보상 전', K,     NaN,   NaN
          '강의자료', D_ppt, 0.13,  0.17
          '우리 계산', D,     info.alpha, info.T };
for i = 1:3
    Ci = cands{i,2};
    [~, pmi] = margin(Ci*G);
    jj = stepinfo(feedback(Ci*G, 1));
    if isnan(cands{i,3})
        fprintf('  %-9s  %6s  %8s  %12.2f  %12.2f  %11.2f\n', ...
                cands{i,1}, '-', '-', pmi, jj.Overshoot, jj.SettlingTime);
    else
        fprintf('  %-9s  %6.3f  %8.4f  %12.2f  %12.2f  %11.2f\n', ...
                cands{i,1}, cands{i,3}, cands{i,4}, pmi, jj.Overshoot, jj.SettlingTime);
    end
end
fprintf('  --> 값이 조금 달라도 결과는 거의 같습니다.\n');
fprintf('      손작도로 읽는 값이라 정확할 필요가 없다는 뜻이기도 합니다.\n\n');

t = (0:0.002:1.2)';
figure('Name','Lead 설계 결과', 'Position',[80 80 950 440]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile
semilogx(w, 20*log10(squeeze(abs(freqresp(K*G, w)))), 'LineWidth', 2); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(D*G, w)))), 'LineWidth', 2);
yline(0,'k--'); ylim([-60 60]); ylabel('크기 [dB]');
legend('보상 전', 'Lead 적용', 'Location','southwest');
title('교차주파수가 오른쪽으로 간다 = 빨라진다');

nexttile
plot(t, step(feedback(K*G,1), t), 'LineWidth', 2); hold on; grid on;
plot(t, step(feedback(D*G,1), t), 'LineWidth', 2);
yline(1,'k--'); xlabel('시간 [s]'); ylabel('출력');
legend('보상 전', 'Lead 적용', 'Location','southeast');
title(sprintf('위상여유 %.0f -> %.0f 도', pm0, info.PM_after));

nexttile
semilogx(w, unwrap(squeeze(angle(freqresp(K*G, w))))*180/pi, 'LineWidth', 2); hold on; grid on;
semilogx(w, unwrap(squeeze(angle(freqresp(D*G, w))))*180/pi, 'LineWidth', 2);
yline(-180,'k--'); xline(info.wm, ':', 'LineWidth', 1.8);
ylim([-200 -60]); xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
title(sprintf('\\omega_m = %.1f 에서 %.0f도를 밀어 올린다', info.wm, info.phi));

nexttile
u_before = step(feedback(K, G), t);
u_after  = step(feedback(D, G), t);
plot(t, u_before, 'LineWidth', 2); hold on; grid on;
plot(t, u_after,  'LineWidth', 2);
xlabel('시간 [s]'); ylabel('제어입력 u');
legend(sprintf('보상 전 (최대 %.0f)', max(abs(u_before))), ...
       sprintf('Lead 적용 (최대 %.0f)', max(abs(u_after))), 'Location','northeast');
title('제어입력도 반드시 본다');

fprintf('=== 제어입력 비교 ===\n');
fprintf('  보상 전   최대 |u| = %.1f\n', max(abs(u_before)));
fprintf('  Lead 적용 최대 |u| = %.1f\n', max(abs(u_after)));
fprintf('  --> Lead 는 고주파 이득을 1/alpha = %.1f 배까지 올리므로\n', 1/info.alpha);
fprintf('      제어입력이 커집니다. 구동기 한계를 반드시 확인해야 합니다.\n\n');

%% 5. 한 단으로 안 될 때 — 강의자료 예제 7-3
%
%  Lead 한 단이 올릴 수 있는 위상은 실용적으로 60도 정도까지입니다.
%  alpha 가 작아질수록 고주파 이득이 감당할 수 없이 커지기 때문입니다.

fprintf('=== 한 단으로 얼마나 올릴 수 있는가 ===\n');
fprintf('     phi[도]    alpha     1/alpha (고주파 이득 배율)\n');
fprintf('   ---------  --------  ---------------------------\n');
for ph = [30 45 60 70 80]
    al = (1 - sind(ph))/(1 + sind(ph));
    fprintf('   %9.0f  %8.4f  %27.1f\n', ph, al, 1/al);
end
fprintf('   --> 70도를 넘기려면 고주파 이득을 30 배 이상 키워야 합니다.\n');
fprintf('       잡음 때문에 현실적이지 않습니다. **두 단으로 나눕니다.**\n\n');

% 3차 플랜트 : 강의자료 예제 7-3 과 같은 상황
%   G3 = 1/(s(s+1)(s/5+1)),  정상상태 사양으로 K = 5 가 정해졌다고 하자
%   목표 위상여유 55도
G3     = 1/(s*(s+1)*(s/5+1));
K3     = 5;
target = 55;

Dcum = tf(K3);                     % 지금까지 쌓인 보상기
t3   = (0:0.01:6)';
Ds   = {Dcum};  lbl = {sprintf('보상 전')};

fprintf('=== 단을 하나씩 늘려 가며 ===\n');
fprintf('     단 수   위상여유[도]    alpha    오버슈트[%%]   정착시간[s]   보상기 차수\n');
fprintf('   -------  ------------  --------  ------------  -----------  ------------\n');
[~, pm_k] = margin(Dcum*G3);
ii_k = stepinfo(feedback(Dcum*G3, 1));
fprintf('   %7d  %12.2f  %8s  %12.1f  %11.2f  %12d\n', 0, pm_k, '-', ...
        ii_k.Overshoot, ii_k.SettlingTime, order(Dcum));

for k = 1:3
    if k == 1
        [Dcum, ik] = lead_design(K3, G3, target, 5);
    else
        [Dk, ik] = lead_design(1, Dcum*G3, target, 5);   % 이미 쌓인 것 위에 한 단 더
        Dcum = Dcum * Dk;
    end
    [~, pm_k] = margin(Dcum*G3);
    ii_k = stepinfo(feedback(Dcum*G3, 1));
    fprintf('   %7d  %12.2f  %8.4f  %12.1f  %11.2f  %12d\n', ...
            k, pm_k, ik.alpha, ii_k.Overshoot, ii_k.SettlingTime, order(Dcum));
    Ds{end+1}  = Dcum;                               %#ok<SAGROW>
    lbl{end+1} = sprintf('Lead %d 단 (PM %.0f도)', k, pm_k); %#ok<SAGROW>
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    한 단으로는 목표 %d 도에 한참 못 미칩니다.\n', target);
fprintf('    단을 늘리면 좋아지지만 **계산한 만큼 다 나오지는 않습니다.**\n');
fprintf('    각 단이 교차주파수를 오른쪽으로 밀어 버려서, 그 자리의 플랜트 위상이\n');
fprintf('    또 떨어져 있기 때문입니다. 그래서 **반복해서 다시 설계**해야 합니다.\n');
fprintf('    보상기 차수도 함께 올라갑니다. 무한정 늘릴 수는 없습니다.\n\n');

figure('Name','Lead 를 여러 단으로', 'Position',[80 80 900 400]);
hold on; grid on;
lbl{1} = sprintf('보상 전 (PM %.0f도)', 3.94);
for k = 1:numel(Ds)
    plot(t3, step(feedback(Ds{k}*G3, 1), t3), 'LineWidth', 2);
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); ylim([0 2]);
legend(lbl, 'Location','southeast');
title('한 단으로 모자라면 나눠서 올린다 (수확은 점점 줄어든다)');

%% 6. DC 모터에 적용
%
%  학기 내내 쓰던 DC 모터 위치 모델에 같은 절차를 적용합니다.
%
%  사양 : 위상여유 >= 60도, 램프 오차 <= 0.5 rad
%
%  램프 오차 사양을 왜 이렇게 느슨하게 잡는가 — 이 플랜트는 s*G 의 직류이득이
%  0.1 밖에 안 되어서, 오차를 줄이려면 K 를 크게 키워야 하고
%  그러면 위상여유가 남아나지 않기 때문입니다.
%  **사양끼리 충돌할 수 있다**는 것을 여기서 한 번 확인해 둡니다.

Gm = plant_dcmotor('position');

Kv_need = 1/0.5;
Km = Kv_need / dcgain(s*Gm);     % s*Gm 의 직류이득이 1 이 아니므로 나눠 준다

fprintf('=== DC 모터 위치제어에 적용 ===\n');
fprintf('  요구 램프 오차 <= 0.5  ->  Kv >= %.0f\n', Kv_need);
fprintf('  s*G 의 직류이득 = %.4f 이므로 K = %.2f\n', dcgain(s*Gm), Km);
fprintf('  확인 : Kv = %.2f, 램프 오차 = %.4f\n\n', ...
        dcgain(s*Km*Gm), 1/dcgain(s*Km*Gm));

fprintf('  참고 : 오차 사양을 더 조이면 어떻게 되는가\n');
fprintf('     요구 오차   필요한 K   그때의 위상여유[도]\n');
fprintf('    ----------  ---------  --------------------\n');
ws2 = warning('off','Control:analysis:MarginUnstable');
for e_req = [1.0 0.5 0.3 0.2 0.1]
    Kx = (1/e_req)/dcgain(s*Gm);
    [~, pmx] = margin(Kx*Gm);
    fprintf('    %10.2f  %9.1f  %20.2f\n', e_req, Kx, pmx);
end
warning(ws2);
fprintf('    --> 오차를 조일수록 위상여유가 사라집니다. 이것이 맞바꿈입니다.\n\n');

[Dm, im] = lead_design(Km, Gm, 60, 8);
jj_before = stepinfo(feedback(Km*Gm,1));
jj_after  = stepinfo(feedback(Dm*Gm,1));

fprintf('\n              위상여유[도]   오버슈트[%%]   정착시간[s]   최대 |u|[V]\n');
fprintf('  ---------  ------------  ------------  -----------  ------------\n');
tm = (0:0.002:2)';
u_b = step(feedback(Km, Gm), tm);
u_a = step(feedback(Dm, Gm), tm);
fprintf('  보상 전    %12.2f  %12.2f  %11.2f  %12.1f\n', ...
        im.PM_before, jj_before.Overshoot, jj_before.SettlingTime, max(abs(u_b)));
fprintf('  Lead 적용  %12.2f  %12.2f  %11.2f  %12.1f\n', ...
        im.PM_after, jj_after.Overshoot, jj_after.SettlingTime, max(abs(u_a)));
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    Lead 를 넣으면 오버슈트가 줄고 빨라집니다.\n');
fprintf('    대신 제어입력이 커집니다. 24 V 드라이버로 감당되는지 확인해야 합니다.\n\n');

figure('Name','DC 모터 Lead 설계', 'Position',[80 80 900 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
plot(tm, step(feedback(Km*Gm,1), tm), 'LineWidth', 2); hold on; grid on;
plot(tm, step(feedback(Dm*Gm,1), tm), 'LineWidth', 2);
yline(1,'k--'); xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('보상 전', 'Lead 적용', 'Location','southeast');
title('DC 모터 위치제어');
nexttile
plot(tm, u_b, 'LineWidth', 2); hold on; grid on;
plot(tm, u_a, 'LineWidth', 2);
yline(24,'r:'); yline(-24,'r:');
xlabel('시간 [s]'); ylabel('제어입력 [V]');
legend('보상 전', 'Lead 적용', '24 V 한계', 'Location','northeast');
title('제어입력이 한계를 넘지 않는가');

%% 7. 이번 실습의 정리
%
%   (1) 주파수영역 설계는 항상 **정상상태 사양으로 K 부터** 정한다
%   (2) PD 는 위상을 올리지만 고주파 크기도 함께 올린다
%   (3) Lead 는 PD 에 극점을 붙여 고주파 이득을 1/alpha 로 제한한 것이다
%   (4) 5단계 : phi -> alpha -> wm -> T -> 검증
%   (5) 한 단으로 60도 이상은 무리다. 두 단으로 나눈다
%   (6) 설계 후에는 반드시 **제어입력**을 확인한다
%
%  다음 실습
%    W11_02_lag_and_pi.m — 반대 방향의 도구 : PI 와 Lag
