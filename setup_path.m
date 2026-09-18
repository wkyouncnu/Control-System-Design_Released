function setup_path()
%SETUP_PATH  제어시스템설계 실습 폴더를 MATLAB 경로에 등록합니다.
%
%   실습을 시작하기 전에 MATLAB 명령창에서 딱 한 번 실행하십시오.
%
%       >> setup_path
%
%   이 명령은 common 폴더(공통 플랜트 함수들)와 각 주차 폴더를 경로에 추가합니다.
%   경로에 등록되어 있어야 plant_msd, plant_dcmotor 같은 함수를 어느 폴더에서든
%   부를 수 있고, Simulink 모델도 정상적으로 열립니다.
%
%   폴더를 다른 컴퓨터로 옮겨도 이 파일만 실행하면 됩니다.
%   (경로가 하드코딩되어 있지 않고 이 파일의 위치를 기준으로 잡습니다.)

% 제어시스템설계 | 충남대학교 자율운항시스템공학과

root = fileparts(mfilename('fullpath'));

% genpath 로 하위 폴더를 모두 모은 뒤, 밑줄로 시작하는 폴더는 제외합니다.
%   _src     : 강의노트(.mlx) 를 만들어 낸 원본 스크립트 (교수자용)
%   _archive : 예전 습작 파일 보관함
% 이 폴더들이 경로에 있으면 학생이 실수로 실행하거나 이름이 충돌할 수 있습니다.
allPaths = strsplit(genpath(root), pathsep);
allPaths = allPaths(~cellfun(@isempty, allPaths));
keep = true(size(allPaths));
for i = 1:numel(allPaths)
    parts = strsplit(allPaths{i}, filesep);
    if any(startsWith(parts, '_'))
        keep(i) = false;
    end
end
addpath(strjoin(allPaths(keep), pathsep));

fprintf('\n');
fprintf('==========================================================\n');
fprintf('  제어시스템설계 실습 경로 등록 완료\n');
fprintf('==========================================================\n');
fprintf('  루트 폴더 : %s\n', root);
fprintf('\n');
fprintf('  사용 가능한 공통 함수\n');
fprintf('    plant_msd       질량-스프링-댐퍼 플랜트      (1~5주차)\n');
fprintf('    plant_dcmotor   DC 모터 플랜트               (5~11주차)\n');
fprintf('    plant_pendulum  단진자 플랜트 (선형화용)     (3주차)\n');
fprintf('    pendulum_ode    단진자 비선형 상태방정식\n');
fprintf('    spec2pole       사양(%%OS, ts) -> 목표 극점        (4주차부터)\n');
fprintf('    rl_scan         근궤적 이득 훑어 성능표 만들기    (7주차부터)\n');
fprintf('    ctrl_input      계단 지령에 대한 제어입력 u(t)    (7주차부터)\n');
fprintf('\n');
fprintf('  주차별 폴더\n');
d = dir(fullfile(root, 'W*'));
for i = 1:numel(d)
    if d(i).isdir
        fprintf('    %s\n', d(i).name);
    end
end
fprintf('\n');

%% 필요한 툴박스가 있는지 확인한다
%  없는 툴박스를 쓰는 줄에서 스크립트가 멈추면 학생은 원인을 모릅니다.
%  그래서 시작할 때 한 번에 알려 줍니다.
%
%  필수  : 없으면 대부분의 실습이 안 됩니다
%  선택  : 그 절만 자동으로 건너뜁니다. 나머지는 정상 동작합니다
need = {
 'Control_Toolbox',          'Control System Toolbox',    '필수', '거의 모든 주차'
 'Simulink',                 'Simulink',                  '필수', '모든 주차의 .slx'
 'Simulink_Control_Design',  'Simulink Control Design',   '선택', '3주차 6절, 10주차 6절 (linearize)'
 'Symbolic_Toolbox',         'Symbolic Math Toolbox',     '선택', '3주차 3절, 13주차 2-2절 (jacobian)'
 };
missReq = {};  missOpt = {};
for i = 1:size(need,1)
    if ~license('test', need{i,1})
        if strcmp(need{i,3}, '필수'), missReq{end+1} = need(i,:); %#ok<AGROW>
        else,                          missOpt{end+1} = need(i,:); %#ok<AGROW>
        end
    end
end

if isempty(missReq) && isempty(missOpt)
    fprintf('  툴박스 : 필요한 것이 전부 있습니다.\n');
else
    for i = 1:numel(missReq)
        fprintf('  [!] %s 가 없습니다 (필수) — %s\n', missReq{i}{2}, missReq{i}{4});
    end
    for i = 1:numel(missOpt)
        fprintf('  [--] %s 가 없습니다 (선택) — %s\n', missOpt{i}{2}, missOpt{i}{4});
    end
    if ~isempty(missOpt)
        fprintf('       선택 항목은 해당 절만 건너뛰고 나머지는 정상 동작합니다.\n');
    end
end

fprintf('\n');
fprintf('  도움말을 보려면 예를 들어  >> help plant_msd  라고 입력하십시오.\n');
fprintf('==========================================================\n\n');

end
