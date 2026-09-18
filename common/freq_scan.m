function T = freq_scan(C1, G, Kvec, wantTime)
%FREQ_SCAN  이득을 훑으며 주파수영역 성능을 표로 만든다 (rl_scan 의 주파수판)
%
%   T = FREQ_SCAN(C1, G, Kvec)
%   T = FREQ_SCAN(C1, G, Kvec, wantTime)
%
%   무엇을 하는가
%     개루프를 L = K*C1*G 로 두고 K 를 하나씩 바꿔 가며
%     이득여유 · 위상여유 · 교차주파수 · 대역폭을 계산해 표로 돌려줍니다.
%     `margin` 을 손으로 여러 번 부르는 대신 표 하나를 보고 고르면 됩니다.
%
%   입력
%     C1       - **이득을 뺀** 제어기.  P 면 1, Lead 면 (T*s+1)/(a*T*s+1)
%     G        - 플랜트
%     Kvec     - 훑을 이득 값들 (예: logspace(0, 2, 100))
%     wantTime - true 면 폐루프 시간응답(오버슈트·정착시간)도 함께 계산.
%                기본값 true. false 로 두면 훨씬 빠릅니다.
%
%   출력 T 의 열
%     K       이득
%     stable  폐루프가 안정한가
%     GM      이득여유 [배율]      GMdB  이득여유 [dB]
%     PM      위상여유 [도]
%     wcp     이득교차주파수 (크기가 0 dB 인 곳) [rad/s]
%     BW      폐루프 대역폭 [rad/s]
%     OS      오버슈트 [%]        ts  정착시간 [s]        (wantTime 일 때만)
%
%   왜 C1 과 K 를 나누는가
%     근궤적에서와 같은 이유입니다. 궤적(또는 보드 선도의 모양)은 C1 과 G 가
%     정하고, K 는 그 모양을 위아래로 옮기기만 합니다.
%     **크기 곡선을 위로 올리면 여유가 줄어든다** 는 것이 이 표의 핵심입니다.
%
%   예제
%     s = tf('s');  G = 1/(s*(s+1)^2);
%     T = freq_scan(1, G, linspace(0.1, 3, 30));
%     T(T.PM >= 45, :)
%
%   See also RL_SCAN, MARGIN, BANDWIDTH, DG_MARGIN
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 4 || isempty(wantTime), wantTime = true; end

Kvec = Kvec(:);
n    = numel(Kvec);

K      = Kvec;
stable = false(n,1);
GM     = zeros(n,1);   GMdB = zeros(n,1);
PM     = zeros(n,1);   wcp  = zeros(n,1);
BW     = zeros(n,1);
OS     = nan(n,1);     ts   = nan(n,1);

% margin 은 폐루프가 불안정하면 경고를 냅니다. 표를 훑는 것이 목적이므로
% 여기서는 잠시 꺼 두고, 안정 여부는 stable 열로 알려 줍니다.
ws = warning('off', 'Control:analysis:MarginUnstable');
cleanupObj = onCleanup(@() warning(ws)); %#ok<NASGU>

for i = 1:n
    L = Kvec(i)*C1*G;

    [gm, pm, ~, wp] = margin(L);
    GM(i)   = gm;
    GMdB(i) = 20*log10(gm);
    PM(i)   = pm;
    if isempty(wp) || ~isfinite(wp), wcp(i) = NaN; else, wcp(i) = wp; end

    Tcl = feedback(L, 1);
    % 상쇄되는 극점을 남겨 두면 안정 판정과 사양 판정이 어긋난다 (rl_scan 과 같은 이유)
    Tcl = minreal(Tcl, 1e-4);
    stable(i) = all(real(pole(Tcl)) < 0);

    if stable(i)
        try
            BW(i) = bandwidth(Tcl);
        catch
            BW(i) = NaN;
        end
        if wantTime
            ii = stepinfo(Tcl);
            OS(i) = ii.Overshoot;
            ts(i) = ii.SettlingTime;
        end
    else
        BW(i) = NaN;
    end
end

T = table(K, stable, GM, GMdB, PM, wcp, BW, OS, ts);
T.Properties.VariableUnits = {'', '', '배', 'dB', '도', 'rad/s', 'rad/s', '%', 's'};
T.Properties.Description = '이득을 훑은 주파수영역 성능표 (freq_scan)';
end
