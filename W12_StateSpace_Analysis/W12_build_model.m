%% W12_build_model.m
%  12주차 Simulink 모델 W12_StateSpace_Modes.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    상태공간 모델을 **초기조건부터** 돌려 봅니다.
%
%    (1) State-Space 블록에는 **초기조건**을 넣을 수 있습니다.
%        전달함수 블록에는 없는 기능입니다.
%        전달함수는 초기조건이 0 이라고 가정하고 유도한 것이기 때문입니다.
%
%    (2) 초기조건을 **고유벡터 방향**으로 주면 응답이 지수함수 하나로 나옵니다.
%        아무 방향으로 주면 여러 모드가 섞입니다.
%        이것이 12주차의 핵심 그림입니다.
%
%    (3) 모든 상태를 출력으로 뽑아 두었습니다 (C = I).
%        그래야 상태 하나하나가 어떻게 움직이는지 볼 수 있습니다.
%
%  제어시스템설계 12주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W12_StateSpace_Modes';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=60; X_SS=260; X_OUT=520; X_SCP=650;
Y_MAIN=150;

gp = @(x,y) [x, y-16, x+70, y+16];

%% 블록
add_block('simulink/Sources/Step', [name '/입력 u'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','u_amp');

add_block('simulink/Continuous/State-Space', [name '/상태공간 모델'], ...
    'Position', [X_SS, Y_MAIN-40, X_SS+160, Y_MAIN+40], ...
    'A','A_mat', 'B','B_mat', 'C','C_mat', 'D','D_mat', 'X0','x0');

add_block('simulink/Sinks/To Workspace', [name '/x_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','x_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/Scope', [name '/Scope 상태'], ...
    'Position', [X_SCP, Y_MAIN-30, X_SCP+50, Y_MAIN+30]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('입력 u/1',          '상태공간 모델/1');
L('상태공간 모델/1',   'x_sim/1');
L('상태공간 모델/1',   'Scope 상태/1');

%% 신호 이름
set_param(get_param([name '/상태공간 모델'],'PortHandles').Outport(1), 'Name','x');

%% Scope 설정
c1 = get_param([name '/Scope 상태'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '상태 x(t)';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['State-Space 블록에는 초기조건 x0 를 넣을 수 있습니다.' newline ...
     'Transfer Fcn 블록에는 없는 기능입니다.' newline ...
     '전달함수는 초기조건이 0 이라는 가정 위에서 유도한 것이기 때문입니다.'];
a1.position = [X_SRC, Y_MAIN-125];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['x0 를 고유벡터 방향으로 주면 응답이 지수함수 하나가 됩니다.' newline ...
     '아무 방향으로 주면 여러 모드가 섞입니다.' newline ...
     'W12_03_run_simulink.m 에서 확인하십시오.'];
a2.position = [X_SS-60, Y_MAIN+80];
a2.FontSize = 11;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W12_StateSpace_Modes 기본 파라미터 (모델을 열 때 자동 실행)'
 '% [주의] 조건부(if ~exist)로 두면 앞 주차 모델이 남긴 같은 이름의 변수 때문에'
 '%        이 블록이 통째로 건너뛰어져 모델이 안 돕니다. **무조건 덮어씁니다.**'
 'A_mat = [0 1; -2 -3];   B_mat = [0;1];'
 'C_mat = eye(2);         D_mat = [0;0];'
 'x0 = [1;0];  u_amp = 0;  t_end = 6;'
 }, newline);set_param(name, 'PreLoadFcn', preload);

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
fprintf('실행은 W12_03_run_simulink.m 로 하십시오.\n');
