%% W11A_build_model.m
%  11A주차 Simulink 모델 W11A_LoopShaping.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    주파수영역에서 계산한 숫자가 **시간영역에서 그대로 나오는지** 봅니다.
%
%    강의노트 5-3 절에서 손으로 이렇게 구했습니다.
%        L = P*C = 100/s,   S = s/(s+100)
%        |S(j2pi)| = 2pi/sqrt((2pi)^2 + 100^2) = 0.0627  ->  -24.05 dB
%    즉 1 Hz 출력외란은 폐루프를 지나면 약 1/16 로 줄어 나옵니다.
%
%    이 모델은 같은 루프에 같은 외란을 넣고, 출력 진폭을 직접 재서
%    0.0627 이 맞는지 확인합니다. 센서 잡음도 같이 넣어
%    "외란은 좋아지고 잡음은 나빠지는" 맞바꿈을 눈으로 봅니다.
%
%    바꿔 볼 것
%      w_d        외란 주파수. 0.6, 2*pi, 60, 600 (고주파는 안 줄어든다)
%      noise_pow  센서 잡음 세기. 0 으로 두면 잡음이 꺼진다
%      numC       제어기 이득. 500 을 2 배로 하면 교차주파수도 2 배
%
%  제어시스템설계 11A주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W11A_LoopShaping';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=180; X_C=240; X_PL=430; X_DSUM=620; X_OUT=710; X_MUX=800; X_SCP=870;
Y_MAIN=150; Y_D=40; Y_FB=270; Y_N=360; Y_U=460;

gp = @(x,y) [x, y-16, x+70, y+16];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-24, x+140, y+24];

%% 블록 — 전방경로
add_block('simulink/Sources/Step', [name '/목표 속도 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Math Operations/Sum', [name '/오차 계산'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

% PI 제어기 : 영점 s = -4 가 모터 극점을 지워 L = 100/s 가 된다
add_block('simulink/Continuous/Transfer Fcn', [name '/PI 제어기'], ...
    'Position', tp(X_C, Y_MAIN), 'Numerator','numC', 'Denominator','denC');

add_block('simulink/Continuous/Transfer Fcn', [name '/DC 모터'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numP', 'Denominator','denP');

%% 블록 — 외란이 들어오는 자리 (플랜트 출력쪽)
add_block('simulink/Sources/Sine Wave', [name '/출력외란 d'], ...
    'Position', gp(X_PL+30, Y_D), 'Amplitude','d_amp', 'Frequency','w_d', 'Phase','0');

add_block('simulink/Math Operations/Sum', [name '/외란 합산'], ...
    'Position', sp(X_DSUM, Y_MAIN), 'Inputs','++', 'IconShape','round');

%% 블록 — 센서 잡음이 들어오는 자리 (되먹임 선)
add_block('simulink/Sources/Band-Limited White Noise', [name '/센서 잡음 n'], ...
    'Position', gp(X_PL+30, Y_N), 'Cov','noise_pow', 'Ts','noise_ts', 'seed','12345');

add_block('simulink/Math Operations/Sum', [name '/측정값 만들기'], ...
    'Position', sp(X_DSUM, Y_FB), 'Inputs','++', 'IconShape','round');

%% 블록 — 기록과 그래프
add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/d_sim'], ...
    'Position', gp(X_OUT, Y_D), 'VariableName','d_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y_U), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 속도'], ...
    'Position', [X_SCP, Y_MAIN-26, X_SCP+50, Y_MAIN+26]);

add_block('simulink/Sinks/Scope', [name '/Scope 전압'], ...
    'Position', [X_SCP, Y_U-26, X_SCP+50, Y_U+26]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('목표 속도 r/1',    '오차 계산/1');
L('오차 계산/1',      'PI 제어기/1');
L('PI 제어기/1',      'DC 모터/1');
L('DC 모터/1',        '외란 합산/1');
L('출력외란 d/1',     '외란 합산/2');

L('외란 합산/1',      'y_sim/1');
L('외란 합산/1',      'Mux/1');
L('목표 속도 r/1',    'Mux/2');
L('Mux/1',            'Scope 속도/1');

% 되먹임 선 : 측정값은 y 가 아니라 y + n 이다
L('외란 합산/1',      '측정값 만들기/1');
L('센서 잡음 n/1',    '측정값 만들기/2');
L('측정값 만들기/1',  '오차 계산/2');

L('출력외란 d/1',     'd_sim/1');
L('PI 제어기/1',      'u_sim/1');
L('PI 제어기/1',      'Scope 전압/1');

%% 신호 이름 — 강의노트의 유도에 쓴 기호와 똑같이 붙인다
set_param(get_param([name '/오차 계산'],'PortHandles').Outport(1),     'Name','e');
set_param(get_param([name '/PI 제어기'],'PortHandles').Outport(1),     'Name','u');
set_param(get_param([name '/DC 모터'],'PortHandles').Outport(1),       'Name','Pu');
set_param(get_param([name '/외란 합산'],'PortHandles').Outport(1),     'Name','y');
set_param(get_param([name '/측정값 만들기'],'PortHandles').Outport(1), 'Name','ym');

%% Scope 설정
%  [주의] ScopeConfiguration 의 Name 은 창 제목이 아니라 **블록 이름**입니다.
%         여기에 긴 설명을 넣으면 블록 이름이 통째로 바뀌어
%         나중에 '모델이름/Scope 속도' 로 찾을 수 없게 됩니다. 건드리지 않습니다.
c1 = get_param([name '/Scope 속도'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;

c2 = get_param([name '/Scope 전압'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowGrid = true;

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['출력외란 d 는 플랜트 뒤에서 더해집니다.' newline ...
     'd 에서 y 까지의 전달함수가 바로 감도함수 S 입니다.' newline ...
     '그래서 d 를 w_d 로 흔들면 출력 진폭이 S 의 크기만큼 나옵니다.'];
a1.position = [X_PL-20, Y_D-80];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['센서 잡음 n 은 되먹임 선에서 더해집니다.' newline ...
     '제어기가 믿는 값은 y 가 아니라 ym = y + n 입니다.' newline ...
     'n 에서 y 까지는 -T 이므로 대역폭 안의 잡음은 그대로 들어옵니다.' newline ...
     'noise_pow 를 0 으로 두면 잡음이 꺼집니다.'];
a2.position = [X_PL-20, Y_N+45];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['손계산 (강의노트 5-3 절)' newline ...
     '  L = P*C = 100 나누기 s,   S = s 나누기 (s+100)' newline ...
     '  w_d = 2*pi 에서 S 의 크기 = 0.0627  즉 -24.05 dB' newline ...
     '실행하면 출력 진폭이 d_amp 의 0.0627 배인지 확인하십시오.' newline ...
     '검증은 W11A_05_run_simulink.m 가 자동으로 해 줍니다.'];
a3.position = [X_SRC, Y_U+60];
a3.FontSize = 12;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W11A_LoopShaping 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 플랜트 P = 0.1/(0.5s+2),  제어기 C = (500s+2000)/s  ->  L = 100/s'
 'defs = { ''r_amp'',1 ;'
 '         ''numC'',[500 2000] ; ''denC'',[1 0] ;'
 '         ''numP'',0.1        ; ''denP'',[0.5 2] ;'
 '         ''d_amp'',0.3       ; ''w_d'',2*pi ;'
 '         ''noise_pow'',2e-7  ; ''noise_ts'',5e-4 ;'
 '         ''t_end'',2 };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name, 'PreLoadFcn', preload);

% 외란 주파수(1 Hz)보다 루프가 훨씬 빠릅니다 (교차주파수 100 rad/s).
% 잡음 샘플 간격 5e-4 초도 따라가야 하므로 최대 시간간격을 작게 묶어 둡니다.
set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','2e-4');

%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -300];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);
fprintf('실행은 W11A_05_run_simulink.m 로 하십시오.\n');
