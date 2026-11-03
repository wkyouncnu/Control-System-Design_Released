%% W09_build_rc_model.m
%  9주차 Simulink 모델 W09_RC_SineCompare.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    교수자 강의자료 3쪽의 Simulink 예제(Ch6_Bode_plot_Sine_wave.slx)를
%    그대로 다시 만든 것입니다.
%
%    같은 RC 회로에 주파수만 다른 사인 두 개를 **동시에** 넣습니다.
%      위쪽 줄 : 1 Hz 사인  ->  1/(0.1s+1)  ->  Scope
%      아래 줄 : 3 Hz 사인  ->  1/(0.1s+1)  ->  Scope
%
%    두 Scope 를 나란히 보면 "같은 회로인데 주파수가 다르면 답이 다르다" 는
%    주파수응답의 정의가 눈으로 보입니다.
%      1 Hz 에서는 크기 0.847, 위상 -32도   (거의 그대로 통과)
%      3 Hz 에서는 크기 0.469, 위상 -62도   (절반 이하로 줄고 더 늦는다)
%
%    회로 값은 강의자료와 같습니다.
%      R = 100 Ohm, C = 0.001 F  ->  tau = R*C = 0.1 s
%      G(s) = 1 / (R*C*s + 1) = 1 / (0.1s + 1)
%
%  왜 W09_SineSweep.slx 와 따로 두는가
%    W09_SineSweep 는 주파수를 logspace 로 훑어 보드 선도 전체를 만드는 모델이고,
%    이 모델은 강의자료처럼 주파수 두 개만 나란히 비교하는 모델입니다.
%    목적이 다르므로 섞지 않습니다.
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W09_RC_SineCompare';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC = 60; X_PL = 240; X_MUX = 470; X_SCP = 550; X_OUT = 240;
Y_1HZ = 140; Y_3HZ = 320;

gp = @(x,y) [x, y-16, x+90, y+16];
tp = @(x,y) [x, y-24, x+150, y+24];

%% 블록 — 위쪽 줄 (1 Hz)
add_block('simulink/Sources/Sine Wave', [name '/1Hz 사인'], ...
    'Position', gp(X_SRC, Y_1HZ), ...
    'Amplitude','A_in', 'Frequency','w1', 'Phase','0');

add_block('simulink/Continuous/Transfer Fcn', [name '/RC 회로 1Hz'], ...
    'Position', tp(X_PL, Y_1HZ), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Signal Routing/Mux', [name '/Mux 1Hz'], ...
    'Position', [X_MUX, Y_1HZ-40, X_MUX+5, Y_1HZ+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 1Hz'], ...
    'Position', [X_SCP, Y_1HZ-26, X_SCP+50, Y_1HZ+26]);

add_block('simulink/Sinks/To Workspace', [name '/y1'], ...
    'Position', gp(X_OUT, Y_1HZ+80), 'VariableName','y1', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u1'], ...
    'Position', gp(X_SRC, Y_1HZ+80), 'VariableName','u1', 'SaveFormat','Timeseries');

%% 블록 — 아래 줄 (3 Hz)
add_block('simulink/Sources/Sine Wave', [name '/3Hz 사인'], ...
    'Position', gp(X_SRC, Y_3HZ), ...
    'Amplitude','A_in', 'Frequency','w3', 'Phase','0');

add_block('simulink/Continuous/Transfer Fcn', [name '/RC 회로 3Hz'], ...
    'Position', tp(X_PL, Y_3HZ), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Signal Routing/Mux', [name '/Mux 3Hz'], ...
    'Position', [X_MUX, Y_3HZ-40, X_MUX+5, Y_3HZ+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 3Hz'], ...
    'Position', [X_SCP, Y_3HZ-26, X_SCP+50, Y_3HZ+26]);

add_block('simulink/Sinks/To Workspace', [name '/y3'], ...
    'Position', gp(X_OUT, Y_3HZ+80), 'VariableName','y3', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u3'], ...
    'Position', gp(X_SRC, Y_3HZ+80), 'VariableName','u3', 'SaveFormat','Timeseries');

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('1Hz 사인/1',    'RC 회로 1Hz/1');
L('RC 회로 1Hz/1', 'Mux 1Hz/1');
L('1Hz 사인/1',    'Mux 1Hz/2');
L('Mux 1Hz/1',     'Scope 1Hz/1');
L('RC 회로 1Hz/1', 'y1/1');
L('1Hz 사인/1',    'u1/1');

L('3Hz 사인/1',    'RC 회로 3Hz/1');
L('RC 회로 3Hz/1', 'Mux 3Hz/1');
L('3Hz 사인/1',    'Mux 3Hz/2');
L('Mux 3Hz/1',     'Scope 3Hz/1');
L('RC 회로 3Hz/1', 'y3/1');
L('3Hz 사인/1',    'u3/1');

%% 신호 이름
set_param(get_param([name '/1Hz 사인'],'PortHandles').Outport(1),    'Name','u_1Hz');
set_param(get_param([name '/RC 회로 1Hz'],'PortHandles').Outport(1), 'Name','y_1Hz');
set_param(get_param([name '/3Hz 사인'],'PortHandles').Outport(1),    'Name','u_3Hz');
set_param(get_param([name '/RC 회로 3Hz'],'PortHandles').Outport(1), 'Name','y_3Hz');

%% Scope 설정
c1 = get_param([name '/Scope 1Hz'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '1 Hz : 크기 0.847, 위상 -32도';

c3 = get_param([name '/Scope 3Hz'], 'ScopeConfiguration');
c3.OpenAtSimulationStart = true; c3.ShowLegend = true; c3.ShowGrid = true;
c3.Name = '3 Hz : 크기 0.469, 위상 -62도';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['교수자 강의자료 3쪽 : 같은 RC 회로에 주파수만 다른 사인 두 개.' newline ...
     'R = 100 Ohm, C = 0.001 F 이므로 tau = 0.1 s, G(s) = 1 / (0.1s + 1) 이다.'];
a1.position = [X_SRC, Y_1HZ-110];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['Sine Wave 의 Frequency 는 Hz 가 아니라 rad/s 다.' newline ...
     '1 Hz 는 2*pi = 6.283, 3 Hz 는 6*pi = 18.850 을 넣는다.'];
a2.position = [X_SRC, Y_3HZ-110];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['두 Scope 를 나란히 보십시오. 위는 거의 그대로 통과하고,' newline ...
     '아래는 절반 이하로 줄고 더 늦습니다. 이것이 주파수응답입니다.'];
a3.position = [X_SCP-120, Y_3HZ+130];
a3.FontSize = 11;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W09_RC_SineCompare 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 강의자료 3쪽 : R = 100 Ohm, C = 0.001 F -> tau = 0.1 s'
 'defs = { ''A_in'',1 ; ''w1'',2*pi ; ''w3'',6*pi ; ''t_end'',2 ;'
 '         ''numG'',1 ; ''denG'',[0.1 1] };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name, 'PreLoadFcn', preload);

set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','0.001');

%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -280];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W09_05_rc_simulink.m 로 하십시오.\n');
