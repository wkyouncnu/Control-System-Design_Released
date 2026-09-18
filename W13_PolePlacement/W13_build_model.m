%% W13_build_model.m
%  13주차 Simulink 모델 W13_PolePlacement.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    상태궤환 u = -K*x + Kr*r 을 블록으로 그려 보고,
%    **구동기 포화**가 있을 때 무슨 일이 생기는지 봅니다.
%
%    (1) State-Space 블록의 C 를 단위행렬로 두어 **상태를 전부 뽑습니다.**
%        상태궤환은 상태를 전부 알아야 쓸 수 있기 때문입니다.
%        (14주차에서 이 가정을 깹니다)
%
%    (2) Gain 블록에 **행벡터 K** 를 넣고 곱셈 방향을 Matrix 로 둡니다.
%        스칼라 이득이 아니라 행벡터라는 점이 오늘의 새로운 부분입니다.
%
%    (3) Saturation 블록을 두 갈래로 두어 켜고 끌 수 있게 했습니다.
%        10강 slide 106~108 의 control saturation 실습입니다.
%
%  제어시스템설계 13주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W13_PolePlacement';
here  = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_R = 40; X_SUM = 170; X_SAT = 260; X_SS = 380; X_OUT = 620; X_SCP = 740;
Y = 160;
gp = @(x,y) [x, y-16, x+70, y+16];

%% 블록
add_block('simulink/Sources/Step', [name '/지령 r'], ...
    'Position', gp(X_R, Y), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Math Operations/Gain', [name '/Kr'], ...
    'Position', gp(X_R+90, Y), 'Gain','Kr');

add_block('simulink/Math Operations/Sum', [name '/합산'], ...
    'Position', [X_SUM, Y-18, X_SUM+30, Y+18], 'Inputs','+-', ...
    'IconShape','round');

add_block('simulink/Discontinuities/Saturation', [name '/구동기 포화'], ...
    'Position', gp(X_SAT, Y), ...
    'UpperLimit','u_lim', 'LowerLimit','-u_lim');

add_block('simulink/Continuous/State-Space', [name '/플랜트'], ...
    'Position', [X_SS, Y-40, X_SS+160, Y+40], ...
    'A','A_mat', 'B','B_mat', 'C','eye(size(A_mat,1))', ...
    'D','zeros(size(A_mat,1),1)', 'X0','x0');

add_block('simulink/Math Operations/Gain', [name '/상태궤환 K'], ...
    'Position', [X_SS+40, Y+120, X_SS+110, Y+160], ...
    'Gain','K_fb', 'Multiplication','Matrix(K*u)', 'Orientation','left');

add_block('simulink/Sinks/To Workspace', [name '/x_sim'], ...
    'Position', gp(X_OUT, Y), 'VariableName','x_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y-90), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/Scope', [name '/Scope'], ...
    'Position', [X_SCP, Y-30, X_SCP+50, Y+30]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('지령 r/1',        'Kr/1');
L('Kr/1',            '합산/1');
L('합산/1',          '구동기 포화/1');
L('구동기 포화/1',   '플랜트/1');
L('플랜트/1',        'x_sim/1');
L('플랜트/1',        'Scope/1');
L('플랜트/1',        '상태궤환 K/1');
L('상태궤환 K/1',    '합산/2');
L('구동기 포화/1',   'u_sim/1');

%% 신호 이름
set_param(get_param([name '/플랜트'],'PortHandles').Outport(1), 'Name','x');
set_param(get_param([name '/구동기 포화'],'PortHandles').Outport(1), 'Name','u');

%% Scope 설정
c1 = get_param([name '/Scope'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '상태 x(t)';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['상태궤환 u = -K x + Kr r' newline ...
     '아래쪽 Gain 블록에 들어가는 것은 스칼라가 아니라 행벡터 K 입니다.' newline ...
     'Multiplication 을 Matrix(K*u) 로 두어야 합니다.'];
a1.position = [X_R, Y-120];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['플랜트의 C 를 단위행렬로 두어 상태를 전부 뽑았습니다.' newline ...
     '상태궤환은 상태를 전부 알아야 쓸 수 있기 때문입니다.' newline ...
     '못 재는 상태가 있으면? 14주차의 관측기로 갑니다.'];
a2.position = [X_SS-40, Y+200];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['u_lim 을 크게 두면 포화가 없는 것과 같습니다.' newline ...
     'u_lim 을 줄여 가며 응답이 어떻게 무너지는지 보십시오.'];
a3.position = [X_SAT-30, Y+60];
a3.FontSize = 11;

%% 모델만 열어도 돌아가게
% [주의] 조건부(if ~exist)로 두면 안 됩니다.
%        앞 주차 모델이 같은 이름의 변수를 남겨 두면 이 블록이 통째로
%        건너뛰어져 K_fb 가 정의되지 않고 모델이 안 돕니다.
%        실제로 W12 가 A_mat 을 남겨 verify_all 에서 이 문제가 났습니다.
%        **무조건 덮어씁니다.** 스크립트는 load_system 뒤에 값을 정하므로
%        이렇게 해도 스크립트의 설정이 지워지지 않습니다.
preload = strjoin({ ...
 '% W13_PolePlacement 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 기본 예제 : DC 모터 위치제어 + 극배치 [-8 -10 -12]'
 '%'
 '% [주의] setup_path 를 안 한 상태에서 모델만 열어도 돌아가야 합니다.'
 '%        경로가 없으면 plant_dcmotor 를 못 찾으므로 아래처럼 숫자로 대신합니다.'
 '%        (숫자는 plant_dcmotor(''''position'''') 이 주는 값과 같습니다)'
 'if isempty(which(''plant_dcmotor''))'
 '    pp = struct(''A'', [0 1 0; 0 -10 1; 0 -0.02 -2], ...'
 '                ''B'', [0; 0; 2], ''C'', [1 0 0], ''D'', 0);'
 'else'
 '    [~, pp] = plant_dcmotor(''position'');'
 'end'
 'A_mat = pp.A;  B_mat = pp.B;'
 'K_fb  = place(pp.A, pp.B, [-8 -10 -12]);'
 'Kr    = 1/dcgain(ss(pp.A - pp.B*K_fb, pp.B, pp.C, pp.D));'
 'x0    = zeros(size(A_mat,1),1);'
 'r_amp = 1;  u_lim = 1e6;  t_end = 1.5;'
 'clear pp'
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
fprintf('실행은 W13_04_run_simulink.m 로 하십시오.\n');
