%% W01_build_model.m
%  1주차 Simulink 모델 W01_OpenClosed.slx 를 코드로 생성합니다. (교수자용)
%
%  학생은 이 파일을 실행할 필요가 없습니다. W01_OpenClosed.slx 를 그냥 열면 됩니다.
%
%  이 모델의 특징
%    1) 모델만 열어서 바로 실행할 수 있습니다.
%       필요한 변수(m, b, k, K, ...)를 모델이 스스로 준비하기 때문입니다.
%       (모델 속성의 PreLoadFcn 에 기본값을 넣어 두었습니다)
%    2) 실행하면 Scope 두 개가 자동으로 열립니다.
%       스크립트를 돌리지 않아도 Simulink 안에서 결과를 다 볼 수 있습니다.
%    3) 위아래 두 경로의 블록이 세로로 딱 맞게 정렬되어 있습니다.
%       같은 x 위치에 같은 역할의 블록이 오도록 배치했습니다.
%
%  제어시스템설계 1주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W01_OpenClosed';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

%% 배치 좌표 (세로 정렬을 위해 x 를 미리 정해 둡니다)
X_SRC  =  40;    % 목표값 / 외란
X_PRE  = 150;    % Kff, Kr  (앞단 보정 상수)
X_ERR  = 250;    % 오차 합산점 (폐루프에만 있음)
X_GAIN = 320;    % 비례이득 K (폐루프에만 있음)
X_DIST = 430;    % 외란 합산점
X_PLNT = 510;    % 플랜트
X_OUT  = 680;    % To Workspace
X_MUX  = 800;    % Mux
X_SCP  = 880;    % Scope

Y_OPEN = 70;     % 개루프 경로의 세로 위치
Y_CLSD = 260;    % 폐루프 경로의 세로 위치
Y_DIST = 420;    % 외란 블록의 세로 위치

gp = @(x,y) [x, y-15, x+50, y+15];      % 게인 블록 (50 x 30)
sp = @(x,y) [x, y-10, x+20, y+10];      % 합산 블록 (20 x 20)
tp = @(x,y) [x, y-20, x+110, y+20];     % 전달함수 블록 (110 x 40)
wp = @(x,y) [x, y-15, x+70, y+15];      % To Workspace (70 x 30)

%% ================= 위쪽 : 개루프 경로 =================
add_block('simulink/Sources/Step', [name '/목표값 r'], ...
    'Position', gp(X_SRC, Y_OPEN), 'Time','0', 'Before','0', 'After','r');

add_block('simulink/Math Operations/Gain', [name '/Kff'], ...
    'Position', gp(X_PRE, Y_OPEN), 'Gain','Kff');

add_block('simulink/Math Operations/Sum', [name '/외란 합산 개루프'], ...
    'Position', sp(X_DIST, Y_OPEN), 'Inputs','++', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 개루프'], ...
    'Position', tp(X_PLNT, Y_OPEN), 'Numerator','[1]', 'Denominator','[m b k]');

add_block('simulink/Sinks/To Workspace', [name '/y_open_sim'], ...
    'Position', wp(X_OUT, Y_OPEN), 'VariableName','y_open_sim', 'SaveFormat','Timeseries');

%% ================= 아래쪽 : 폐루프 경로 =================
add_block('simulink/Math Operations/Gain', [name '/Kr'], ...
    'Position', gp(X_PRE, Y_CLSD), 'Gain','Kr');

add_block('simulink/Math Operations/Sum', [name '/오차 계산'], ...
    'Position', sp(X_ERR, Y_CLSD), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_GAIN, Y_CLSD), 'Gain','K');

add_block('simulink/Math Operations/Sum', [name '/외란 합산 폐루프'], ...
    'Position', sp(X_DIST, Y_CLSD), 'Inputs','++', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 폐루프'], ...
    'Position', tp(X_PLNT, Y_CLSD), 'Numerator','[1]', 'Denominator','[m b k]');

add_block('simulink/Sinks/To Workspace', [name '/y_close_sim'], ...
    'Position', wp(X_OUT, Y_CLSD), 'VariableName','y_close_sim', 'SaveFormat','Timeseries');

%% ================= 외란 =================
add_block('simulink/Sources/Step', [name '/외란 d'], ...
    'Position', gp(X_SRC, Y_DIST), 'Time','t_d', 'Before','0', 'After','d');

%% ================= 화면 표시 =================
add_block('simulink/Signal Routing/Mux', [name '/Mux 출력'], ...
    'Position', [X_MUX, Y_OPEN-20, X_MUX+5, Y_CLSD+20], 'Inputs','3');

add_block('simulink/Sinks/Scope', [name '/Scope 출력 비교'], ...
    'Position', [X_SCP, (Y_OPEN+Y_CLSD)/2-25, X_SCP+50, (Y_OPEN+Y_CLSD)/2+25]);

add_block('simulink/Sinks/Scope', [name '/Scope 제어입력'], ...
    'Position', [X_SCP, Y_CLSD+120, X_SCP+50, Y_CLSD+170]);

%% ================= 신호선 =================
L = @(src, dst) add_line(name, src, dst, 'autorouting','smart');

% 개루프
L('목표값 r/1',            'Kff/1');
L('Kff/1',                 '외란 합산 개루프/1');
L('외란 d/1',              '외란 합산 개루프/2');
L('외란 합산 개루프/1',    '플랜트 개루프/1');
L('플랜트 개루프/1',       'y_open_sim/1');

% 폐루프
L('목표값 r/1',            'Kr/1');
L('Kr/1',                  '오차 계산/1');
L('오차 계산/1',           '비례이득 K/1');
L('비례이득 K/1',          '외란 합산 폐루프/1');
L('외란 d/1',              '외란 합산 폐루프/2');
L('외란 합산 폐루프/1',    '플랜트 폐루프/1');
L('플랜트 폐루프/1',       'y_close_sim/1');
L('플랜트 폐루프/1',       '오차 계산/2');          % <- 되먹임. 이 선 하나가 핵심

% 화면 표시
L('플랜트 개루프/1',       'Mux 출력/1');
L('플랜트 폐루프/1',       'Mux 출력/2');
L('목표값 r/1',            'Mux 출력/3');
L('Mux 출력/1',            'Scope 출력 비교/1');
L('비례이득 K/1',          'Scope 제어입력/1');

%% ================= 신호 이름 (Scope 범례에 나옵니다) =================
setName = @(blk, port, nm) set_param( ...
    get_param([name '/' blk],'PortHandles').Outport(port), 'Name', nm);

setName('플랜트 개루프', 1, 'y_open');
setName('플랜트 폐루프', 1, 'y_close');
setName('목표값 r',      1, 'r');
setName('오차 계산',     1, 'e');
setName('비례이득 K',    1, 'u');

%% ================= Scope 설정 =================
%  실행하자마자 창이 열리고, 범례와 격자가 보이도록 설정합니다.
%  이렇게 해 두면 스크립트를 돌리지 않아도 Simulink 안에서 결과를 다 볼 수 있습니다.
cfgOut = get_param([name '/Scope 출력 비교'], 'ScopeConfiguration');
cfgOut.OpenAtSimulationStart = true;
cfgOut.ShowLegend            = true;
cfgOut.ShowGrid              = true;
cfgOut.Name                  = '출력 비교 : 개루프 vs 폐루프';

cfgU = get_param([name '/Scope 제어입력'], 'ScopeConfiguration');
cfgU.OpenAtSimulationStart = true;
cfgU.ShowGrid              = true;
cfgU.Name                  = '폐루프 제어입력 u';

%% ================= 설명 주석 =================
%  주의: Simulink.Annotation 텍스트에는 슬래시를 쓸 수 없습니다.
%        모델 경로 구분자로 해석되어 오류가 납니다.
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['【위】 개루프 - 출력을 보지 않는다' newline ...
     '목표값에 상수 Kff 를 곱해 그냥 내보낸다.' newline ...
     '외란이 들어와도 알아채지 못하므로 그대로 오차가 된다.'];
a1.position = [X_PRE, Y_OPEN-90];
a1.FontSize = 11;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['【아래】 폐루프 - 출력을 되먹인다' newline ...
     '출력 y 를 빼서 오차 e 를 만들고, 거기에 K 를 곱해 넣는다.' newline ...
     '외란이 들어오면 e 가 커지므로 제어입력이 자동으로 늘어난다.'];
a2.position = [X_PRE, Y_CLSD-90];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['이 되먹임 선 하나가' newline ...
     '위아래의 유일한 차이다.'];
a3.position = [X_ERR-40, Y_CLSD+95];
a3.FontSize = 11;

a4 = Simulink.Annotation([name '/a4']);
a4.Text = ['외란 d 는 두 경로에 똑같이 들어간다.' newline ...
     '조건이 같으므로 결과 차이는 오직 되먹임 유무에서 나온다.'];
a4.position = [X_SRC, Y_DIST+45];
a4.FontSize = 11;

a5 = Simulink.Annotation([name '/a5']);
a5.Text = ['이 모델은 그냥 열어서 실행(Ctrl+T)해도 됩니다.' newline ...
     '필요한 변수는 모델이 스스로 준비합니다.' newline ...
     '값을 바꿔 가며 실험하려면 W01_03_run_simulink.m 을 쓰십시오.'];
a5.position = [X_SRC, Y_OPEN-160];
a5.FontSize = 12;

%% ================= 모델만 열어도 돌아가게 만들기 =================
%  블록에는 숫자가 아니라 변수 이름이 적혀 있으므로, 그냥 열어서 실행하면
%  "m 이 정의되지 않았다"는 오류가 납니다.
%
%  그래서 모델을 불러올 때 기본값을 만들어 주는 코드를 PreLoadFcn 에 넣습니다.
%  단, 이미 값이 있으면 건드리지 않습니다. 그래야 스크립트에서 값을 바꿔
%  실험할 때 덮어쓰지 않습니다.
preload = strjoin({ ...
 '% W01_OpenClosed 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 이미 워크스페이스에 값이 있으면 그대로 두고, 없을 때만 채웁니다.'
 'defs = { ''m'',1 ; ''b'',0.2 ; ''k'',1 ; ''r'',1 ; ''d'',0.5 ; ''t_d'',40 ;'
 '         ''t_end'',100 ; ''K'',9 ; ''Kff'',1 ; ''Kr'',10/9 };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);

set_param(name, 'PreLoadFcn', preload);

%% ================= 솔버 =================
set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','0.01');

%% ================= 저장 =================

%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
%  고칠 일이 있으면 common/model_blocks.m 만 고치면 됩니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -260];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('\n확인 방법\n');
fprintf('  1) 모델만 열어서 실행 :  open_system(''%s'') 후 Ctrl+T\n', name);
fprintf('     -> Scope 두 개가 자동으로 열리며 결과가 보입니다.\n');
fprintf('  2) 값을 바꿔 가며 실험 :  W01_03_run_simulink.m 실행\n');
