%% W06_build_model.m
%  6주차 Simulink 모델 W06_Rlocus_Verify.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    근궤적으로 고른 이득을 Simulink 에서 검증합니다.
%    그리고 여기에 **포화(Saturation)** 를 넣습니다.
%
%    근궤적은 선형 이론입니다. 포화는 비선형입니다.
%    선형 이론으로 고른 이득이 포화가 있으면 어떻게 되는지
%    직접 보여 주는 것이 이 모델의 핵심입니다.
%
%    포화를 켜고 끄는 것은 u_lim 값으로 합니다.
%    아주 큰 값(예: 1e6)을 주면 포화가 없는 것과 같습니다.
%
%  제어시스템설계 6주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W06_Rlocus_Verify';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC=40; X_ERR=160; X_K=240; X_SAT=340; X_PL=440; X_OUT=600; X_MUX=710; X_SCP=780;
Y_MAIN=130; Y_U=300;

gp = @(x,y) [x, y-16, x+62, y+16];
sp = @(x,y) [x, y-10, x+20, y+10];
tp = @(x,y) [x, y-24, x+130, y+24];

%% 블록
add_block('simulink/Sources/Step', [name '/목표 각도 r'], ...
    'Position', gp(X_SRC, Y_MAIN), 'Time','0', 'Before','0', 'After','r_amp');

add_block('simulink/Math Operations/Sum', [name '/오차'], ...
    'Position', sp(X_ERR, Y_MAIN), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_K, Y_MAIN), 'Gain','K');

% 포화 : 근궤적이 모르는 비선형 요소
add_block('simulink/Discontinuities/Saturation', [name '/구동기 포화'], ...
    'Position', gp(X_SAT, Y_MAIN), ...
    'UpperLimit','u_lim', 'LowerLimit','-u_lim');

add_block('simulink/Continuous/Transfer Fcn', [name '/DC 모터 위치 모델'], ...
    'Position', tp(X_PL, Y_MAIN), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_OUT, Y_MAIN), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_OUT, Y_U), 'VariableName','u_sim', 'SaveFormat','Timeseries');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN-40, X_MUX+5, Y_MAIN+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 각도'], ...
    'Position', [X_SCP, Y_MAIN-26, X_SCP+50, Y_MAIN+26]);

add_block('simulink/Sinks/Scope', [name '/Scope 제어입력'], ...
    'Position', [X_SCP, Y_U-26, X_SCP+50, Y_U+26]);

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('목표 각도 r/1',        '오차/1');
L('오차/1',               '비례이득 K/1');
L('비례이득 K/1',         '구동기 포화/1');
L('구동기 포화/1',        'DC 모터 위치 모델/1');
L('DC 모터 위치 모델/1',  'y_sim/1');
L('DC 모터 위치 모델/1',  '오차/2');
L('DC 모터 위치 모델/1',  'Mux/1');
L('목표 각도 r/1',        'Mux/2');
L('Mux/1',                'Scope 각도/1');
L('구동기 포화/1',        'u_sim/1');
L('구동기 포화/1',        'Scope 제어입력/1');

%% 신호 이름
set_param(get_param([name '/오차'],'PortHandles').Outport(1), 'Name','e');
set_param(get_param([name '/구동기 포화'],'PortHandles').Outport(1), 'Name','u');
set_param(get_param([name '/DC 모터 위치 모델'],'PortHandles').Outport(1), 'Name','theta');

%% Scope 설정
c1 = get_param([name '/Scope 각도'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '각도 응답 비교';

c2 = get_param([name '/Scope 제어입력'], 'ScopeConfiguration');
c2.OpenAtSimulationStart = true; c2.ShowGrid = true;
c2.Name = '제어입력 추이';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['근궤적으로 고른 이득 K 를 여기에 넣는다.' newline ...
     '근궤적은 선형 이론이므로 아래 포화 블록의 존재를 모른다.'];
a1.position = [X_K-30, Y_MAIN-95];
a1.FontSize = 11;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['구동기 포화 - 근궤적이 모르는 비선형 요소' newline ...
     '실제 모터 드라이버는 낼 수 있는 전압에 한계가 있다.' newline ...
     'u_lim 을 아주 크게 하면 포화가 없는 것과 같다.'];
a2.position = [X_SAT-60, Y_MAIN+55];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['그냥 열어서 Ctrl+T 로 실행해도 됩니다.' newline ...
     '기본값은 포화를 크게 잡아 두어 선형 이론과 같은 결과가 나옵니다.' newline ...
     'u_lim 을 48 로 줄이면 응답이 달라지는 것이 보입니다.'];
a3.position = [X_SRC, Y_MAIN-165];
a3.FontSize = 12;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W06_Rlocus_Verify 기본 파라미터 (모델을 열 때 자동 실행)'
 '% u_lim 이 크므로 기본 상태는 포화 없음 = 선형 이론과 같은 결과'
 'defs = { ''K'',30 ; ''r_amp'',1 ; ''u_lim'',1e6 ; ''t_end'',6 ;'
 '         ''numG'',0.01 ; ''denG'',[0.005 0.06 0.1001 0] };'
 'for ii = 1:size(defs,1)'
 '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
 '        assignin(''base'', defs{ii,1}, defs{ii,2});'
 '    end'
 'end'
 'clear defs ii'
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
fprintf('실행은 W06_03_run_simulink.m 로 하십시오.\n');
