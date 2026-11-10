%% W09_build_examples.m
%  9주차 **단독 실행 Simulink 예제 네 개**를 코드로 생성합니다. (교수자용)
%
%  왜 따로 만드는가
%    W09_Margin_Check.slx 는 선형화까지 다루는 "본 모델" 이라
%    처음 보는 학생에게는 블록이 많습니다.
%    아래 네 개는 **한 개가 한 가지만** 보여 줍니다.
%    각각 따로 열어 그냥 [실행] 만 누르면 되고, 서로 아무 관계가 없습니다.
%
%  네 개가 하는 일
%    W09_E1_LoopOnce    되먹임을 **끊어 놓고** w=1 사인을 한 바퀴만 통과시킨다.
%                       돌아온 진폭이 곧 |L(j1)| 이다. K=2 에서 정확히 1 이 된다.
%    W09_E2_GainMargin  E1 과 똑같은 플랜트에 **되먹임선 하나만 더** 그었다.
%                       K = 0.5 / 2 / 3 에서 수렴 · 지속진동 · 발산.
%    W09_E3_DelayMargin K 는 0.5 로 고정하고 **시간지연만** 키운다.
%                       크기는 그대로인데 위상여유가 깎여 발산한다.
%    W09_E4_Bandwidth   폐루프에 사인을 하나씩 넣어 **진폭비**를 잰다.
%                       1 을 넘는 곳이 공진봉우리, 0.707 이 되는 곳이 대역폭.
%
%  네 모델이 쓰는 플랜트는 전부 같습니다 — 강의자료 6장의 G = 1 over s(s+1)^2.
%  달라지는 것은 **연결과 손잡이 하나**뿐이고, 그것이 이 예제들의 요점입니다.
%
%  실행은 W09_07_examples.m 로 하십시오 (네 모델을 차례로 돌려 손계산과 대조).
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

clc; clear; close all;

here = fileparts(mfilename('fullpath'));
bdclose('all');

build_e1(here);
build_e2(here);
build_e3(here);
build_e4(here);

fprintf('\n네 개의 단독 예제 모델을 만들었습니다.\n');
fprintf('실행은 W09_07_examples.m 로 하십시오.\n');


% =====================================================================
%  E1. 루프를 끊고 한 바퀴만 — 돌아온 진폭이 |L| 이다
% =====================================================================
function build_e1(here)
name = 'W09_E1_LoopOnce';
fresh(name, here);

X_SIN=40; X_K=190; X_PL=300; X_MUX=480; X_SCP=550; X_WS=480;
Y=140; Y_WS=250;

add_block('simulink/Sources/Sine Wave', [name '/사인 입력'], ...
    'Position', gp(X_SIN,Y), 'Amplitude','1', 'Frequency','w_in', 'Bias','0');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_K,Y), 'Gain','K');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G(s)'], ...
    'Position', tp(X_PL,Y), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y-40, X_MUX+5, Y+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 한바퀴'], ...
    'Position', [X_SCP, Y-26, X_SCP+50, Y+26]);

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_WS,Y_WS), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_WS,Y_WS+60), 'VariableName','u_sim', 'SaveFormat','Timeseries');

ln(name, '사인 입력/1',   '비례이득 K/1');
ln(name, '비례이득 K/1',  '플랜트 G(s)/1');
ln(name, '플랜트 G(s)/1', 'Mux/1');
ln(name, '사인 입력/1',   'Mux/2');
ln(name, 'Mux/1',         'Scope 한바퀴/1');
ln(name, '플랜트 G(s)/1', 'y_sim/1');
ln(name, '사인 입력/1',   'u_sim/1');

scope_cfg(name, 'Scope 한바퀴', '돌아온 신호와 넣은 신호');

note(name, ['되먹임선이 없습니다. 신호가 한 바퀴만 지나갑니다.' newline ...
    'w_in = 1 은 이 플랜트의 위상이 정확히 -180 도가 되는 주파수입니다.' newline ...
    '돌아온 사인은 넣은 사인과 위아래가 뒤집혀 있고,' newline ...
    '그 진폭이 바로 루프이득의 크기 |L(j1)| = K 나누기 2 입니다.'], ...
    [X_SIN, Y-130], 12);

note(name, ['K 를 0.5 / 2 / 3 으로 바꿔 보십시오.' newline ...
    '돌아온 진폭이 0.25 / 1.00 / 1.50 으로 나옵니다.' newline ...
    '진폭이 1 이 되는 K 가 안정 한계이고, 그것이 이득여유의 정의입니다.' newline ...
    '루프를 닫으면 어떻게 되는지는 W09_E2_GainMargin 에서 봅니다.'], ...
    [X_K-40, Y+80], 11);

preload(name, { ...
 'defs = { ''K'',2 ; ''w_in'',1 ; ''t_end'',40 ;'
 '         ''numG'',1 ; ''denG'',[1 2 1 0] };'});

finish(name, here);
end


% =====================================================================
%  E2. 루프를 닫으면 — K 세 개로 안정 한계를 통과한다
% =====================================================================
function build_e2(here)
name = 'W09_E2_GainMargin';
fresh(name, here);

X_SRC=40; X_ERR=180; X_K=250; X_PL=370; X_MUX=560; X_SCP=630; X_WS=560;
Y=140; Y_WS=270;

add_block('simulink/Sources/Step', [name '/목표값 r'], ...
    'Position', gp(X_SRC,Y), 'Time','0', 'Before','0', 'After','1');

add_block('simulink/Math Operations/Sum', [name '/오차'], ...
    'Position', sp(X_ERR,Y), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_K,Y), 'Gain','K');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G(s)'], ...
    'Position', tp(X_PL,Y), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y-40, X_MUX+5, Y+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 출력'], ...
    'Position', [X_SCP, Y-26, X_SCP+50, Y+26]);

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_WS,Y_WS), 'VariableName','y_sim', 'SaveFormat','Timeseries');

ln(name, '목표값 r/1',    '오차/1');
ln(name, '오차/1',        '비례이득 K/1');
ln(name, '비례이득 K/1',  '플랜트 G(s)/1');
ln(name, '플랜트 G(s)/1', '오차/2');
ln(name, '플랜트 G(s)/1', 'Mux/1');
ln(name, '목표값 r/1',    'Mux/2');
ln(name, 'Mux/1',         'Scope 출력/1');
ln(name, '플랜트 G(s)/1', 'y_sim/1');

scope_cfg(name, 'Scope 출력', '출력과 목표값');

note(name, ['W09_E1_LoopOnce 와 블록이 똑같습니다.' newline ...
    '더해진 것은 플랜트 출력에서 오차로 돌아가는 **되먹임선 하나**뿐입니다.' newline ...
    'E1 에서 잰 진폭이 1 보다 작으면 여기서 수렴하고, 크면 발산합니다.'], ...
    [X_SRC, Y-130], 12);

note(name, ['K 를 0.5 / 2 / 3 으로 바꿔 보십시오.' newline ...
    '0.5 는 수렴, 2 는 진폭이 일정한 지속진동, 3 은 발산입니다.' newline ...
    'K = 2 가 안정 한계이고, K = 0.5 에서 본 이득여유 4 배와 정확히 맞습니다.' newline ...
    '진동 주기는 약 6.3 초 - E1 에서 넣었던 w = 1 그 주파수입니다.'], ...
    [X_ERR-40, Y+90], 11);

preload(name, { ...
 'defs = { ''K'',0.5 ; ''t_end'',60 ;'
 '         ''numG'',1 ; ''denG'',[1 2 1 0] };'});

finish(name, here);
end


% =====================================================================
%  E3. 이득은 그대로, 지연만 — 위상여유만 깎인다
% =====================================================================
function build_e3(here)
name = 'W09_E3_DelayMargin';
fresh(name, here);

X_SRC=40; X_ERR=180; X_K=250; X_DLY=360; X_PL=490; X_MUX=680; X_SCP=750; X_WS=680;
Y=140; Y_WS=280;

add_block('simulink/Sources/Step', [name '/목표값 r'], ...
    'Position', gp(X_SRC,Y), 'Time','0', 'Before','0', 'After','1');

add_block('simulink/Math Operations/Sum', [name '/오차'], ...
    'Position', sp(X_ERR,Y), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_K,Y), 'Gain','K');

add_block('simulink/Continuous/Transport Delay', [name '/시간지연'], ...
    'Position', gp(X_DLY,Y), 'DelayTime','tau_d');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G(s)'], ...
    'Position', tp(X_PL,Y), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y-40, X_MUX+5, Y+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 출력'], ...
    'Position', [X_SCP, Y-26, X_SCP+50, Y+26]);

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_WS,Y_WS), 'VariableName','y_sim', 'SaveFormat','Timeseries');

ln(name, '목표값 r/1',    '오차/1');
ln(name, '오차/1',        '비례이득 K/1');
ln(name, '비례이득 K/1',  '시간지연/1');
ln(name, '시간지연/1',    '플랜트 G(s)/1');
ln(name, '플랜트 G(s)/1', '오차/2');
ln(name, '플랜트 G(s)/1', 'Mux/1');
ln(name, '목표값 r/1',    'Mux/2');
ln(name, 'Mux/1',         'Scope 출력/1');
ln(name, '플랜트 G(s)/1', 'y_sim/1');

scope_cfg(name, 'Scope 출력', '출력과 목표값');

note(name, ['W09_E2_GainMargin 에 **지연 블록 하나만** 끼워 넣었습니다.' newline ...
    'K 는 0.5 로 고정입니다. 이득은 전혀 건드리지 않습니다.' newline ...
    '그런데도 지연만으로 불안정해집니다 - 깎인 것은 위상여유입니다.'], ...
    [X_SRC, Y-130], 12);

note(name, ['tau_d 를 0 / 0.9 / 1.81 / 2.7 로 바꿔 보십시오.' newline ...
    'K = 0.5 에서 위상여유는 44.1 도, 교차주파수는 0.424 rad/s 입니다.' newline ...
    '견딜 수 있는 지연은 tau_max = 44.1 도를 라디안으로 바꾼 값 나누기 0.424' newline ...
    '= 1.81 초입니다. tau_d = 1.81 에서 정확히 지속진동이 나옵니다.'], ...
    [X_DLY-120, Y+90], 11);

preload(name, { ...
 'defs = { ''K'',0.5 ; ''tau_d'',0 ; ''t_end'',80 ;'
 '         ''numG'',1 ; ''denG'',[1 2 1 0] };'});

finish(name, here);
end


% =====================================================================
%  E4. 폐루프에 사인을 넣어 공진봉우리와 대역폭을 직접 잰다
% =====================================================================
function build_e4(here)
name = 'W09_E4_Bandwidth';
fresh(name, here);

X_SIN=40; X_ERR=200; X_K=270; X_PL=390; X_MUX=580; X_SCP=650; X_WS=580;
Y=140; Y_WS=280;

add_block('simulink/Sources/Sine Wave', [name '/사인 입력'], ...
    'Position', gp(X_SIN,Y), 'Amplitude','1', 'Frequency','w_in', 'Bias','0');

add_block('simulink/Math Operations/Sum', [name '/오차'], ...
    'Position', sp(X_ERR,Y), 'Inputs','+-', 'IconShape','round');

add_block('simulink/Math Operations/Gain', [name '/비례이득 K'], ...
    'Position', gp(X_K,Y), 'Gain','K');

add_block('simulink/Continuous/Transfer Fcn', [name '/플랜트 G(s)'], ...
    'Position', tp(X_PL,Y), 'Numerator','numG', 'Denominator','denG');

add_block('simulink/Signal Routing/Mux', [name '/Mux'], ...
    'Position', [X_MUX, Y-40, X_MUX+5, Y+40], 'Inputs','2');

add_block('simulink/Sinks/Scope', [name '/Scope 진폭비'], ...
    'Position', [X_SCP, Y-26, X_SCP+50, Y+26]);

add_block('simulink/Sinks/To Workspace', [name '/y_sim'], ...
    'Position', gp(X_WS,Y_WS), 'VariableName','y_sim', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/To Workspace', [name '/u_sim'], ...
    'Position', gp(X_WS,Y_WS+60), 'VariableName','u_sim', 'SaveFormat','Timeseries');

ln(name, '사인 입력/1',   '오차/1');
ln(name, '오차/1',        '비례이득 K/1');
ln(name, '비례이득 K/1',  '플랜트 G(s)/1');
ln(name, '플랜트 G(s)/1', '오차/2');
ln(name, '플랜트 G(s)/1', 'Mux/1');
ln(name, '사인 입력/1',   'Mux/2');
ln(name, 'Mux/1',         'Scope 진폭비/1');
ln(name, '플랜트 G(s)/1', 'y_sim/1');
ln(name, '사인 입력/1',   'u_sim/1');

scope_cfg(name, 'Scope 진폭비', '넣은 사인과 나온 사인');

note(name, ['이번에는 루프가 **닫혀 있습니다.** 그래서 재는 것은 폐루프 T 입니다.' newline ...
    '8주차에서 플랜트의 보드 선도를 사인으로 쟀던 그 방법을' newline ...
    '이번에는 폐루프에 그대로 적용합니다.'], ...
    [X_SIN, Y-130], 12);

note(name, ['w_in 을 0.1 / 0.4 / 0.8 / 1.1 / 1.5 / 2 로 바꿔 보십시오.' newline ...
    '나온 사인의 진폭을 넣은 진폭 1 로 나눈 것이 폐루프 크기입니다.' newline ...
    '저주파에서는 1 에 가깝고, 어디선가 1 을 넘어 봉우리를 만들고' newline ...
    '(공진봉우리 Mr), 0.707 로 떨어진 곳이 대역폭 w_BW 입니다.' newline ...
    '처음 몇 초는 과도구간이니 **뒤쪽 정상상태에서 진폭을 재십시오.**'], ...
    [X_ERR-60, Y+90], 11);

preload(name, { ...
 'defs = { ''K'',0.5 ; ''w_in'',0.4 ; ''t_end'',120 ;'
 '         ''numG'',1 ; ''denG'',[1 2 1 0] };'});

finish(name, here);
end


% =====================================================================
%  네 모델이 함께 쓰는 짧은 도우미들
%  (강의노트 규칙상 예제 쪽에는 함수를 쓰지 않지만,
%   이 파일은 학생용 예제가 아니라 **교수자용 생성 스크립트**입니다.)
% =====================================================================

function fresh(name, here)
% 같은 이름이 열려 있거나 파일이 있으면 지우고 새로 만든다
fpath = fullfile(here, [name '.slx']);
if bdIsLoaded(name), close_system(name, 0); end
if isfile(fpath),    delete(fpath);          end
new_system(name);
open_system(name);
end

function finish(name, here)
set_param(name, 'Solver','ode45', 'StopTime','t_end', ...
                'SolverType','Variable-step', 'MaxStep','0.02');

% 블록 설명표는 common/model_blocks.m 한 곳에서만 관리한다
aBlk = Simulink.Annotation([name '/aBlk']);
aBlk.Text = model_blocks(name, 'note');
aBlk.position = [40, -240];
aBlk.FontSize = 11;

fpath = fullfile(here, [name '.slx']);
save_system(name, fpath);
fprintf('  저장 : %s\n', [name '.slx']);
end

function p = gp(x, y)
p = [x, y-16, x+68, y+16];       % 일반 블록
end

function p = sp(x, y)
p = [x, y-10, x+20, y+10];       % 합산점
end

function p = tp(x, y)
p = [x, y-24, x+140, y+24];      % 전달함수 (분수가 들어가므로 넓게)
end

function ln(name, a, b)
add_line(name, a, b, 'autorouting','smart');
end

function scope_cfg(name, blk, ttl)
c = get_param([name '/' blk], 'ScopeConfiguration');
c.OpenAtSimulationStart = true;
c.ShowLegend = true;
c.ShowGrid   = true;
c.Name       = ttl;
end

function note(name, txt, pos, fsz)
% 주석. 텍스트에 슬래시를 쓰면 블록 경로로 오인되므로 쓰지 않는다
persistent n
if isempty(n), n = 0; end
n = n + 1;
a = Simulink.Annotation([name '/note' num2str(n)]);
a.Text = txt;
a.position = pos;
a.FontSize = fsz;
end

function preload(name, lines)
% 모델만 열어도 그냥 돌아가도록 기본 파라미터를 심는다.
% 이미 작업공간에 있는 값은 건드리지 않는다.
body = [ {['% ' name ' 기본 파라미터 (모델을 열 때 자동 실행)']} ...
         lines(:)' ...
         { 'for ii = 1:size(defs,1)'
           '    if ~evalin(''base'', sprintf(''exist(''''%s'''',''''var'''')'', defs{ii,1}))'
           '        assignin(''base'', defs{ii,1}, defs{ii,2});'
           '    end'
           'end'
           'clear defs ii' }' ];
set_param(name, 'PreLoadFcn', strjoin(body, newline));
end
