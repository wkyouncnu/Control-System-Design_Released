%% W10_build_model.m
%  10주차 Simulink 모델 W10_Margin_Check.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    두 가지를 보여 줍니다.
%
%    (1) **실제 현장의 모델은 전달함수가 아니라 블록선도로 온다.**
%        그래서 Simulink 모델을 선형화해서 개루프를 뽑아내고
%        거기서 이득여유와 위상여유를 읽는 절차를 익힙니다.
%        (Simulink Control Design 의 linearize / getLoopTransfer)
%
%    (2) **시간지연은 크기를 건드리지 않고 위상만 깎는다.**
%        Transport Delay 블록의 tau_d 를 키우면
%        보드 선도의 크기 곡선은 그대로인데 위상여유만 줄어들다가
%        결국 불안정해집니다. 근궤적으로는 설명하기 어려운 현상이라
%        주파수영역 방법의 값어치를 보여 주는 좋은 예입니다.
%
%  기본값은 tau_d = 0 (지연 없음) 입니다.
%
%  제어시스템설계 10주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W10_Margin_Check';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=170; X_K=250; X_DLY=350; X_PL=470; X_OUT=650; X_MUX=760; X_SCP=830;
Y_MAIN=140; Y_U=290;

gp = @(x,y) [x, y-16, x+68, y+16];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-24, x+140, y+24];

%% 블록
add_block('simulink/Sources/Step', [name '/목표값 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Math Operations/Sum', [name '/오차'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_K, Y_MAIN), 'Gain','K');

% 시간지연 : 크기는 그대로 두고 위상만 깎는다
add_block('simulink/Continuous/Transport Delay', [name '/시간지연'], ...
    'Position', gp(X_DLY, Y_MAIN), 'DelayTime','tau_d');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G(s)'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y_U), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 출력'], ...
    'Position', [X_SCP, Y_MAIN-26, X_SCP+50, Y_MAIN+26]);

add_block('simulink/Sinks/Scope', [name '/Scope 제어입력'], ...
    'Position', [X_SCP, Y_U-26, X_SCP+50, Y_U+26]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('목표값 r/1',      '오차/1');
L('오차/1',          '비례이득 K/1');
L('비례이득 K/1',    '시간지연/1');
L('시간지연/1',      '플랜트 G(s)/1');
L('플랜트 G(s)/1',   'y_sim/1');
L('플랜트 G(s)/1',   '오차/2');
L('플랜트 G(s)/1',   'Mux/1');
L('목표값 r/1',      'Mux/2');
L('Mux/1',           'Scope 출력/1');
L('비례이득 K/1',    'u_sim/1');
L('비례이득 K/1',    'Scope 제어입력/1');

%% 신호 이름 (선형화 지점을 지정할 때 이 이름을 씁니다)
set_param(get_param([name '/오차'],'PortHandles').Outport(1),        'Name','e');
set_param(get_param([name '/비례이득 K'],'PortHandles').Outport(1),  'Name','u');
set_param(get_param([name '/플랜트 G(s)'],'PortHandles').Outport(1), 'Name','y');

%% Scope 설정
c1 = get_param([name '/Scope 출력'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '출력과 목표값';

c2 = get_param([name '/Scope 제어입력'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowGrid = true;
c2.Name = '제어입력 u';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['이 모델을 선형화해서 개루프를 뽑고' newline ...
     '거기서 이득여유와 위상여유를 읽습니다.' newline ...
     '실제 현장에서는 전달함수가 아니라 이런 블록선도가 주어집니다.'];
a1.position = [X_SRC, Y_MAIN-120];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['시간지연 tau_d - 크기는 그대로, 위상만 깎인다.' newline ...
     '0.1, 0.3, 0.5 로 키워 보십시오. 어느 순간 발산합니다.' newline ...
     '통신 지연, 센서 처리 시간, 열 전달 등에서 늘 생깁니다.'];
a2.position = [X_DLY-60, Y_MAIN+70];
a2.FontSize = 11;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W10_Margin_Check 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 기본 플랜트는 강의자료 6장의 예 G = 1 over s(s+1)^2'
 'defs = { ''K'',0.5 ; ''r_amp'',1 ; ''tau_d'',0 ; ''t_end'',60 ;'
 '         ''numG'',1 ; ''denG'',[1 2 1 0] };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name, 'PreLoadFcn', preload);

set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','0.02');


%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
%  고칠 일이 있으면 common/model_blocks.m 만 고치면 됩니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -260];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W10_03_run_simulink.m 로 하십시오.\n');
