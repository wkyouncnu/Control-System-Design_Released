function [K, Kr, info] = fsfb_design(sys, p_des, t)
%FSFB_DESIGN  상태궤환 극배치 + 정상상태 보정이득을 한 번에 구한다
%
%   [K, Kr, info] = FSFB_DESIGN(sys, p_des)
%   [K, Kr, info] = FSFB_DESIGN(sys, p_des, t)
%
%   무엇을 하는가
%     원하는 폐루프 극점 위치 p_des 를 주면
%
%       1) 가제어성을 먼저 확인하고            (안 되면 여기서 멈춥니다)
%       2) K 를 구하고            u = -K x + Kr r
%       3) 정상상태 오차를 없애는 Kr 을 구하고
%       4) 그 설계가 요구하는 **제어입력 크기**까지 계산해 돌려줍니다
%
%   왜 Kr 이 필요한가
%     상태궤환은 A 를 A - B*K 로 바꿔 **극점만** 옮깁니다.
%     직류이득은 건드리지 않으므로 계단 지령을 그대로 넣으면
%     출력이 엉뚱한 값에 수렴합니다. 그래서 앞단에 상수배를 하나 답니다.
%
%     $$K_r = \frac{1}{C\,(-(A-BK))^{-1}B}
%           = \frac{1}{\mathrm{dcgain}(A-BK,\;B,\;C,\;D)}$$
%
%   왜 제어입력까지 보는가
%     극을 왼쪽으로 보낼수록 응답이 빨라지지만 **공짜가 아닙니다.**
%     K 가 커지고 초기 제어입력이 커집니다. 실제 구동기는 그만큼 못 냅니다.
%     강의자료 10강 slide 106~108 의 control saturation 이 바로 이 이야기입니다.
%
%   입력
%     sys   - ss 객체 (A, B, C, D)
%     p_des - 원하는 폐루프 극점 벡터. 예: [-2 -4] 또는 [-2+2j, -2-2j]
%     t     - 제어입력을 계산할 시간 벡터 (생략하면 자동으로 잡습니다)
%
%   출력
%     K   - 상태궤환 이득 행렬 (1 x n)
%     Kr  - 앞단 보정이득 (스칼라)
%     info - .ctrb_rank .controllable .poles_open .poles_closed
%            .umax .OS .ts .method
%
%   place 와 acker 의 차이 (학생이 반드시 알아야 함)
%     - `place`  : 수치적으로 안정적. 다입력도 된다. **중근을 허용하지 않는다**
%     - `acker`  : Ackermann 공식 그대로. 중근도 되지만 **고차에서 수치가 나쁘다**
%     이 함수는 중근이 있으면 acker, 아니면 place 를 씁니다. info.method 로 알려 줍니다.
%
%   예제
%     [G, p] = plant_dcmotor('position');
%     sys = ss(p.A, p.B, p.C, p.D);
%     [K, Kr, info] = fsfb_design(sys, [-10 -12 -14]);
%
%   See also PLACE, ACKER, CTRB, OBSV_DESIGN
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

A = sys.A;  B = sys.B;  C = sys.C;  D = sys.D;
n = size(A,1);

%% 1) 가제어성 확인 — 이것이 안 되면 극배치는 불가능하다
Mc = ctrb(A, B);
r  = rank(Mc);
if r < n
    error('fsfb_design:가제어아님', ...
        ['가제어성 행렬의 계수가 %d 로 차수 %d 보다 작습니다. ' ...
         '극배치가 불가능합니다. 입력이 못 건드리는 상태가 있습니다.'], r, n);
end

%% 2) K 구하기
p_des = p_des(:).';
hasRepeat = numel(uniquetol(real(p_des) + 1i*imag(p_des), 1e-9)) < numel(p_des);
if hasRepeat
    K = acker(A, B, p_des);
    method = 'acker (중근이 있어서)';
else
    K = place(A, B, p_des);
    method = 'place';
end

%% 3) 정상상태 보정이득
Acl = A - B*K;
g0  = dcgain(ss(Acl, B, C, D));
if abs(g0) < eps
    Kr = NaN;
else
    Kr = 1/g0;
end

%% 4) 제어입력 크기
if nargin < 3 || isempty(t)
    tau = 1/max(abs(real(p_des)));
    t   = (0:tau/200:8*tau)';
end
t = t(:);

if isfinite(Kr)
    sysCl = ss(Acl, B*Kr, C, D);              % r -> y
    sysU  = ss(Acl, B*Kr, -K, Kr);            % r -> u
    y = step(sysCl, t);
    u = step(sysU,  t);
    ii = stepinfo(sysCl);
    OS = ii.Overshoot;  ts = ii.SettlingTime;
else
    y = []; u = [];  OS = NaN; ts = NaN;
end

info = struct( ...
    'ctrb_rank',     r, ...
    'controllable',  true, ...
    'poles_open',    eig(A).', ...
    'poles_closed',  eig(Acl).', ...
    'umax',          max(abs(u)), ...
    'OS',            OS, ...
    'ts',            ts, ...
    'method',        method, ...
    't',             t, ...
    'y',             y, ...
    'u',             u);
end
