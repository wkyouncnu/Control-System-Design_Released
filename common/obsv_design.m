function [L, info] = obsv_design(sys, p_obs)
%OBSV_DESIGN  관측기 이득 L 을 구한다 (전치 트릭)
%
%   [L, info] = OBSV_DESIGN(sys, p_obs)
%
%   관측기란
%     상태를 전부 잴 수 없을 때, **같은 모델을 컴퓨터 안에서 함께 돌려서**
%     상태를 만들어 내는 장치입니다.
%
%     $$\dot{\hat{x}} = A\hat{x} + Bu + L\,(y - C\hat{x})$$
%
%     마지막 항이 핵심입니다. 실제로 잰 출력 y 와 내가 예상한 출력 C*xhat 이
%     다르면, 그 차이만큼 추정을 고칩니다. **오차를 보고 고친다** — 피드백입니다.
%
%   추정오차의 방정식
%     e = x - xhat 로 두고 두 식을 빼면
%
%     $$\dot{e} = (A - LC)\,e$$
%
%     입력 u 가 사라집니다. 즉 **무슨 입력을 넣든 추정오차는 스스로 줄어듭니다.**
%     단, A - LC 의 고유값이 전부 좌반면에 있어야 합니다.
%
%   전치 트릭 — 왜 place(A', C', p)' 인가
%     극배치는 `place(A, B, p)` 로 A - B*K 의 고유값을 옮깁니다.
%     우리가 원하는 것은 A - L*C 인데 모양이 다릅니다. 그런데
%
%       eig(A - LC) = eig( (A - LC)' ) = eig( A' - C'L' )
%
%     이므로 A' 를 A 로, C' 를 B 로, L' 를 K 로 놓으면 **똑같은 문제**가 됩니다.
%     그래서 `L = place(A', C', p_obs)'` 입니다. 전치를 두 번 하는 것이 전부입니다.
%
%   관측기 극을 얼마나 빠르게 잡는가
%     관례는 **제어기 극보다 2~5배 빠르게** 입니다.
%     - 너무 느리면 : 추정이 따라오기 전에 제어기가 틀린 값으로 일한다
%     - 너무 빠르면 : y 의 잡음을 그대로 증폭한다 (L 이 커지므로)
%     14주차에서 이 맞바꿈을 그림으로 확인합니다.
%
%   입력
%     sys   - ss 객체
%     p_obs - 원하는 관측기 극점 (A - LC 의 고유값)
%
%   출력
%     L    - 관측기 이득 (n x 1)
%     info - .obsv_rank .observable .poles_obs .method
%
%   See also FSFB_DESIGN, PLACE, ACKER, OBSV
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

A = sys.A;  C = sys.C;
n = size(A,1);

%% 가관측성 확인
Mo = obsv(A, C);
r  = rank(Mo);
if r < n
    error('obsv_design:가관측아님', ...
        ['가관측성 행렬의 계수가 %d 로 차수 %d 보다 작습니다. ' ...
         '출력만 보고는 알 수 없는 상태가 있어 관측기를 만들 수 없습니다.'], r, n);
end

%% 전치 트릭
p_obs = p_obs(:).';
hasRepeat = numel(uniquetol(real(p_obs) + 1i*imag(p_obs), 1e-9)) < numel(p_obs);
if hasRepeat
    L = acker(A.', C.', p_obs).';
    method = 'acker (중근이 있어서)';
else
    L = place(A.', C.', p_obs).';
    method = 'place';
end

info = struct( ...
    'obsv_rank',  r, ...
    'observable', true, ...
    'poles_obs',  eig(A - L*C).', ...
    'method',     method);
end
