%% W07_build_model.m
%  7주차 Simulink 모델 두 개를 코드로 생성합니다. (교수자용)
%
%    W07_PD_Noise.slx      PD 의 잡음 증폭 문제
%    W07_Design_Verify.slx 제어입력 한계까지 넣은 설계의 검증
%
%  ---------------------------------------------------------------
%  첫 번째 모델 : W07_PD_Noise.slx
%
%  모델의 목적
%    PD 제어기의 잡음 증폭 문제를 눈으로 보여 줍니다.
%
%    위 : PD 제어 (Derivative 블록 사용)
%    아래 : Lead 보상기 (Transfer Fcn 사용)
%
%    두 경로에 **똑같은 측정 잡음**을 넣습니다.
%    제어입력 Scope 를 보면 PD 쪽만 요동치는 것이 보입니다.
%
%    MATLAB 에서는 PD 의 제어입력을 아예 계산하지 못했습니다 (비인과적 모델).
%    Simulink 의 Derivative 블록은 수치미분으로 근사하므로 돌아가기는 하는데,
%    바로 그 때문에 잡음 문제가 그대로 드러납니다.
%
%  제어시스템설계 7주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W07_PD_Noise';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=170; X_C1=260; X_C2=370; X_SUM=470; X_PL=550; X_MEAS=720;
X_OUT=830; X_SCP=950;
Y_PD=130; Y_LD=380; Y_N=600;

gp = @(x,y) [x, y-16, x+70, y+16];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-24, x+140, y+24];

%% 공통 입력
add_block('simulink/Sources/Step', [name '/목표 각도 r'], ...
    'Position', gp(X_SRC, (Y_PD+Y_LD)/2), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Sources/Band-Limited White Noise', [name '/측정 잡음'], ...
    'Position', gp(X_SRC, Y_N), 'Cov','noise_pow', 'Ts','noise_ts', 'seed','12345');

%% ---------- 위 : PD 제어 ----------
add_block('simulink/Math Operations/Sum', [name '/오차 PD'], ...
    'Position', sp(X_ERR, Y_PD), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/Kp'], ...
    'Position', gp(X_C1, Y_PD-45), 'Gain','Kp_pd');

add_block('simulink/Continuous/Derivative', [name '/미분 du dt'], ...
    'Position', gp(X_C1, Y_PD+45));

add_block('simulink/Math Operations/Gain', [name '/Kd'], ...
    'Position', gp(X_C2, Y_PD+45), 'Gain','Kd_pd');

add_block('simulink/Math Operations/Sum', [name '/제어입력 PD'], ...
    'Position', sp(X_SUM, Y_PD), 'Inputs','++', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 PD'], ...
    'Position', tp(X_PL, Y_PD), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Math Operations/Sum', [name '/측정 PD'], ...
    'Position', sp(X_MEAS, Y_PD), 'Inputs','++', 'IconShape','round');

add_block('simulink/Sinks/To Workspace', [name '/u_pd'], ...
    'Position', gp(X_OUT, Y_PD-45), 'VariableName','u_pd', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/y_pd'], ...
    'Position', gp(X_OUT, Y_PD+45), 'VariableName','y_pd', 'SaveFormat','Timeseries');

%% ---------- 아래 : Lead 보상기 ----------
add_block('simulink/Math Operations/Sum', [name '/오차 Lead'], ...
    'Position', sp(X_ERR, Y_LD), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/Lead 보상기'], ...
    'Position', tp(X_C1, Y_LD), 'Numerator','numC', 'Denominator','denC');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 Lead'], ...
    'Position', tp(X_PL, Y_LD), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Math Operations/Sum', [name '/측정 Lead'], ...
    'Position', sp(X_MEAS, Y_LD), 'Inputs','++', 'IconShape','round');

add_block('simulink/Sinks/To Workspace', [name '/u_lead'], ...
    'Position', gp(X_OUT, Y_LD-45), 'VariableName','u_lead', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/y_lead'], ...
    'Position', gp(X_OUT, Y_LD+45), 'VariableName','y_lead', 'SaveFormat','Timeseries');

%% ---------- Scope ----------
add_block('simulink/Signal Routing/Mux', [name '/Mux 출력'], ...
    'Position', [X_SCP-70, Y_PD-30, X_SCP-65, Y_LD+30], 'Inputs','3');

add_block('simulink/Sinks/Scope', [name '/Scope 각도'], ...
    'Position', [X_SCP, (Y_PD+Y_LD)/2-70, X_SCP+50, (Y_PD+Y_LD)/2-20]);

add_block('simulink/Signal Routing/Mux', [name '/Mux 입력'], ...
    'Position', [X_SCP-70, Y_N-40, X_SCP-65, Y_N+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 제어입력'], ...
    'Position', [X_SCP, Y_N-25, X_SCP+50, Y_N+25]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

% PD 경로
L('목표 각도 r/1',      '오차 PD/1');
L('오차 PD/1',          'Kp/1');
L('오차 PD/1',          '미분 du dt/1');
L('미분 du dt/1',       'Kd/1');
L('Kp/1',               '제어입력 PD/1');
L('Kd/1',               '제어입력 PD/2');
L('제어입력 PD/1',      '플랜트 PD/1');
L('플랜트 PD/1',        '측정 PD/1');
L('측정 잡음/1',        '측정 PD/2');
L('측정 PD/1',          '오차 PD/2');
L('제어입력 PD/1',      'u_pd/1');
L('플랜트 PD/1',        'y_pd/1');

% Lead 경로
L('목표 각도 r/1',      '오차 Lead/1');
L('오차 Lead/1',        'Lead 보상기/1');
L('Lead 보상기/1',      '플랜트 Lead/1');
L('플랜트 Lead/1',      '측정 Lead/1');
L('측정 잡음/1',        '측정 Lead/2');
L('측정 Lead/1',        '오차 Lead/2');
L('Lead 보상기/1',      'u_lead/1');
L('플랜트 Lead/1',      'y_lead/1');

% Scope
L('플랜트 PD/1',        'Mux 출력/1');
L('플랜트 Lead/1',      'Mux 출력/2');
L('목표 각도 r/1',      'Mux 출력/3');
L('Mux 출력/1',         'Scope 각도/1');
L('제어입력 PD/1',      'Mux 입력/1');
L('Lead 보상기/1',      'Mux 입력/2');
L('Mux 입력/1',         'Scope 제어입력/1');

%% 신호 이름
set_param(get_param([name '/제어입력 PD'],'PortHandles').Outport(1), 'Name','u_PD');
set_param(get_param([name '/Lead 보상기'],'PortHandles').Outport(1), 'Name','u_Lead');
set_param(get_param([name '/플랜트 PD'],'PortHandles').Outport(1),   'Name','theta_PD');
set_param(get_param([name '/플랜트 Lead'],'PortHandles').Outport(1), 'Name','theta_Lead');

%% Scope 설정
c1 = get_param([name '/Scope 각도'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '각도 응답 : PD vs Lead';

c2 = get_param([name '/Scope 제어입력'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowLegend = true; c2.ShowGrid = true;
c2.Name = '제어입력 : PD 만 요동친다';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['PD 제어 - 미분기를 그대로 쓴다' newline ...
     '잡음이 섞인 측정값을 미분하므로 제어입력이 요동친다.'];
a1.position = [X_C1-40, Y_PD-110];
a1.FontSize = 11;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['Lead 보상기 - 미분 대신 분모가 있는 전달함수' newline ...
     '고주파 이득이 제한되어 잡음이 증폭되지 않는다.'];
a2.position = [X_C1-40, Y_LD+60];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['두 경로에 똑같은 측정 잡음이 들어간다.' newline ...
     '조건이 같으므로 차이는 오직 제어기 구조에서 나온다.'];
a3.position = [X_SRC, Y_N+45];
a3.FontSize = 11;

a4 = Simulink.Annotation([name '/a4']);
a4.Text = ['그냥 열어서 Ctrl+T 로 실행해도 됩니다.' newline ...
     '아래쪽 제어입력 Scope 를 보십시오. PD 만 요동칩니다.' newline ...
     'noise_pow 를 0 으로 하면 둘 다 깨끗해집니다.'];
a4.position = [X_SRC, Y_PD-165];
a4.FontSize = 12;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W07_PD_Noise 기본 파라미터 (모델을 열 때 자동 실행)'
 '% numC, denC 는 Lead 보상기의 계수입니다.'
 'defs = { ''Kp_pd'',56.7 ; ''Kd_pd'',18.9 ; ''r_amp'',1 ; ''t_end'',4 ;'
 '         ''noise_pow'',1e-8 ; ''noise_ts'',0.001 ;'
 '         ''numG'',0.01 ; ''denG'',[0.005 0.06 0.1001 0] ;'
 '         ''numC'',[265 530] ; ''denC'',[1 15] };'
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
%  같은 글을 .slx 주석 · 실행 스크립트 · 강의노트가 함께 씁니다.
%  고칠 일이 있으면 common/model_blocks.m 만 고치면 됩니다.
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -260];
aBlk.FontSize = 11;

save_system(name, fpath);
fprintf('모델을 저장했습니다: %s\n', fpath);


%% ====================================================================
%  두 번째 모델 : W07_Design_Verify.slx
%
%  모델의 목적
%    W07_04 에서 "제어입력 한계를 사양에 넣고" 설계한 결과를 확인합니다.
%
%    위   : 포화가 없는 이상적인 루프 (설계할 때 가정한 것)
%    아래 : 포화가 있는 실제 루프
%
%    설계를 제대로 했다면 두 응답이 겹칩니다.
%    K 를 키워 보면 아래쪽만 이상해집니다. 그것이 포화입니다.
%  ====================================================================

name2  = 'W07_Design_Verify';
fpath2 = fullfile(here, [name2 '.slx']);

if bdIsLoaded(name2), close_system(name2, 0); end
if isfile(fpath2),    delete(fpath2);          end
new_system(name2);
open_system(name2);

B_SRC=40; B_ERR=190; B_K=280; B_SAT=400; B_PL=520; B_OUT=700; B_SCP=830;
Y_ID=140; Y_RE=340;

gp2 = @(x,y) [x, y-16, x+70, y+16];
sp2 = @(x,y) [x, y-10, x+20, y+10];
tp2 = @(x,y) [x, y-24, x+140, y+24];

%% 공통 지령
add_block('simulink/Sources/Step', [name2 '/목표값 r'], ...
    'Position', gp2(B_SRC, (Y_ID+Y_RE)/2), 'Time','0', 'Before','0', 'After','1');

%% ---------- 위 : 포화 없는 이상적 루프 ----------
add_block('simulink/Math Operations/Sum', [name2 '/오차 이상'], ...
    'Position', sp2(B_ERR, Y_ID), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name2 '/K 이상'], ...
    'Position', gp2(B_K, Y_ID), 'Gain','K_des');

add_block('simulink/Continuous/Transfer Fcn', [name2 '/플랜트 이상'], ...
    'Position', tp2(B_PL, Y_ID), 'Numerator','numG2', 'Denominator','denG2');

add_block('simulink/Sinks/To Workspace', [name2 '/u_ideal'], ...
    'Position', gp2(B_OUT, Y_ID-50), 'VariableName','u_ideal', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name2 '/y_ideal'], ...
    'Position', gp2(B_OUT, Y_ID+50), 'VariableName','y_ideal', 'SaveFormat','Timeseries');

%% ---------- 아래 : 포화가 있는 실제 루프 ----------
add_block('simulink/Math Operations/Sum', [name2 '/오차 실제'], ...
    'Position', sp2(B_ERR, Y_RE), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name2 '/K 실제'], ...
    'Position', gp2(B_K, Y_RE), 'Gain','K_des');

add_block('simulink/Discontinuities/Saturation', [name2 '/구동기 한계'], ...
    'Position', gp2(B_SAT, Y_RE), 'UpperLimit','u_lim', 'LowerLimit','-u_lim');

add_block('simulink/Continuous/Transfer Fcn', [name2 '/플랜트 실제'], ...
    'Position', tp2(B_PL, Y_RE), 'Numerator','numG2', 'Denominator','denG2');

add_block('simulink/Sinks/To Workspace', [name2 '/u_real'], ...
    'Position', gp2(B_OUT, Y_RE-50), 'VariableName','u_real', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name2 '/y_real'], ...
    'Position', gp2(B_OUT, Y_RE+50), 'VariableName','y_real', 'SaveFormat','Timeseries');

%% ---------- Scope ----------
add_block('simulink/Signal Routing/Mux', [name2 '/Mux 출력'], ...
    'Position', [B_SCP-70, Y_ID-30, B_SCP-65, Y_RE+30], 'Inputs','3');

add_block('simulink/Sinks/Scope', [name2 '/Scope 출력'], ...
    'Position', [B_SCP, (Y_ID+Y_RE)/2-80, B_SCP+50, (Y_ID+Y_RE)/2-30]);

add_block('simulink/Signal Routing/Mux', [name2 '/Mux 입력'], ...
    'Position', [B_SCP-70, (Y_ID+Y_RE)/2+40, B_SCP-65, (Y_ID+Y_RE)/2+120], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name2 '/Scope 제어입력'], ...
    'Position', [B_SCP, (Y_ID+Y_RE)/2+55, B_SCP+50, (Y_ID+Y_RE)/2+105]);

%% 연결
L2 = @(a,b) add_line(name2, a, b, 'autorouting','smart');

L2('목표값 r/1',      '오차 이상/1');
L2('오차 이상/1',     'K 이상/1');
L2('K 이상/1',        '플랜트 이상/1');
L2('플랜트 이상/1',   '오차 이상/2');
L2('K 이상/1',        'u_ideal/1');
L2('플랜트 이상/1',   'y_ideal/1');

L2('목표값 r/1',      '오차 실제/1');
L2('오차 실제/1',     'K 실제/1');
L2('K 실제/1',        '구동기 한계/1');
L2('구동기 한계/1',   '플랜트 실제/1');
L2('플랜트 실제/1',   '오차 실제/2');
L2('구동기 한계/1',   'u_real/1');
L2('플랜트 실제/1',   'y_real/1');

L2('플랜트 이상/1',   'Mux 출력/1');
L2('플랜트 실제/1',   'Mux 출력/2');
L2('목표값 r/1',      'Mux 출력/3');
L2('Mux 출력/1',      'Scope 출력/1');
L2('K 이상/1',        'Mux 입력/1');
L2('구동기 한계/1',   'Mux 입력/2');
L2('Mux 입력/1',      'Scope 제어입력/1');

%% 신호 이름
set_param(get_param([name2 '/K 이상'],'PortHandles').Outport(1),      'Name','u_ideal');
set_param(get_param([name2 '/구동기 한계'],'PortHandles').Outport(1), 'Name','u_real');
set_param(get_param([name2 '/플랜트 이상'],'PortHandles').Outport(1), 'Name','y_ideal');
set_param(get_param([name2 '/플랜트 실제'],'PortHandles').Outport(1), 'Name','y_real');

%% Scope 설정
d1 = get_param([name2 '/Scope 출력'], 'ScopeConfiguration');
d1.OpenAtSimulationStart = true; d1.ShowLegend = true; d1.ShowGrid = true;
d1.Name = '출력 : 포화 없음 vs 포화 있음';

d2 = get_param([name2 '/Scope 제어입력'], 'ScopeConfiguration');
d2.OpenAtSimulationStart = true; d2.ShowLegend = true; d2.ShowGrid = true;
d2.Name = '제어입력 : 한계에 닿는가';

%% 주석 (슬래시 사용 금지)
b1 = Simulink.Annotation([name2 '/b1']);
b1.Text = ['위 - 포화가 없는 루프.' newline ...
     '설계할 때 우리가 가정한 세상이다.'];
b1.position = [B_ERR, Y_ID-95]; b1.FontSize = 11;

b2 = Simulink.Annotation([name2 '/b2']);
b2.Text = ['아래 - 구동기 한계가 있는 실제 루프.' newline ...
     'K 곱한 값이 u_lim 을 넘으면 잘려 나간다.'];
b2.position = [B_ERR, Y_RE+70]; b2.FontSize = 11;

b3 = Simulink.Annotation([name2 '/b3']);
b3.Text = ['그냥 열어서 Ctrl+T 로 실행해 보십시오.' newline ...
     'K_des = 4.79 는 W07_04 에서 제어입력 한계까지 넣어 설계한 값입니다.' newline ...
     '두 응답이 겹칩니다. 설계가 맞았다는 뜻입니다.' newline ...
     '명령창에서 K_des = 30 으로 바꾸고 다시 돌려 보십시오.' newline ...
     '아래쪽만 크게 흔들립니다. 그것이 포화입니다.'];
b3.position = [B_SRC, Y_ID-190]; b3.FontSize = 12;

%% 모델만 열어도 돌아가게
preload2 = strjoin({ ...
 '% W07_Design_Verify 기본 파라미터 (모델을 열 때 자동 실행)'
 '% 플랜트 G(s) = 1 / (s(s+2)(s+5))'
 'defs = { ''K_des'',4.79 ; ''u_lim'',5 ; ''t_end2'',12 ;'
 '         ''numG2'',1 ; ''denG2'',[1 7 10 0] };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
 }, newline);
set_param(name2, 'PreLoadFcn', preload2);

set_param(name2, 'Solver','ode45', 'StopTime','t_end2', ...
                 'SolverType','Variable-step', 'MaxStep','0.01');

%% 블록 설명 주석 (common/model_blocks.m 에서 가져온다)
bBlk = Simulink.Annotation([name2 '/bBlk']);
bBlk.Text = model_blocks(name2, 'note');
bBlk.position = [40, -300];
bBlk.FontSize = 11;

save_system(name2, fpath2);
fprintf('모델을 저장했습니다: %s\n', fpath2);
fprintf('실행은 W07_06_run_simulink.m 로 하십시오.\n');
