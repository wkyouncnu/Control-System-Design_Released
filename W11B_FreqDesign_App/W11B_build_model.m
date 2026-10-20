%% W11B_build_model.m
%  11B주차 Simulink 모델 W11B_FreqDesign.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    controlSystemDesigner 앱 안에서는 끝까지 볼 수 없는 두 가지를 봅니다.
%
%      (가) 수송지연 e^(-s*Td)  — 앱과 margin 은 유리함수만 다룹니다.
%           진짜 지연을 넣어 볼 수 있는 곳은 Simulink 뿐입니다.
%           지연은 **구동기 앞**(전방경로)에 둡니다. 강의노트 8-5 절과 같은
%           자리이고, 그래야 y_sim 이 곧 실제 출력이 됩니다.
%      (나) 제어입력 u 의 한계 — 앱의 기본 화면에는 u 가 아예 없습니다.
%
%    강의노트 8절에서 설계한 제어기를 그대로 넣습니다.
%        G = 0.01/(0.005s^3 + 0.06s^2 + 0.1001s)      (DC 모터 위치)
%        C = 200 * [(0.14416s + 1)/(0.01433s + 1)]^2  (K + 2단 Lead)
%        Td = 0.02 s,   |u| <= 12 V
%
%    지령은 **계단이 아니라 램프**입니다. 계단을 주면 첫 순간에
%    u = K/alpha^2 = 20237 V 가 필요해서 (8-6절) 아예 불가능합니다.
%    그래서 Ramp 를 1/(tau*s+1) 로 완만하게 만들어 넣습니다.
%        r(t) = A*(t - tau*(1 - exp(-t/tau)))
%    이것이 8-6절의 그 지령이고, 거기서 umax = 4.2 V 였습니다.
%
%    바꿔 볼 것
%      tau       지령의 완만함. 0.3 -> 0.01 로 줄이면 u 가 터지고 포화가 걸린다
%      Td        지연. 0 으로 두면 앱의 결과와 정확히 같아진다
%      sat_on    1 이면 포화를 켠다 (u_lim 으로 자른다), 0 이면 끈다
%      r_slope   지령 속도 [rad/s]. 사양은 0.2 였다
%
%  제어시스템설계 11B주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W11B_FreqDesign';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_FLT=150; X_ERR=340; X_C=400; X_SAT=600; X_DLY=700; X_PL=830;
X_OUT=1030; X_MUX=1140; X_SCP=1210;
Y_MAIN=150; Y_R=60; Y_FB=300; Y_U=440;

gp = @(x,y) [x, y-16, x+70, y+16];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-24, x+150, y+24];

%% 블록 — 지령을 만드는 곳
%  Ramp 를 1 차 필터에 통과시키면 출발이 매끄러운 램프가 됩니다.
%  r = A*t 를 1/(tau*s+1) 에 넣으면 정확히
%  r = A*(t - tau*(1-exp(-t/tau))) 가 나옵니다 (8-6절의 그 식).
add_block('simulink/Sources/Ramp', [name '/지령 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'slope','r_slope', 'start','0', ...
    'InitialOutput','0');

add_block('simulink/Continuous/Transfer Fcn', [name '/지령 완만화 필터'], ...
    'Position', tp(X_FLT, Y_MAIN), 'Numerator','1', 'Denominator','[tau 1]');

%% 블록 — 제어 루프
add_block('simulink/Math Operations/Sum', [name '/오차 계산'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/설계한 제어기 C'], ...
    'Position', tp(X_C, Y_MAIN), 'Numerator','numC', 'Denominator','denC');

% 포화 : sat_on 을 0 으로 두면 한계가 사실상 없어진다 (1e9 V)
add_block('simulink/Discontinuities/Saturation', [name '/구동기 한계'], ...
    'Position', gp(X_SAT, Y_MAIN), ...
    'UpperLimit','u_sat', 'LowerLimit','-u_sat');

%% 블록 — 수송지연 (계산한 전압이 모터에 실제로 걸리기까지 걸리는 시간)
%  루프 안 어디에 두어도 여유(PM·GM)는 같습니다. 전방경로에 두면
%  y_sim 이 곧 실제 출력이 되어 강의노트 8-5 절의 G_real 과 똑같아집니다.
add_block('simulink/Continuous/Transport Delay', [name '/수송지연'], ...
    'Position', gp(X_DLY, Y_MAIN), 'DelayTime','Td', 'InitialOutput','0', ...
    'BufferSize','16384');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numG', 'Denominator','denG');

%% 블록 — 기록과 그래프
add_block('simulink/Sinks/To Workspace', [name '/r_sim'], ...
    'Position', gp(X_OUT, Y_R), 'VariableName','r_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y_U), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 위치'], ...
    'Position', [X_SCP, Y_MAIN-26, X_SCP+50, Y_MAIN+26]);

add_block('simulink/Sinks/Scope', [name '/Scope 전압'], ...
    'Position', [X_SCP, Y_U-26, X_SCP+50, Y_U+26]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('지령 r/1',            '지령 완만화 필터/1');
L('지령 완만화 필터/1',   '오차 계산/1');
L('오차 계산/1',          '설계한 제어기 C/1');
L('설계한 제어기 C/1',    '구동기 한계/1');
L('구동기 한계/1',        '수송지연/1');
L('수송지연/1',           '플랜트 G/1');

% 되먹임 : 출력이 그대로 돌아온다 (단위 피드백)
L('플랜트 G/1',           '오차 계산/2');

L('플랜트 G/1',           'y_sim/1');
L('플랜트 G/1',           'Mux/1');
L('지령 완만화 필터/1',   'Mux/2');
L('Mux/1',                'Scope 위치/1');

L('지령 완만화 필터/1',   'r_sim/1');
L('구동기 한계/1',        'u_sim/1');
L('구동기 한계/1',        'Scope 전압/1');

%% 신호 이름 — 강의노트의 유도에 쓴 기호와 똑같이 붙인다
set_param(get_param([name '/지령 완만화 필터'],'PortHandles').Outport(1), 'Name','r');
set_param(get_param([name '/오차 계산'],'PortHandles').Outport(1),        'Name','e');
set_param(get_param([name '/설계한 제어기 C'],'PortHandles').Outport(1),  'Name','u_raw');
set_param(get_param([name '/구동기 한계'],'PortHandles').Outport(1),      'Name','u');
set_param(get_param([name '/수송지연'],'PortHandles').Outport(1),         'Name','u_late');
set_param(get_param([name '/플랜트 G'],'PortHandles').Outport(1),         'Name','y');

%% Scope 설정
%  [주의] ScopeConfiguration 의 Name 은 창 제목이 아니라 **블록 이름**입니다.
%         여기에 설명을 넣으면 블록 이름이 통째로 바뀌어
%         나중에 '모델이름/Scope 위치' 로 찾을 수 없게 됩니다. 건드리지 않습니다.
c1 = get_param([name '/Scope 위치'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;

c2 = get_param([name '/Scope 전압'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowGrid = true;

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['지령은 계단이 아니라 램프입니다.' newline ...
     'Ramp 를 1 나누기 (tau*s+1) 에 통과시키면 출발이 매끄러워집니다.' newline ...
     '계단을 주면 첫 순간에 20237 V 가 필요합니다 (강의노트 8-6 절).' newline ...
     'tau 를 0.01 로 줄여 보십시오. u 가 터지고 포화가 걸립니다.'];
a1.position = [X_SRC, Y_R-90];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['수송지연은 구동기 앞에 있습니다. 계산한 전압이 모터에 걸리기까지의 시간입니다.' newline ...
     '크기는 하나도 안 바뀌고 위상만 깎입니다. 깎는 양은 -w*Td 입니다.' newline ...
     'wc = 8.588 에서 -9.84 도 이므로 PM 60.6 도가 50.7 도로 떨어집니다.' newline ...
     'Td 를 0 으로 두면 앱의 결과와 정확히 같아집니다.'];
a2.position = [X_DLY-160, Y_FB+45];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['손계산 (강의노트 8 절)' newline ...
     '  C = 200 곱하기 [(0.14416s+1) 나누기 (0.01433s+1)] 의 제곱' newline ...
     '  이상 플랜트 PM 60.6 도,  지연 포함 PM 50.7 도,  GM 13.5 dB' newline ...
     '  매끄러운 램프의 umax = 4.2 V  (한계 12 V)' newline ...
     '검증은 W11B_06_run_simulink.m 가 자동으로 해 줍니다.'];
a3.position = [X_SRC, Y_U+70];
a3.FontSize = 12;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W11B_FreqDesign 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 플랜트 G = 0.01/(0.005s^3+0.06s^2+0.1001s),  DC 모터 위치'
 '% 제어기 C = 200*[(0.14416s+1)/(0.01433s+1)]^2  (강의노트 8-4 절)'
 'defs = { ''numG'',0.01 ; ''denG'',[0.005 0.06 0.1001 0] ;'
 '         ''numC'',200*conv([0.144164 1],[0.144164 1]) ;'
 '         ''denC'',conv([0.014334 1],[0.014334 1]) ;'
 '         ''r_slope'',0.2 ; ''tau'',0.3 ;'
 '         ''Td'',0.02 ;'
 '         ''u_lim'',12 ; ''u_sat'',12 ;'
 '         ''t_end'',4 };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name, 'PreLoadFcn', preload);

% 수송지연이 0.02 초입니다. 보간 오차가 생기지 않게
% 최대 시간간격을 지연의 1/10 보다 작게 묶어 둡니다 (강의노트 8-5 절).
set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','1e-3');

% 기록은 0.001 초 간격으로 **균일하게** 남긴다.
% lsim 은 시간 간격이 균일한 벡터만 받으므로,
% 가변 스텝 솔버가 남긴 들쭉날쭉한 시각을 그대로 주면 오류가 난다.
set_param(name, 'OutputOption','SpecifiedOutputTimes', ...
                'OutputTimes','0:0.001:t_end');

%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -320];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W11B_06_run_simulink.m 로 하십시오.\n');
