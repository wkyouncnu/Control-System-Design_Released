function [sysLin, p] = plant_pendulum(theta0, m, l, b)
%PLANT_PENDULUM  단진자 플랜트 (비선형 모델 + 지정한 동작점에서의 선형 모델)
%
%   3주차 "선형화" 실습의 기준 플랜트입니다.
%   강의자료 3_Modeling.pptx 의 Example 3-27 과 같은 시스템입니다.
%
%   [sysLin, p] = PLANT_PENDULUM()          theta0 = 0 (아래로 매달린 평형점)
%   [sysLin, p] = PLANT_PENDULUM(pi)        theta0 = pi (거꾸로 선 평형점)
%   [sysLin, p] = PLANT_PENDULUM(theta0, m, l, b)
%
%   출력
%     sysLin : 동작점 theta0 근처에서 선형화한 상태공간 모델 (ss 객체)
%              입력  = 토크 변화량   delta_u
%              출력  = 각도 변화량   delta_theta
%     p      : 파라미터 구조체
%              p.m, p.l, p.b, p.g, p.J     물리 파라미터
%              p.theta0, p.u0              동작점(평형점)의 상태와 입력
%              p.A, p.B, p.C, p.D          선형 모델 행렬
%              p.f                         비선형 상태방정식 함수핸들 @(x,u)
%
%   두 개의 평형점
%     이 진자에는 평형점이 두 개 있습니다.
%
%       theta0 = 0   : 아래로 매달린 상태.  건드리면 되돌아옵니다 -> 안정
%       theta0 = pi  : 거꾸로 선 상태.      건드리면 넘어갑니다   -> 불안정
%
%     같은 물리 시스템인데 어느 점 근처에서 선형화하느냐에 따라
%     완전히 다른 선형 모델이 나옵니다. 이것이 3주차의 핵심 메시지입니다.
%
%   선형화 방법
%     비선형 상태방정식은
%         x1' = x2
%         x2' = ( u - b*x2 - m*g*l*sin(x1) ) / J,      J = m*l^2
%
%     평형점 (theta0, u0) 근처에서 x1 = theta0 + dx1 로 두고
%     sin(theta0 + dx1) ~ sin(theta0) + cos(theta0)*dx1 로 근사하면
%
%         dx1' = dx2
%         dx2' = ( du - b*dx2 - m*g*l*cos(theta0)*dx1 ) / J
%
%     따라서
%         A = [        0                1   ;
%              -m*g*l*cos(theta0)/J   -b/J ]
%         B = [0; 1/J]
%
%   theta0 = 0 일 때 (b = 0 인 경우)
%     A 의 고유값이 +-j*sqrt(g/l) 로 순허수가 되어 극점 두 개가 허수축 위에
%     놓입니다. 강의자료 Example 3-27 의 결론과 정확히 같습니다.
%     감쇠가 없으니 영원히 진동합니다.
%
%   기본 감쇠계수를 0 으로 둔 이유
%     강의자료 예제와 숫자를 맞추기 위함이며, 동시에 3주차 Simulink 실습에서
%     "큰 각도에서는 비선형 진자의 주기가 길어진다"는 현상을 가장 뚜렷하게
%     보여주기 위해서입니다. 감쇠를 넣고 싶으면 네 번째 인자로 주십시오.
%
%   See also PENDULUM_ODE, PLANT_MSD, PLANT_DCMOTOR

% 제어시스템설계 | 충남대학교 자율운항시스템공학과

%% 기본값 처리
if nargin < 1 || isempty(theta0), theta0 = 0;    end   % 동작점 각도 [rad]
if nargin < 2 || isempty(m),      m      = 0.5;  end   % 추 질량 [kg]
if nargin < 3 || isempty(l),      l      = 0.3;  end   % 막대 길이 [m]
if nargin < 4 || isempty(b),      b      = 0;    end   % 감쇠계수 [N*m*s/rad]

g = 9.81;                 % 중력가속도 [m/s^2]
J = m * l^2;              % 관성모멘트 [kg*m^2]

%% 평형점에서 필요한 입력 토크
%  평형이란 x' = 0 인 상태입니다. x2 = 0 이고 x2' = 0 이어야 하므로
%      0 = u0 - b*0 - m*g*l*sin(theta0)
%  즉 중력 토크를 상쇄할 만큼의 토크를 계속 넣어 주어야 그 자세가 유지됩니다.
u0 = m * g * l * sin(theta0);

%% 선형화 (야코비안)
A = [                    0            1    ;
      -m*g*l*cos(theta0)/J        -b/J    ];
B = [0; 1/J];
C = [1 0];                % 각도를 측정한다고 가정
D = 0;

sysLin = ss(A, B, C, D);
sysLin.StateName  = {'delta_theta', 'delta_theta_dot'};
sysLin.InputName  = 'delta_u';
sysLin.OutputName = 'delta_theta';

%% 비선형 모델 함수핸들
%  스크립트에서 ode45 로 풀 때 사용합니다.
%  Simulink 의 MATLAB Function 블록도 같은 pendulum_ode 를 호출합니다.
p.f = @(x, u) pendulum_ode(x, u, m, l, b, g);

%% 파라미터 기록
p.m = m;  p.l = l;  p.b = b;  p.g = g;  p.J = J;
p.theta0 = theta0;
p.u0     = u0;
p.A = A;  p.B = B;  p.C = C;  p.D = D;
p.name = sprintf('단진자 (동작점 theta0 = %.4f rad = %.1f deg)', ...
                 theta0, rad2deg(theta0));

end
