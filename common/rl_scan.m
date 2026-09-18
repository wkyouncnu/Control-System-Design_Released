function T = rl_scan(C1, G, Kvec, wantU)
%RL_SCAN  근궤적 위를 이득 K 로 훑으며 폐루프 성능을 표로 만든다
%
%   T = rl_scan(C1, G, Kvec)
%   T = rl_scan(C1, G, Kvec, wantU)
%
%   왜 필요한가
%     rlocfind 는 마우스로 궤적 위의 한 점을 찍는 명령입니다. 수업 중에
%     감을 잡기에는 좋지만 (1) 손이 떨리면 값이 달라지고 (2) 스크립트를
%     자동으로 돌릴 수 없습니다. 이 함수는 같은 일을 숫자로 합니다.
%     이득을 촘촘히 훑으면서 매번 폐루프를 닫고 성능을 재 표로 만듭니다.
%
%   원리
%     개루프를  L(s) = K * C1(s) * G(s)  로 보고
%     폐루프    T(s) = L / (1 + L)      를 K 마다 계산합니다.
%     극점은 pole 로, 과도응답 사양은 stepinfo 로, 정상상태 오차는
%     dcgain 으로 구합니다. 전부 1, 4, 5 주차에서 배운 명령입니다.
%
%   입력
%     C1    - 이득을 뺀 제어기.  P 제어면 1, PD 면 (s+z), Lead 면 (s+z)/(s+p)
%     G     - 플랜트 전달함수
%     Kvec  - 훑을 이득 벡터.  예 : linspace(0.1, 50, 500)
%     wantU - true 면 제어입력 최대치도 계산 (기본값 false, 조금 느려짐)
%
%   출력  T - table. 한 행이 이득 하나에 대응
%     K       이득
%     stable  폐루프가 안정한가 (극점이 전부 좌반면인가)
%     zeta    지배극점의 감쇠비        (실극점이면 1)
%     wn      지배극점의 고유진동수
%     OS      오버슈트 [%]            (stepinfo 실측값)
%     ts      정착시간 [s]            (2 % 기준)
%     Tp      첨두시간 [s]            (진동이 없으면 NaN)
%     ess     계단 정상상태 오차
%     umax    max|u(t)|               (wantU 가 false 면 NaN)
%
%   지배극점의 정의
%     허수축에 가장 가까운 극점, 즉 실수부가 가장 큰 극점입니다.
%     가장 늦게 사라지므로 응답의 모양을 결정합니다.
%
%   주의 : 영점에 지워지는 극점은 세지 않습니다
%     제어기 영점이 플랜트 극점과 같은 자리에 놓이면 그 극점은 응답에
%     나타나지 않습니다. 그런데 pole 명령은 그것까지 세어 버립니다.
%     그래서 이 함수는 minreal 로 상쇄되는 짝을 먼저 지웁니다.
%     지우지 않으면 "감쇠비 1 인데 오버슈트 45 %" 같은 이상한 표가 나옵니다.
%
%   예제
%     s = tf('s');  G = 1/((s+1)*(s+3));
%     T = rl_scan(1, G, linspace(0.5, 12, 200));
%     ok = T.OS <= 10 & T.ts <= 2;
%     fprintf('만족 구간 K = %.2f ~ %.2f\n', min(T.K(ok)), max(T.K(ok)));
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 4 || isempty(wantU), wantU = false; end
Kvec = Kvec(:);
n = numel(Kvec);

stable = false(n,1);
zeta   = nan(n,1);   wn  = nan(n,1);
OS     = nan(n,1);   ts  = nan(n,1);   Tp = nan(n,1);
ess    = nan(n,1);   umax = nan(n,1);

for i = 1:n
    K   = Kvec(i);
    L   = K * C1 * G;
    Tcl = feedback(L, 1);
    p   = pole(Tcl);

    stable(i) = all(real(p) < 0);
    if ~stable(i), continue; end

    % 지배극점 : 허수축에 가장 가까운 것
    % (영점에 지워지는 극점은 minreal 로 먼저 제거)
    pe = pole(minreal(Tcl, 1e-4));
    if isempty(pe), pe = p; end
    [~, ix] = max(real(pe));
    pd = pe(ix);
    wn(i) = abs(pd);
    if abs(imag(pd)) < 1e-8
        zeta(i) = 1;                       % 실극점 -> 진동 없음
    else
        zeta(i) = -real(pd) / abs(pd);
    end

    info   = stepinfo(Tcl);
    OS(i)  = info.Overshoot;
    ts(i)  = info.SettlingTime;
    if info.Overshoot > 1e-6
        Tp(i) = info.PeakTime;
    end
    ess(i) = 1 - dcgain(Tcl);

    if wantU
        try
            [~, ~, umax(i)] = ctrl_input(K*C1, G);
        catch
            umax(i) = NaN;
        end
    end
end

T = table(Kvec, stable, zeta, wn, OS, ts, Tp, ess, umax, ...
    'VariableNames', {'K','stable','zeta','wn','OS','ts','Tp','ess','umax'});
end
