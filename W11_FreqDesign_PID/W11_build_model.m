%% W11_build_model.m
%  11주차 Simulink 모델 W11_PID_AntiWindup.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    PID 제어기를 **실제로 쓸 때 생기는 문제**를 보여 줍니다.
%
%    (1) 구동기에는 한계가 있다 (Saturation)
%    (2) 포화 중에도 적분기는 계속 쌓인다 -> **적분 와인드업**
%    (3) 처방은 포화 중에 적분을 멈추는 것 -> **anti-windup**
%
%    Simulink 의 PID Controller 블록은 이 세 가지를 블록 안에서 모두
%    처리해 줍니다. 그래서 이 모델은 블록 하나로 켜고 끄며 비교할 수 있습니다.
%
%    aw_mode 로 바꿉니다.
%      'none'             와인드업 그대로 (문제를 보여 주는 설정)
%      'clamping'         포화 중에 적분을 멈춘다
%      'back-calculation' 포화된 만큼을 적분기에서 빼 준다
%
%  제어시스템설계 11주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W11_PID_AntiWindup';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=170; X_PID=250; X_PL=420; X_OUT=610; X_MUX=720; X_SCP=790;
Y_MAIN=140; Y_U=300;

gp = @(x,y) [x, y-16, x+70, y+16];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-24, x+140, y+24];

%% 블록
add_block('simulink/Sources/Step', [name '/목표 속도 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Math Operations/Sum', [name '/오차 계산'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

% PID Controller : 포화와 anti-windup 을 블록 안에서 처리합니다
add_block('simulink/Continuous/PID Controller', [name '/PID'], ...
    'Position', [X_PID, Y_MAIN-30, X_PID+90, Y_MAIN+30], ...
    'P','Kp', 'I','Ki', 'D','Kd', 'N','Nf', ...
    'LimitOutput','on', ...
    'UpperSaturationLimit','u_max', 'LowerSaturationLimit','-u_max', ...
    'AntiWindupMode','none', 'Kb','Kb_gain');

% [주의] AntiWindupMode 는 목록에서 고르는 파라미터(enum)라
%        워크스페이스 변수 이름을 적을 수 없습니다.
%        바꾸려면 스크립트에서 set_param 을 직접 불러야 합니다.
%            set_param('W11_PID_AntiWindup/PID', 'AntiWindupMode', 'clamping')
%        고를 수 있는 값 : none, back-calculation, clamping, external

add_block('simulink/Continuous/Transfer Fcn', [name '/DC 모터'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y_U), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 속도'], ...
    'Position', [X_SCP, Y_MAIN-26, X_SCP+50, Y_MAIN+26]);

add_block('simulink/Sinks/Scope', [name '/Scope 전압'], ...
    'Position', [X_SCP, Y_U-26, X_SCP+50, Y_U+26]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('목표 속도 r/1',  '오차 계산/1');
L('오차 계산/1',    'PID/1');
L('PID/1',          'DC 모터/1');
L('DC 모터/1',      'y_sim/1');
L('DC 모터/1',      '오차 계산/2');
L('DC 모터/1',      'Mux/1');
L('목표 속도 r/1',  'Mux/2');
L('Mux/1',          'Scope 속도/1');
L('PID/1',          'u_sim/1');
L('PID/1',          'Scope 전압/1');

%% 신호 이름
set_param(get_param([name '/오차 계산'],'PortHandles').Outport(1), 'Name','e');
set_param(get_param([name '/PID'],'PortHandles').Outport(1),       'Name','u');
set_param(get_param([name '/DC 모터'],'PortHandles').Outport(1),   'Name','w');

%% Scope 설정
c1 = get_param([name '/Scope 속도'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '각속도와 목표값';

c2 = get_param([name '/Scope 전압'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowGrid = true;
c2.Name = '전압 (포화 확인)';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['PID Controller 블록은 포화와 anti-windup 을' newline ...
     '블록 안에서 처리합니다. 더블클릭해서 설정을 보십시오.' newline ...
     'Anti-windup method 를 none 과 clamping 으로 바꿔 비교해 보십시오.'];
a1.position = [X_PID-90, Y_MAIN-115];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['구동기 한계 u_max - 실제 모터 드라이버가 낼 수 있는 전압.' newline ...
     'r_amp 를 크게 하면 반드시 포화가 걸립니다.' newline ...
     '그때 적분기가 어떻게 되는지가 오늘의 주제입니다.'];
a2.position = [X_PL-60, Y_MAIN+75];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['PID Tuner 를 써 보려면 PID 블록을 더블클릭한 뒤' newline ...
     'Tune 버튼을 누르십시오. 응답 속도를 슬라이더로 바꿀 수 있습니다.'];
a3.position = [X_SRC, Y_MAIN+200];
a3.FontSize = 11;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W11_PID_AntiWindup 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 플랜트는 DC 모터 속도 모델 (CTMS 표준값)'
 'defs = { ''Kp'',60 ; ''Ki'',400 ; ''Kd'',0 ; ''Nf'',100 ;'
 '         ''r_amp'',1 ; ''u_max'',15 ; ''t_end'',2.5 ;'
 '         ''Kb_gain'',1 ;'
 '         ''numG'',0.01 ; ''denG'',[0.005 0.06 0.1001] };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name, 'PreLoadFcn', preload);

set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','0.002');

% 포화와 anti-windup 은 스위치가 켜졌다 꺼졌다 하는 비선형 요소라
% 경계 근처에서 영점교차(zero-crossing)가 수없이 반복되어 시뮬레이션이 멈출 수 있습니다.
% 적응형 알고리즘으로 바꾸면 그 자리를 알아서 넘어갑니다.
set_param(name, 'ZeroCrossAlgorithm','Adaptive', 'IgnoredZcDiagnostic','none');


%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
%  고칠 일이 있으면 common/model_blocks.m 만 고치면 됩니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -260];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W11_04_run_simulink.m 로 하십시오.\n');
