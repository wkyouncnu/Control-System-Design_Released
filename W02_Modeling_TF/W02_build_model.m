%% W02_build_model.m
%  2주차 Simulink 모델 W02_MSD_ThreeWays.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 구성
%    경로 A : 적분기 두 개로 미분방정식을 그대로 구현   (초기조건 지정 가능)
%    경로 B : Transfer Fcn 블록                          (초기조건 지정 불가)
%    경로 C : State-Space 블록                           (초기조건 지정 가능)
%
%  세 경로에 같은 입력을 넣고 응답이 겹치는지 확인하는 것이 목적입니다.
%  초기조건을 0 이 아닌 값으로 주면 경로 B 만 반응하지 못하는데,
%  이것이 "전달함수는 초기조건을 담지 못한다"는 사실의 눈에 보이는 증거입니다.
%
%  제어시스템설계 2주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W02_MSD_ThreeWays';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

%% 공통 입력
add_block('simulink/Sources/Step', [name '/입력 힘 F'], ...
    'Position', [30 200 60 230], 'Time','0', 'Before','0', 'After','F_amp');

%% ---------- 경로 A : 적분기 두 개 ----------
% x'' = (F - b*x' - k*x)/m 을 블록으로 그대로 옮긴 것입니다.
% 가속도를 한 번 적분하면 속도, 두 번 적분하면 위치가 됩니다.

add_block('simulink/Math Operations/Sum', [name '/힘의 합'], ...
    'Position', [140 45 160 65], 'Inputs','+--', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/나누기 m'], ...
    'Position', [190 40 220 70], 'Gain','1/m');

add_block('simulink/Continuous/Integrator', [name '/적분1 가속도에서 속도'], ...
    'Position', [250 40 280 70], 'InitialCondition','x0_vel');

add_block('simulink/Continuous/Integrator', [name '/적분2 속도에서 위치'], ...
    'Position', [320 40 350 70], 'InitialCondition','x0_pos');

add_block('simulink/Math Operations/Gain', [name '/댐퍼 b'], ...
    'Position', [250 120 280 150], 'Gain','b', 'Orientation','left');

add_block('simulink/Math Operations/Gain', [name '/스프링 k'], ...
    'Position', [320 170 350 200], 'Gain','k', 'Orientation','left');

add_block('simulink/Sinks/To Workspace', [name '/y_A'], ...
    'Position', [430 40 490 70], 'VariableName','y_A', 'SaveFormat','Timeseries');

%% ---------- 경로 B : Transfer Fcn ----------
add_block('simulink/Continuous/Transfer Fcn', [name '/전달함수 블록'], ...
    'Position', [250 280 350 320], 'Numerator','[1]', 'Denominator','[m b k]');

add_block('simulink/Sinks/To Workspace', [name '/y_B'], ...
    'Position', [430 285 490 315], 'VariableName','y_B', 'SaveFormat','Timeseries');

%% ---------- 경로 C : State-Space ----------
add_block('simulink/Continuous/State-Space', [name '/상태공간 블록'], ...
    'Position', [250 380 350 420], ...
    'A','A_msd', 'B','B_msd', 'C','C_msd', 'D','D_msd', 'X0','[x0_pos; x0_vel]');

add_block('simulink/Sinks/To Workspace', [name '/y_C'], ...
    'Position', [430 385 490 415], 'VariableName','y_C', 'SaveFormat','Timeseries');

%% ---------- 비교용 ----------
add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [560 50 565 410], 'Inputs','3');

add_block('simulink/Sinks/Scope', [name '/세 경로 비교'], ...
    'Position', [620 210 660 250]);

%% 신호선 연결
L = @(src, dst) add_line(name, src, dst, 'autorouting','smart');

% 경로 A
L('입력 힘 F/1',              '힘의 합/1');
L('힘의 합/1',                '나누기 m/1');
L('나누기 m/1',               '적분1 가속도에서 속도/1');
L('적분1 가속도에서 속도/1',  '적분2 속도에서 위치/1');
L('적분1 가속도에서 속도/1',  '댐퍼 b/1');          % 속도를 되먹임
L('댐퍼 b/1',                 '힘의 합/2');
L('적분2 속도에서 위치/1',    '스프링 k/1');        % 위치를 되먹임
L('스프링 k/1',               '힘의 합/3');
L('적분2 속도에서 위치/1',    'y_A/1');

% 경로 B
L('입력 힘 F/1',              '전달함수 블록/1');
L('전달함수 블록/1',          'y_B/1');

% 경로 C
L('입력 힘 F/1',              '상태공간 블록/1');
L('상태공간 블록/1',          'y_C/1');

% 비교
L('적분2 속도에서 위치/1',    'Mux/1');
L('전달함수 블록/1',          'Mux/2');
L('상태공간 블록/1',          'Mux/3');
L('Mux/1',                    '세 경로 비교/1');

%% 신호 이름
set_param(get_param([name '/적분1 가속도에서 속도'],'PortHandles').Outport(1), 'Name','v');
set_param(get_param([name '/적분2 속도에서 위치'],  'PortHandles').Outport(1), 'Name','x_A');
set_param(get_param([name '/나누기 m'],             'PortHandles').Outport(1), 'Name','a');

%% 설명 주석
% 주의: Simulink.Annotation 의 텍스트에는 슬래시를 쓸 수 없습니다.
%       모델 경로 구분자로 해석되어 오류가 납니다.
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['경로 A: 적분기 두 개로 미분방정식을 그대로 구현' newline ...
     '가속도 = (F - b*속도 - k*위치) 를 m 으로 나눈 값' newline ...
     '이것을 두 번 적분하면 위치가 된다.' newline ...
     '시스템 내부가 훤히 보이고, 초기조건도 줄 수 있다.'];
a1.position = [560 20];

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['경로 B: Transfer Fcn 블록' newline ...
     '가장 간단하지만 초기조건을 줄 수 없다.' newline ...
     '입력-출력 관계만 담고 있기 때문이다.'];
a2.position = [560 300];

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['경로 C: State-Space 블록' newline ...
     '초기조건을 줄 수 있고 내부 상태를 모두 꺼내 볼 수 있다.' newline ...
     '3주차에서 자세히 다룬다.'];
a3.position = [560 400];

%% Scope 설정 : 실행하면 창이 자동으로 열리도록
cfg = get_param([name '/세 경로 비교'], 'ScopeConfiguration');
cfg.OpenAtSimulationStart = true;
cfg.ShowLegend            = true;
cfg.ShowGrid              = true;
cfg.Name                  = '세 가지 방법의 응답 비교';

%% 모델만 열어도 돌아가게 만들기
%  블록에는 숫자가 아니라 변수 이름이 적혀 있으므로, 그냥 열어서 실행하면
%  "m 이 정의되지 않았다"는 오류가 납니다.
%  그래서 모델을 불러올 때 기본값을 만들어 주는 코드를 PreLoadFcn 에 넣습니다.
%  단, 이미 값이 있으면 건드리지 않습니다. 그래야 스크립트에서 값을 바꿔
%  실험할 때 덮어쓰지 않습니다.
preload = strjoin({ ...
 '% W02_MSD_ThreeWays 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 이미 워크스페이스에 값이 있으면 그대로 두고, 없을 때만 채웁니다.'
 'defs = { ''m'',1 ; ''b'',0.2 ; ''k'',1 ; ''F_amp'',1 ; ''t_end'',40 ;'
 '         ''x0_pos'',0 ; ''x0_vel'',0 ;'
 '         ''A_msd'',[0 1; -1 -0.2] ; ''B_msd'',[0;1] ;'
 '         ''C_msd'',[1 0] ; ''D_msd'',0 };'
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
fprintf('실행은 W02_03_run_simulink.m 로 하십시오.\n');
