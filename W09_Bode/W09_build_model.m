%% W09_build_model.m
%  9주차 Simulink 모델 W09_SineSweep.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    보드 선도를 **직접 측정해서** 그립니다.
%
%    사인파를 하나 넣고 충분히 기다린 뒤, 출력 사인의
%      - 진폭이 입력의 몇 배인가   -> 크기
%      - 얼마나 늦게 따라오는가    -> 위상
%    를 잽니다. 주파수를 바꿔 가며 이것을 반복하면 보드 선도가 나옵니다.
%
%    즉 이 모델은 "보드 선도가 어디서 오는가" 에 대한 답입니다.
%    실험실에서 실제 장치의 주파수응답을 재는 절차와 똑같습니다.
%
%  주파수는 워크스페이스 변수 w_in 으로 바꿉니다.
%  W09_03_run_simulink.m 이 이 값을 바꿔 가며 sim 을 반복 호출합니다.
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W09_SineSweep';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=60; X_PL=240; X_OUT=430; X_MUX=560; X_SCP=640;
Y_MAIN=140; Y_U=270;

gp = @(x,y) [x, y-16, x+70, y+16];
tp = @(x,y) [x, y-24, x+140, y+24];

%% 블록
add_block('simulink/Sources/Sine Wave', [name '/사인 입력'], ...
    'Position', gp(X_SRC, Y_MAIN), ...
    'Amplitude','A_in', 'Frequency','w_in', 'Phase','0');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G(s)'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y_U), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 입출력'], ...
    'Position', [X_SCP, Y_MAIN-26, X_SCP+50, Y_MAIN+26]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('사인 입력/1',    '플랜트 G(s)/1');
L('플랜트 G(s)/1',  'y_sim/1');
L('플랜트 G(s)/1',  'Mux/1');
L('사인 입력/1',    'Mux/2');
L('사인 입력/1',    'u_sim/1');
L('Mux/1',          'Scope 입출력/1');

%% 신호 이름
set_param(get_param([name '/사인 입력'],'PortHandles').Outport(1),   'Name','u');
set_param(get_param([name '/플랜트 G(s)'],'PortHandles').Outport(1), 'Name','y');

%% Scope 설정
c1 = get_param([name '/Scope 입출력'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '입력 사인과 출력 사인';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['주파수 w_in 을 바꿔 가며 여러 번 돌린다.' newline ...
     '출력 사인의 진폭비와 시간지연을 재면 그것이 곧 보드 선도의 한 점이다.'];
a1.position = [X_SRC, Y_MAIN-110];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['정상상태에 들어간 뒤의 구간만 써야 한다.' newline ...
     '처음 몇 주기는 과도응답이 섞여 있어 값이 틀린다.'];
a2.position = [X_PL, Y_MAIN+70];
a2.FontSize = 11;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W09_SineSweep 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 기본값은 질량-스프링-댐퍼, 입력 주파수 1 rad/s'
 'defs = { ''A_in'',1 ; ''w_in'',1 ; ''t_end'',60 ;'
 '         ''numG'',1 ; ''denG'',[1 0.2 1] };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name, 'PreLoadFcn', preload);

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
fprintf('실행은 W09_03_run_simulink.m 로 하십시오.\n');
