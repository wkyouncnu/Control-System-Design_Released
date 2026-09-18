%% W05_build_model.m
%  5주차 Simulink 모델 W05_SteadyStateError.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 구성
%    DC 모터 속도제어(타입 0)에 PI 제어기를 붙였습니다.
%
%        u = Kp*e + Ki*(e 의 적분)
%
%    Ki 를 0 으로 두면 순수 비례제어가 되어 정상상태 오차가 남고,
%    Ki 를 0 이 아닌 값으로 두면 적분기가 붙어 오차가 사라집니다.
%
%    즉 게인 하나만 바꿔서 "적분기의 효과" 를 켜고 끌 수 있습니다.
%    이것이 이 모델의 목적입니다.
%
%  제어시스템설계 5주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W05_SteadyStateError';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=150; X_P=250; X_I1=250; X_I2=340; X_SUM=430; X_PL=500;
X_OUT=650; X_MUX=760; X_SCP=830;
Y_MAIN=130; Y_INT=250; Y_ERR=380;

gp = @(x,y) [x, y-15, x+60, y+15];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-22, x+120, y+22];

%% 블록
add_block('simulink/Sources/Step', [name '/목표 각속도 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Math Operations/Sum', [name '/오차 e'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

% 비례 경로
add_block('simulink/Math Operations/Gain', [name '/비례이득 Kp'], ...
    'Position', gp(X_P, Y_MAIN), 'Gain','Kp');

% 적분 경로 : Ki 를 0 으로 두면 이 경로가 꺼진 것과 같다
add_block('simulink/Continuous/Integrator', [name '/적분기'], ...
    'Position', gp(X_I1, Y_INT), 'InitialCondition','0');

add_block('simulink/Math Operations/Gain', [name '/적분이득 Ki'], ...
    'Position', gp(X_I2, Y_INT), 'Gain','Ki');

add_block('simulink/Math Operations/Sum', [name '/제어입력 u'], ...
    'Position', sp(X_SUM, Y_MAIN), 'Inputs','++', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/DC 모터 속도 모델'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/e_sim'], ...
    'Position', gp(X_OUT, Y_ERR), 'VariableName','e_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 출력'], ...
    'Position', [X_SCP, Y_MAIN-25, X_SCP+50, Y_MAIN+25]);

add_block('simulink/Sinks/Scope', [name '/Scope 오차'], ...
    'Position', [X_SCP, Y_ERR-25, X_SCP+50, Y_ERR+25]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('목표 각속도 r/1',      '오차 e/1');
L('오차 e/1',             '비례이득 Kp/1');
L('오차 e/1',             '적분기/1');
L('적분기/1',             '적분이득 Ki/1');
L('비례이득 Kp/1',        '제어입력 u/1');
L('적분이득 Ki/1',        '제어입력 u/2');
L('제어입력 u/1',         'DC 모터 속도 모델/1');
L('DC 모터 속도 모델/1',  'y_sim/1');
L('DC 모터 속도 모델/1',  '오차 e/2');
L('DC 모터 속도 모델/1',  'Mux/1');
L('목표 각속도 r/1',      'Mux/2');
L('Mux/1',                'Scope 출력/1');
L('오차 e/1',             'e_sim/1');
L('오차 e/1',             'Scope 오차/1');

%% 신호 이름
set_param(get_param([name '/오차 e'],'PortHandles').Outport(1), 'Name','e');
set_param(get_param([name '/제어입력 u'],'PortHandles').Outport(1), 'Name','u');
set_param(get_param([name '/DC 모터 속도 모델'],'PortHandles').Outport(1), 'Name','w');

%% Scope 설정
c1 = get_param([name '/Scope 출력'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '각속도 : 목표 vs 실제';

c2 = get_param([name '/Scope 오차'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowGrid = true;
c2.Name = '오차 신호 추이';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['PI 제어기' newline ...
     'u = Kp*e + Ki*(e 의 적분)' newline ...
     'Ki 를 0 으로 두면 순수 비례제어가 된다.'];
a1.position = [X_P-30, Y_MAIN-95];
a1.FontSize = 11;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['이 적분 경로가 정상상태 오차를 없앤다.' newline ...
     '오차가 0 이 되어도 쌓인 값이 남아 계속 힘을 내기 때문이다.' newline ...
     '단, 적분기를 넣으면 불안정해지기 쉽다. Ki 를 너무 키우지 말 것.'];
a2.position = [X_I1-40, Y_INT+45];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['그냥 열어서 Ctrl+T 로 실행해도 됩니다.' newline ...
     '기본값은 Ki = 0 (비례제어) 이라 오차가 남아 있는 것이 보입니다.' newline ...
     'Ki 를 5 로 바꾸면 오차가 사라집니다.'];
a3.position = [X_SRC, Y_MAIN-165];
a3.FontSize = 12;

%% 모델만 열어도 돌아가게
%  numG, denG 는 DC 모터 속도 모델의 계수입니다.
preload = strjoin({ ...
 '% W05_SteadyStateError 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 기본값은 Ki = 0 : 비례제어만 -> 정상상태 오차가 남는 것을 보여 줍니다.'
 'defs = { ''Kp'',50 ; ''Ki'',0 ; ''r_amp'',10 ; ''t_end'',5 ;'
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
                'SolverType','Variable-step', 'MaxStep','0.005');


%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
%  고칠 일이 있으면 common/model_blocks.m 만 고치면 됩니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -260];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W05_03_run_simulink.m 로 하십시오.\n');
