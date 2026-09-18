function [G, p] = plant_dcmotor(mode)
%PLANT_DCMOTOR  DC 모터 표준 플랜트 (속도 제어용 / 위치 제어용)
%
%   이 과목에서 5~11주차 제어기 설계에 계속 사용하는 기준 플랜트입니다.
%
%   [G, p] = PLANT_DCMOTOR()            속도 모델 (기본값)
%   [G, p] = PLANT_DCMOTOR('speed')     속도 모델  : 입력 전압 -> 출력 각속도
%   [G, p] = PLANT_DCMOTOR('position')  위치 모델  : 입력 전압 -> 출력 각도
%
%   출력
%     G : 전달함수
%     p : 파라미터와 상태공간 행렬을 담은 구조체
%
%   물리 모델
%     전기 쪽 (키르히호프 전압법칙):
%         L*di/dt + R*i = V - Ke*w
%     기계 쪽 (뉴턴의 회전 운동방정식):
%         J*dw/dt + b*w = Kt*i
%
%     여기서
%         V  : 입력 전압 [V]          i : 전기자 전류 [A]
%         w  : 각속도 [rad/s]         Ke*w : 역기전력 [V]
%         Kt*i : 발생 토크 [N*m]
%
%     이 과목에서는 SI 단위계에서 Ke = Kt 이므로 둘 다 K 로 씁니다.
%
%   전달함수 (속도)
%         G(s) = w(s)/V(s) = K / ( (J*s + b)*(L*s + R) + K^2 )
%
%   전달함수 (위치)
%         각도 = 각속도의 적분이므로 위 식을 s 로 한 번 더 나눕니다.
%         G(s) = th(s)/V(s) = K / ( s * ( (J*s + b)*(L*s + R) + K^2 ) )
%
%   왜 이 두 모델을 구분하는가
%     속도 모델은 극점이 모두 좌반면에 있는 안정한 시스템(타입 0)이라
%     비례제어만으로도 잘 동작하지만 정상상태 오차가 남습니다.
%     위치 모델은 원점에 극점(적분기)이 하나 더 생겨 타입 1이 되므로
%     계단 입력에 대한 정상상태 오차가 0이 됩니다. 대신 위상여유가 줄어
%     안정도 문제가 생깁니다. 5주차 이후 이 대비를 계속 사용합니다.
%
%   파라미터 출처
%     MathWorks CTMS(Control Tutorials for MATLAB and Simulink) 표준값입니다.
%     예제코드 폴더의 MotorSpeed_SystemAnalysis.mlx 등과 숫자가 같으므로
%     학생이 그 튜토리얼과 결과를 직접 대조할 수 있습니다.
%
%   See also PLANT_MSD, PLANT_PENDULUM

% 제어시스템설계 | 충남대학교 자율운항시스템공학과

%% 입력 처리
if nargin < 1 || isempty(mode), mode = 'speed'; end
mode = lower(string(mode));

%% 물리 파라미터 (CTMS 표준값)
J = 0.01;    % 회전자 관성모멘트 [kg*m^2]
b = 0.1;     % 점성 마찰계수     [N*m*s]
K = 0.01;    % 토크상수 = 역기전력상수 [N*m/A] = [V*s/rad]
R = 1;       % 전기자 저항 [ohm]
L = 0.5;     % 전기자 인덕턴스 [H]

%% 전달함수
s = tf('s');
G_speed = K / ( (J*s + b)*(L*s + R) + K^2 );

switch mode
    case "speed"
        G = G_speed;
        G.InputName  = 'V';        % 입력: 전압 [V]
        G.OutputName = 'w';        % 출력: 각속도 [rad/s]

        % 상태공간: 상태 x = [각속도 w ; 전류 i]
        p.A = [ -b/J    K/J ;
                -K/L   -R/L ];
        p.B = [0; 1/L];
        p.C = [1 0];               % 각속도를 측정
        p.D = 0;
        p.states = {'w [rad/s]', 'i [A]'};

    case "position"
        G = G_speed / s;
        G.InputName  = 'V';        % 입력: 전압 [V]
        G.OutputName = 'theta';    % 출력: 각도 [rad]

        % 상태공간: 상태 x = [각도 th ; 각속도 w ; 전류 i]
        p.A = [ 0     1      0   ;
                0   -b/J    K/J  ;
                0   -K/L   -R/L ];
        p.B = [0; 0; 1/L];
        p.C = [1 0 0];             % 각도를 측정
        p.D = 0;
        p.states = {'theta [rad]', 'w [rad/s]', 'i [A]'};

    otherwise
        error('plant_dcmotor:badMode', ...
              'mode 는 ''speed'' 또는 ''position'' 이어야 합니다. 입력값: %s', mode);
end

%% 파라미터 기록
p.J = J;  p.b = b;  p.K = K;  p.R = R;  p.L = L;
p.mode = char(mode);
p.name = sprintf('DC 모터 (%s)', p.mode);

end
