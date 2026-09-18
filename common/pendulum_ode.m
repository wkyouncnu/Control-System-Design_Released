function dx = pendulum_ode(x, u, m, l, b, g)
%PENDULUM_ODE  단진자(simple pendulum)의 비선형 상태방정식
%
%   dx = PENDULUM_ODE(x, u, m, l, b, g)
%
%   입력
%     x : 상태벡터 [theta; theta_dot]
%         theta     = 아래쪽 수직으로부터 잰 각도 [rad]  (매달린 상태가 0)
%         theta_dot = 각속도 [rad/s]
%     u : 입력 토크 [N*m]
%     m : 추의 질량 [kg]
%     l : 막대 길이 [m]   (막대 자체는 무게가 없다고 가정)
%     b : 회전 감쇠계수 [N*m*s/rad]
%     g : 중력가속도 [m/s^2]
%
%   출력
%     dx : 상태의 시간미분 [theta_dot; theta_ddot]
%
%   운동방정식
%     막대에 작용하는 토크의 합이 관성모멘트 곱하기 각가속도와 같습니다.
%
%         J * theta'' = u - b*theta' - m*g*l*sin(theta)
%
%     여기서 관성모멘트는 J = m*l^2 입니다.
%     따라서
%
%         theta'' = ( u - b*theta' - m*g*l*sin(theta) ) / (m*l^2)
%
%   비선형인 이유
%     sin(theta) 항 때문입니다. theta 가 작을 때만 sin(theta) ~ theta 로
%     근사할 수 있고, 이것이 3주차에서 배우는 선형화의 핵심입니다.
%
%   중요
%     이 함수는 MATLAB 스크립트(ode45)와 Simulink 의 MATLAB Function 블록에서
%     똑같이 호출됩니다. 즉 두 실습이 완전히 같은 수식을 쓰고 있음이 보장됩니다.
%
%   See also PLANT_PENDULUM

% 제어시스템설계 | 충남대학교 자율운항시스템공학과

%#codegen

J = m * l^2;                                        % 관성모멘트 [kg*m^2]

theta     = x(1);
theta_dot = x(2);

theta_ddot = ( u - b*theta_dot - m*g*l*sin(theta) ) / J;

dx = [theta_dot; theta_ddot];

end
