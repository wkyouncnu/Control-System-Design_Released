%% W04_build_lowpass.m
%  4주차 두 번째 Simulink 모델 W04_LowPass.slx 를 코드로 생성합니다. (교수자용)
%
%  모델의 구성
%    느린 사인과 빠른 사인을 더해 "잡음 섞인 신호" 를 만들고,
%    그것을 1차 시스템 1/(tau*s+1) 에 통과시킵니다.
%
%      입력 u(t) = a_lo*sin(w_lo*t) + a_hi*sin(w_hi*t)
%      출력 y(t) = 1/(tau*s+1) 을 지난 것
%
%    빠른 성분만 작아져 나옵니다. 그래서 이 시스템을 **저역통과 필터**라 부릅니다.
%    강의노트 2-4, 2-5 절과 짝입니다.
%
%  제어시스템설계 4주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

name  = 'W04_LowPass';
here  = fileparts(mfilename('fullpath'));
fpath = fullfile(here, [name '.slx']);

if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);

X_SRC = 40;  X_SUM = 180; X_TF = 270; X_MUX = 420; X_SCP = 500; X_WS = 500;
Y_LO  = 120; Y_HI  = 220; Y_MAIN = 120; Y_WS = 230;

gp = @(x,y) [x, y-15, x+70, y+15];
sp = @(x,y) [x, y-10, x+20, y+10];

%% 블록
add_block('simulink/Sources/Sine Wave', [name '/저주파 사인'], ...
    'Position', gp(X_SRC, Y_LO), 'Amplitude','a_lo', 'Frequency','w_lo', 'Bias','0');

add_block('simulink/Sources/Sine Wave', [name '/고주파 사인'], ...
    'Position', gp(X_SRC, Y_HI), 'Amplitude','a_hi', 'Frequency','w_hi', 'Bias','0');

add_block('simulink/Math Operations/Sum', [name '/신호 합치기'], ...
    'Position', sp(X_SUM, Y_MAIN+50), 'Inputs','++', 'IconShape','round');

add_block('simulink/Continuous/Transfer Fcn', [name '/1차 시스템'], ...
    'Position', gp(X_TF, Y_MAIN+50), 'Numerator','[1]', 'Denominator','[tau 1]');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y_MAIN+10, X_MUX+5, Y_MAIN+90], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 비교'], ...
    'Position', [X_SCP, Y_MAIN+25, X_SCP+50, Y_MAIN+75]);

add_block('simulink/Sinks/To Workspace', [name '/uy_sim'], ...
    'Position', gp(X_WS, Y_WS+60), 'VariableName','uy_sim', 'SaveFormat','Timeseries');

%% 연결
L = @(a,b) add_line(name, a, b, 'autorouting','smart');

L('저주파 사인/1',  '신호 합치기/1');
L('고주파 사인/1',  '신호 합치기/2');
L('신호 합치기/1',  '1차 시스템/1');
L('신호 합치기/1',  'Mux/1');           % 입력 (필터를 지나기 전)
L('1차 시스템/1',   'Mux/2');           % 출력 (필터를 지난 뒤)
L('Mux/1',          'Scope 비교/1');
L('Mux/1',          'uy_sim/1');

%% 신호 이름
set_param(get_param([name '/신호 합치기'],'PortHandles').Outport(1), 'Name','u');
set_param(get_param([name '/1차 시스템'],'PortHandles').Outport(1),  'Name','y');

%% Scope 설정
cfg = get_param([name '/Scope 비교'], 'ScopeConfiguration');
cfg.OpenAtSimulationStart = true;
cfg.ShowLegend            = true;
cfg.ShowGrid              = true;
cfg.Name                  = '저역통과 필터 : 입력과 출력';

%% 주석 (슬래시 사용 금지)
a1 = Simulink.Annotation([name '/a1']);
a1.Text = ['느린 사인과 빠른 사인을 더해' newline ...
     '"잡음 섞인 신호" 를 만든다.'];
a1.position = [X_SRC, Y_LO-70];
a1.FontSize = 11;

a2 = Simulink.Annotation([name '/a2']);
a2.Text = ['1차 시스템 1 나누기 (tau s + 1).' newline ...
     '크기비는 1 나누기 sqrt(1 + (w tau)^2) 이므로' newline ...
     'w 가 클수록 작아진다. 그래서 저역통과 필터다.'];
a2.position = [X_TF-40, Y_MAIN-40];
a2.FontSize = 11;

a3 = Simulink.Annotation([name '/a3']);
a3.Text = ['그냥 열어서 Ctrl+T 로 실행해도 됩니다.' newline ...
     'tau 와 두 주파수를 바꿔 가며 실험하려면 W04_04_run_lowpass.m 을 쓰십시오.'];
a3.position = [X_SRC, Y_LO-130];
a3.FontSize = 12;

%% 모델만 열어도 돌아가게
preload = strjoin({ ...
 '% W04_LowPass 기본 파라미터 (모델을 열 때 자동 실행)'
 'defs = { ''tau'',1 ; ''w_lo'',0.2 ; ''w_hi'',10 ; ''a_lo'',1 ; ''a_hi'',0.5 ; ''t_end'',60 };'
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
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [X_SRC, Y_HI+120];
aBlk.FontSize = 11;

%% 저장
save_system(name, fpath);
fprintf('만들었습니다 : %s\n', fpath);
fprintf('  기본값 : tau = 1, 저주파 0.2 rad/s, 고주파 10 rad/s\n');
fprintf('  Ctrl+T 로 실행하면 고주파만 깎여 나가는 것이 보입니다.\n');
