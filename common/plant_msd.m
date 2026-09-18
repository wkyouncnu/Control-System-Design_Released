function [G, p] = plant_msd(m, b, k)
%PLANT_MSD  질량-스프링-댐퍼(Mass-Spring-Damper) 표준 플랜트
%
%   이 과목에서 1~5주차에 계속 사용하는 기준 플랜트입니다.
%   매 주차마다 파라미터를 다시 적지 않고 이 함수 하나만 부르면 되도록 만들었습니다.
%
%   [G, p] = PLANT_MSD()            기본값 (m=1, b=0.2, k=1)
%   [G, p] = PLANT_MSD(m, b, k)     파라미터를 직접 지정
%   [G, p] = PLANT_MSD([], 1.0, []) 일부만 바꾸고 나머지는 기본값
%
%   출력
%     G : 전달함수  G(s) = X(s)/F(s) = 1 / (m*s^2 + b*s + k)
%     p : 파라미터와 상태공간 행렬을 담은 구조체
%         p.m, p.b, p.k          물리 파라미터
%         p.A, p.B, p.C, p.D     상태공간 행렬  (상태 x = [위치; 속도])
%         p.wn, p.zeta           고유진동수 [rad/s], 감쇠비 [-]
%
%   물리 모델
%     질량 m 에 스프링(k)과 댐퍼(b)가 붙어 있고, 외력 F(t)를 가하면
%
%         m*x'' + b*x' + k*x = F
%
%     여기서 x는 평형위치로부터의 변위입니다.
%     양변을 라플라스 변환하면 (초기조건 0)
%
%         (m*s^2 + b*s + k) * X(s) = F(s)
%
%     이므로 전달함수는 G(s) = 1 / (m*s^2 + b*s + k) 가 됩니다.
%
%   기본값의 의미
%     m=1, b=0.2, k=1 이면 wn = 1 rad/s, zeta = 0.1 인 부족감쇠 2차 시스템입니다.
%     감쇠비가 0.1로 작아서 진동이 오래 남습니다. 시간응답 관찰에 좋은 값입니다.
%
%   참고: 이 값은 기존 예제코드 3_Modeling/MSD_example.m 및 강의자료
%         3_Modeling.pptx 와 동일한 값입니다.
%
%   See also PLANT_DCMOTOR, PLANT_PENDULUM

% 제어시스템설계 | 충남대학교 자율운항시스템공학과

%% 기본값 처리
if nargin < 1 || isempty(m), m = 1.0;  end   % 질량 [kg]
if nargin < 2 || isempty(b), b = 0.2;  end   % 감쇠계수 [N*s/m]
if nargin < 3 || isempty(k), k = 1.0;  end   % 스프링 상수 [N/m]

%% 전달함수
s = tf('s');
G = 1 / (m*s^2 + b*s + k);
G.InputName  = 'F';      % 입력: 힘 [N]
G.OutputName = 'x';      % 출력: 변위 [m]

%% 상태공간 표현
%  상태를 x1 = 위치, x2 = 속도 로 잡으면
%     x1' = x2
%     x2' = (F - b*x2 - k*x1)/m
%  이므로 아래 행렬이 나옵니다.
p.A = [   0     1 ;
       -k/m  -b/m ];
p.B = [0; 1/m];
p.C = [1 0];             % 위치를 측정한다고 가정
p.D = 0;

%% 2차 시스템 표준형 파라미터
%  G(s) = (1/m) / (s^2 + (b/m)s + k/m) 을 표준형 wn^2/(s^2+2*zeta*wn*s+wn^2)
%  과 비교하면 아래와 같습니다.
p.wn   = sqrt(k/m);              % 고유진동수 [rad/s]
p.zeta = b / (2*sqrt(m*k));      % 감쇠비 [-]

%% 파라미터 기록
p.m = m;
p.b = b;
p.k = k;
p.name = '질량-스프링-댐퍼 (MSD)';

end
