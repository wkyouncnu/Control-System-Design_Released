%% W03_build_model.m
%  3주차 Simulink 모델 W03_Pendulum_NonlinVsLin.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 핵심 아이디어
%    위아래 두 경로가 블록 구성이 완전히 똑같습니다.
%    딱 하나, 위쪽에만 sin 블록이 들어 있습니다.
%
%      위쪽 (비선형) : ... -> [sin] -> [m*g*l] -> 합산
%      아래쪽 (선형) : ... ------------> [m*g*l] -> 합산
%
%    이 sin 블록 하나가 있고 없고가 비선형과 선형의 차이 전부입니다.
%    학생이 "선형화란 sin 을 떼어내는 것"이라고 눈으로 이해하게 만드는 것이 목적입니다.
%
%  제어시스템설계 3주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W03_Pendulum_NonlinVsLin';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

%% 공통 입력 : 토크
add_block('simulink/Sources/Constant', [name '/입력 토크'], ...
    'Position', [30 210 70 240], 'Value','u_torque');

%% ---------- 위쪽 : 비선형 진자 (진짜) ----------
add_block('simulink/Math Operations/Sum', [name '/토크 합산 비선형'], ...
    'Position', [140 55 160 75], 'Inputs','+--', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/관성으로 나누기 비선형'], ...
    'Position', [190 50 240 80], 'Gain','1/(m*l^2)');

add_block('simulink/Continuous/Integrator', [name '/적분 각가속도에서 각속도 비선형'], ...
    'Position', [270 50 300 80], 'InitialCondition','0');

add_block('simulink/Continuous/Integrator', [name '/적분 각속도에서 각도 비선형'], ...
    'Position', [340 50 370 80], 'InitialCondition','theta0');

add_block('simulink/Math Operations/Gain', [name '/감쇠 b 비선형'], ...
    'Position', [270 130 300 160], 'Gain','b', 'Orientation','left');

% 여기가 비선형의 정체입니다
add_block('simulink/Math Operations/Trigonometric Function', [name '/sin 여기가 비선형'], ...
    'Position', [330 180 380 210], 'Operator','sin', 'Orientation','left');

add_block('simulink/Math Operations/Gain', [name '/중력토크 비선형'], ...
    'Position', [250 180 300 210], 'Gain','m*g*l', 'Orientation','left');

add_block('simulink/Sinks/To Workspace', [name '/theta_nl'], ...
    'Position', [440 50 500 80], 'VariableName','theta_nl', 'SaveFormat','Timeseries');

%% ---------- 아래쪽 : 선형 근사 (sin 을 뗀 것) ----------
add_block('simulink/Math Operations/Sum', [name '/토크 합산 선형'], ...
    'Position', [140 335 160 355], 'Inputs','+--', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/관성으로 나누기 선형'], ...
    'Position', [190 330 240 360], 'Gain','1/(m*l^2)');

add_block('simulink/Continuous/Integrator', [name '/적분 각가속도에서 각속도 선형'], ...
    'Position', [270 330 300 360], 'InitialCondition','0');

add_block('simulink/Continuous/Integrator', [name '/적분 각속도에서 각도 선형'], ...
    'Position', [340 330 370 360], 'InitialCondition','theta0');

add_block('simulink/Math Operations/Gain', [name '/감쇠 b 선형'], ...
    'Position', [270 410 300 440], 'Gain','b', 'Orientation','left');

% 위쪽과 달리 sin 블록이 없습니다. 각도를 그대로 씁니다.
add_block('simulink/Math Operations/Gain', [name '/중력토크 선형'], ...
    'Position', [250 460 300 490], 'Gain','m*g*l', 'Orientation','left');

add_block('simulink/Sinks/To Workspace', [name '/theta_lin'], ...
    'Position', [440 330 500 360], 'VariableName','theta_lin', 'SaveFormat','Timeseries');

%% ---------- 비교용 ----------
add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [560 60 565 350], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/두 모델 비교'], ...
    'Position', [620 185 660 225]);

%% 신호선 연결
L = @(src, dst) add_line(name, src, dst, 'autorouting','smart');

% 비선형 경로
L('입력 토크/1',                          '토크 합산 비선형/1');
L('토크 합산 비선형/1',                   '관성으로 나누기 비선형/1');
L('관성으로 나누기 비선형/1',             '적분 각가속도에서 각속도 비선형/1');
L('적분 각가속도에서 각속도 비선형/1',    '적분 각속도에서 각도 비선형/1');
L('적분 각가속도에서 각속도 비선형/1',    '감쇠 b 비선형/1');
L('감쇠 b 비선형/1',                      '토크 합산 비선형/2');
L('적분 각속도에서 각도 비선형/1',        'sin 여기가 비선형/1');
L('sin 여기가 비선형/1',                  '중력토크 비선형/1');
L('중력토크 비선형/1',                    '토크 합산 비선형/3');
L('적분 각속도에서 각도 비선형/1',        'theta_nl/1');

% 선형 경로 (sin 만 없고 나머지는 똑같습니다)
L('입력 토크/1',                          '토크 합산 선형/1');
L('토크 합산 선형/1',                     '관성으로 나누기 선형/1');
L('관성으로 나누기 선형/1',               '적분 각가속도에서 각속도 선형/1');
L('적분 각가속도에서 각속도 선형/1',      '적분 각속도에서 각도 선형/1');
L('적분 각가속도에서 각속도 선형/1',      '감쇠 b 선형/1');
L('감쇠 b 선형/1',                        '토크 합산 선형/2');
L('적분 각속도에서 각도 선형/1',          '중력토크 선형/1');
L('중력토크 선형/1',                      '토크 합산 선형/3');
L('적분 각속도에서 각도 선형/1',          'theta_lin/1');

% 비교
L('적분 각속도에서 각도 비선형/1',        'Mux/1');
L('적분 각속도에서 각도 선형/1',          'Mux/2');
L('Mux/1',                                '두 모델 비교/1');

%% 신호 이름
set_param(get_param([name '/적분 각속도에서 각도 비선형'],'PortHandles').Outport(1), ...
          'Name','theta_nonlinear');
set_param(get_param([name '/적분 각속도에서 각도 선형'],'PortHandles').Outport(1), ...
          'Name','theta_linear');

%% 설명 주석 (슬래시는 쓸 수 없으니 주의)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['위쪽 = 진짜 진자 (비선형)' newline ...
     '중력 토크가 m*g*l*sin(theta) 이다.'];
a1.position = [560 20];

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['아래쪽 = 선형 근사' newline ...
     '중력 토크를 m*g*l*theta 로 바꿨다.' newline ...
     'sin 블록이 없다는 것 말고는 위와 완전히 같다.'];
a2.position = [560 380];

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['이 sin 블록 하나가' newline ...
     '비선형의 정체다.' newline ...
     '이것을 떼어내는 것이 선형화다.'];
a3.position = [330 230];

%% Scope 설정 : 실행하면 창이 자동으로 열리도록
cfg = get_param([name '/두 모델 비교'], 'ScopeConfiguration');
cfg.OpenAtSimulationStart = true;
cfg.ShowLegend            = true;
cfg.ShowGrid              = true;
cfg.Name                  = '비선형(진짜) vs 선형 근사';

%% 모델만 열어도 돌아가게 만들기
%  기본값은 60도에서 놓은 경우로 해 두었습니다.
%  모델을 열어 바로 실행하면 두 곡선이 뚜렷하게 갈라지는 모습이 보입니다.
%  theta0 를 deg2rad(5) 로 바꾸면 두 곡선이 겹칩니다.
preload = strjoin({ ...
 '% W03_Pendulum_NonlinVsLin 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 이미 워크스페이스에 값이 있으면 그대로 두고, 없을 때만 채웁니다.'
 'defs = { ''m'',0.5 ; ''l'',0.3 ; ''b'',0 ; ''g'',9.81 ;'
 '         ''u_torque'',0 ; ''theta0'',pi/3 ; ''t_end'',10 };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);

set_param(name, 'PreLoadFcn', preload);

%% 솔버
set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','0.01');


%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
%  고칠 일이 있으면 common/model_blocks.m 만 고치면 됩니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -260];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W03_04_run_simulink.m 로 하십시오.\n');
