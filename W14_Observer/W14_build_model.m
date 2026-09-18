%% W14_build_model.m
%  14주차 Simulink 모델 W14_ObserverBased.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 목적
%    **실제 플랜트와 관측기를 나란히 놓고 상태를 겹쳐 보는 것**입니다.
%
%    (1) 위쪽이 실제 플랜트입니다. 초기조건이 있습니다.
%    (2) 아래쪽이 관측기입니다. 초기조건이 0 입니다 — **아무것도 모릅니다.**
%    (3) 관측기는 입력 u 와 측정 y 만 받습니다. 진짜 상태는 안 봅니다.
%    (4) 측정 y 에 잡음을 더할 수 있게 해 두었습니다 (noise_pwr 로 조절).
%
%    관측기를 하나의 State-Space 블록으로 구현했습니다.
%
%      xhat' = (A - L*C) xhat + [B  L] * [u ; y]
%
%    괄호를 풀면 xhat' = A xhat + B u + L(y - C xhat) 과 같습니다.
%    이렇게 묶으면 블록 하나로 끝나서 그림이 훨씬 읽기 쉽습니다.
%
%  제어시스템설계 14주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W14_ObserverBased';
here  = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_U = 50; X_P = 220; X_N = 430; X_MUX = 560; X_O = 650; X_W = 880;
Y_P = 120;  Y_O = 300;
gp = @(x,y) [x, y-16, x+70, y+16];

%% 블록 — 위쪽 : 실제 플랜트
add_block('simulink/Sources/Step', [name '/입력 u'], ...
    'Position', gp(X_U, Y_P), 'Time','0', 'Before','0', 'After','u_amp');

add_block('simulink/Continuous/State-Space', [name '/실제 플랜트'], ...
    'Position', [X_P, Y_P-45, X_P+150, Y_P+45], ...
    'A','A_mat', 'B','B_mat', 'C','[C_mat; eye(size(A_mat,1))]', ...
    'D','zeros(size(A_mat,1)+1, 1)', 'X0','x0');

add_block('simulink/Signal Routing/Demux', [name '/분배'], ...
    'Position', [X_N-40, Y_P-45, X_N-35, Y_P+45], ...
    'Outputs','[1 size(A_mat,1)]');

add_block('simulink/Sources/Band-Limited White Noise', [name '/센서 잡음'], ...
    'Position', gp(X_N, Y_P-110), 'Cov','noise_pwr', 'Ts','1e-4', 'seed','23341');

add_block('simulink/Math Operations/Sum', [name '/잡음 더하기'], ...
    'Position', [X_N+110, Y_P-18, X_N+140, Y_P+18], 'Inputs','++', ...
    'IconShape','round');

%% 블록 — 아래쪽 : 관측기
add_block('simulink/Signal Routing/Mux', [name '/u 와 y'], ...
    'Position', [X_MUX, Y_O-30, X_MUX+5, Y_O+30], 'Inputs','2');

add_block('simulink/Continuous/State-Space', [name '/관측기'], ...
    'Position', [X_O, Y_O-45, X_O+160, Y_O+45], ...
    'A','A_mat - L_obs*C_mat', 'B','[B_mat, L_obs]', ...
    'C','eye(size(A_mat,1))', 'D','zeros(size(A_mat,1),2)', ...
    'X0','zeros(size(A_mat,1),1)');

%% 블록 — 기록
add_block('simulink/Sinks/To Workspace', [name '/x_real'], ...
    'Position', gp(X_W, Y_P), 'VariableName','x_real', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/x_hat'], ...
    'Position', gp(X_W, Y_O), 'VariableName','x_hat', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/Scope', [name '/Scope 비교'], ...
    'Position', [X_W+120, Y_P+60, X_W+170, Y_P+120], 'NumInputPorts','2');

%% 연결
L_ = @(a,b) add_line(name, a, b, 'autorouting','smart');

L_('입력 u/1',        '실제 플랜트/1');
L_('실제 플랜트/1',   '분배/1');
L_('분배/1',          '잡음 더하기/1');
L_('센서 잡음/1',     '잡음 더하기/2');
L_('분배/2',          'x_real/1');
L_('분배/2',          'Scope 비교/1');
L_('입력 u/1',        'u 와 y/1');
L_('잡음 더하기/1',   'u 와 y/2');
L_('u 와 y/1',        '관측기/1');
L_('관측기/1',        'x_hat/1');
L_('관측기/1',        'Scope 비교/2');

%% 신호 이름
set_param(get_param([name '/잡음 더하기'],'PortHandles').Outport(1), 'Name','y_meas');
set_param(get_param([name '/관측기'],'PortHandles').Outport(1), 'Name','xhat');

%% Scope 설정
c1 = get_param([name '/Scope 비교'], 'ScopeConfiguration');
c1.OpenAtSimulationStart = true; c1.ShowLegend = true; c1.ShowGrid = true;
c1.Name = '실제 x 와 추정 xhat';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['위쪽 = 실제 플랜트. 초기조건 x0 가 있습니다.' newline ...
     '아래쪽 = 관측기. 초기조건이 0 입니다. 아무것도 모르고 시작합니다.' newline ...
     '그런데도 따라잡습니다. 그것이 오늘의 요지입니다.'];
a1.position = [X_U, Y_P-190];
a1.FontSize = 12;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['관측기가 받는 것은 u 와 y 뿐입니다.' newline ...
     '진짜 상태는 아무 데도 연결되어 있지 않습니다. 확인해 보십시오.'];
a2.position = [X_MUX-120, Y_O+120];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['noise_pwr 를 키우면 센서 잡음이 커집니다.' newline ...
     '관측기 극을 빠르게 잡을수록 추정값이 더 심하게 떱니다.'];
a3.position = [X_N-40, Y_P-160];
a3.FontSize = 11;

%% 모델만 열어도 돌아가게
% [주의] 조건부(if ~exist)로 두면 안 됩니다.
%        앞 주차 모델이 같은 이름의 변수를 남겨 두면 이 블록이 통째로
%        건너뛰어져 noise_pwr 등이 정의되지 않고 모델이 안 돕니다.
%        **무조건 덮어씁니다.**
preload = strjoin({ ...
 '% W14_ObserverBased 기본 파라미터 (모델을 열 때 자동 실행)'
 '%'
 '% [주의] setup_path 를 안 한 상태에서 모델만 열어도 돌아가야 합니다.'
 '%        경로가 없으면 plant_dcmotor 를 못 찾으므로 아래처럼 숫자로 대신합니다.'
 'if isempty(which(''plant_dcmotor''))'
 '    pp = struct(''A'', [0 1 0; 0 -10 1; 0 -0.02 -2], ...'
 '                ''B'', [0; 0; 2], ''C'', [1 0 0], ''D'', 0);'
 'else'
 '    [~, pp] = plant_dcmotor(''position'');'
 'end'
 'A_mat = pp.A;  B_mat = pp.B;  C_mat = pp.C;'
 % [주의] 아래 줄은 **문자열 안의 코드**다. 작은따옴표가 두 배로 들어간다.
 %        place(...)'  를 쓰려면 여기서는 place(...)''  로 적어야 한다.
 %        네 개를 적으면 전치가 두 번 되어 L 이 행벡터로 나온다.
 'L_obs = place(pp.A'', pp.C'', [-30 -34 -38])'';'
 'x0    = [0.5; 0; 0];'
 'u_amp = 0;  noise_pwr = 0;  t_end = 1.0;'
 'clear pp'
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
fprintf('실행은 W14_03_run_simulink.m 로 하십시오.\n');
