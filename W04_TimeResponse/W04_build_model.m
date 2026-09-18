%% W04_build_model.m
%  4주차 Simulink 모델 W04_SecondOrder_Sweep.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 구성
%    표준 2차 시스템을 적분기 두 개로 구현했습니다.
%    전달함수 블록을 쓰지 않은 이유는 zeta 와 wn 이 블록 안 어디에 들어가는지
%    눈으로 보이게 하기 위해서입니다.
%
%      x'' = wn^2*(r - x) - 2*zeta*wn*x'
%
%    이 식을 그대로 블록으로 옮기면 표준 2차 시스템이 됩니다.
%    감쇠 경로의 게인이 2*zeta*wn 이고, 여기가 zeta 가 들어가는 유일한 자리입니다.
%
%  제어시스템설계 4주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W04_SecondOrder_Sweep';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=150; X_GAIN=220; X_SUM=320; X_I1=390; X_I2=470; X_OUT=580;
X_MUX=690; X_SCP=760;
Y_MAIN=120; Y_FB=250;

gp = @(x,y) [x, y-15, x+55, y+15];
sp = @(x,y) [x, y-10, x+20, y+10];

%% 블록
add_block('simulink/Sources/Step', [name '/목표값 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','1');

add_block('simulink/Math Operations/Sum', [name '/오차 계산'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/wn 제곱'], ...
    'Position', gp(X_GAIN, Y_MAIN), 'Gain','wn^2');

add_block('simulink/Math Operations/Sum', [name '/가속도 합산'], ...
    'Position', sp(X_SUM, Y_MAIN), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Continuous/Integrator', [name '/적분1 속도'], ...
    'Position', gp(X_I1, Y_MAIN), 'InitialCondition','0');

add_block('simulink/Continuous/Integrator', [name '/적분2 위치'], ...
    'Position', gp(X_I2, Y_MAIN), 'InitialCondition','0');

% 감쇠 경로 : 여기가 zeta 가 들어가는 유일한 자리
add_block('simulink/Math Operations/Gain', [name '/감쇠 2 zeta wn'], ...
    'Position', gp(X_I1, Y_FB), 'Gain','2*zeta*wn', 'Orientation','left');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 계단응답'], ...
    'Position', [X_SCP, Y_MAIN-25, X_SCP+50, Y_MAIN+25]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('목표값 r/1',        '오차 계산/1');
L('오차 계산/1',       'wn 제곱/1');
L('wn 제곱/1',         '가속도 합산/1');
L('가속도 합산/1',     '적분1 속도/1');
L('적분1 속도/1',      '적분2 위치/1');
L('적분1 속도/1',      '감쇠 2 zeta wn/1');     % 속도를 되먹임
L('감쇠 2 zeta wn/1',  '가속도 합산/2');
L('적분2 위치/1',      '오차 계산/2');          % 위치를 되먹임
L('적분2 위치/1',      'y_sim/1');
L('적분2 위치/1',      'Mux/1');
L('목표값 r/1',        'Mux/2');
L('Mux/1',             'Scope 계단응답/1');

%% 신호 이름
set_param(get_param([name '/적분2 위치'],'PortHandles').Outport(1), 'Name','y');
set_param(get_param([name '/적분1 속도'],'PortHandles').Outport(1), 'Name','y_dot');
set_param(get_param([name '/오차 계산'],'PortHandles').Outport(1),  'Name','e');

%% Scope 설정
cfg = get_param([name '/Scope 계단응답'], 'ScopeConfiguration');
cfg.OpenAtSimulationStart = true;
cfg.ShowLegend            = true;
cfg.ShowGrid              = true;
cfg.Name                  = '2차 시스템 계단응답';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['표준 2차 시스템을 적분기 두 개로 구현' newline ...
     '가속도 = wn^2*(r - y) - 2*zeta*wn*(속도)' newline ...
     '이것을 두 번 적분하면 위치 y 가 된다.'];
a1.position = [X_GAIN, Y_MAIN-90];
a1.FontSize = 11;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['여기가 zeta 가 들어가는 유일한 자리다.' newline ...
     '이 게인을 0 으로 하면 감쇠가 사라져 영원히 진동한다.'];
a2.position = [X_I1-60, Y_FB+40];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['그냥 열어서 Ctrl+T 로 실행해도 됩니다.' newline ...
     'zeta 와 wn 을 바꿔 가며 실험하려면 W04_03_run_simulink.m 을 쓰십시오.'];
a3.position = [X_SRC, Y_MAIN-160];
a3.FontSize = 12;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W04_SecondOrder_Sweep 기본 파라미터 (모델을 열 때 자동 실행)'
 'defs = { ''zeta'',0.5 ; ''wn'',2 ; ''t_end'',15 };'
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
fprintf('실행은 W04_03_run_simulink.m 로 하십시오.\n');
