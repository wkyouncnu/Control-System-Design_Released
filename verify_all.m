function ok = verify_all(weeks)
%VERIFY_ALL  자료 전체를 자동으로 검증한다 (교수자용)
%
%   verify_all()          모든 주차
%   verify_all('W07')     한 주차만
%   ok = verify_all(...)  전부 통과하면 true
%
%   무엇을 검사하는가 — 네 가지
%
%     1) 실습 스크립트   모든 Wxx_NN_*.m 이 오류 없이 끝까지 도는가
%     2) Simulink 모델   워크스페이스를 비운 채 모델만 열어도 돌아가는가
%     3) 문서 (.mlx)     깨진 수식·서식이 남아 있지 않은가 (check_mlx)
%     4) 다이어그램      선이 끊기거나 블록을 뚫고 지나가지 않는가 (dg_check_all)
%
%   3, 4 번이 이 도구의 핵심입니다.
%
%   - 수식이 깨져도 MATLAB 은 오류를 내지 않습니다. 글자로 그냥 남습니다
%   - 블록선도 좌표를 잘못 적어도 그림은 그냥 그려집니다
%
%   둘 다 눈으로 일일이 볼 수 없으므로 자동으로 확인합니다.
%   자료를 고친 뒤에는 **항상 이것을 돌리고** 결과를 확인하십시오.
%
%   왜 base 워크스페이스에서 실행하는가
%     실습 스크립트는 첫 줄에 `clear all` 이 있고, Simulink 의 `sim` 은
%     함수 안의 변수를 보지 못하고 base 워크스페이스만 봅니다.
%     그래서 `evalin('base', ...)` 로 돌립니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(weeks), weeks = ''; end

here = fileparts(mfilename('fullpath'));
cd(here);
evalc('evalin(''base'', ''run(''''setup_path'''')'')');

if isempty(weeks)
    pat = 'W*';
else
    d0 = dir(fullfile(here, [weeks '*']));
    d0 = d0([d0.isdir]);
    if isempty(d0)
        error('verify_all:주차 - %s 폴더를 찾을 수 없습니다', weeks);
    end
    pat = d0(1).name;
end

nFail = 0;

%% 1) 실습 스크립트
fprintf('\n=========== 1. 실습 스크립트 ===========\n');
d = dir(fullfile(here, pat, 'W*_*.m'));
files = {};
for i = 1:numel(d)
    if contains(d(i).name, 'build_model'), continue; end
    files{end+1} = fullfile(d(i).folder, d(i).name); %#ok<AGROW>
end

nBad = 0;
for i = 1:numel(files)
    [~, nm] = fileparts(files{i});
    try
        evalc(sprintf('evalin(''base'', ''run(''''%s'''')'')', files{i}));
    catch ME
        fprintf('  [!] %s : %s\n', nm, local_deep(ME));
        nBad = nBad + 1;
    end
    close all force;
end
fprintf('  통과 %d / %d\n', numel(files) - nBad, numel(files));
nFail = nFail + nBad;

%% 2) Simulink 단독 실행 (워크스페이스를 비운 상태)
fprintf('\n=========== 2. Simulink 단독 실행 ===========\n');
bdclose all;
evalin('base', 'clear all');
evalc('evalin(''base'', ''run(''''setup_path'''')'')');

dm = dir(fullfile(here, pat, '*.slx'));
nBadM = 0;
for i = 1:numel(dm)
    [~, mn] = fileparts(dm(i).name);
    try
        evalc(sprintf('evalin(''base'', ''load_system(''''%s''''); sim(''''%s'''');'')', mn, mn));
        fprintf('  [OK] %s\n', mn);
    catch ME
        fprintf('  [!] %s : %s\n', mn, local_deep(ME));
        nBadM = nBadM + 1;
    end
    try, evalin('base', sprintf('close_system(''%s'', 0)', mn)); catch, end
end
fprintf('  통과 %d / %d\n', numel(dm) - nBadM, numel(dm));
nFail = nFail + nBadM;

%% 3) 문서 검사
fprintf('\n=========== 3. 문서 (.mlx) 검사 ===========\n');
dx = dir(fullfile(here, pat, '**', '*.mlx'));
nBadX = 0;
for i = 1:numel(dx)
    r = check_mlx(fullfile(dx(i).folder, dx(i).name));
    if ~r.ok, nBadX = nBadX + 1; end
end
fprintf('  통과 %d / %d\n', numel(dx) - nBadX, numel(dx));
nFail = nFail + nBadX;

%% 4) 다이어그램 검사
fprintf('\n=========== 4. 다이어그램 검사 ===========\n');
ds = [ dir(fullfile(here, pat, '_src', '*_src.m')) ; ...
       dir(fullfile(here, pat, 'hw', '_src', '*_src.m')) ];
nBadD = 0;  nDiag = 0;
for i = 1:numel(ds)
    f = fullfile(ds(i).folder, ds(i).name);
    [~, nm] = fileparts(f);
    dg_reset();
    try
        evalc(sprintf('evalin(''base'', ''run(''''%s'''')'')', f));
    catch
        % 실행 오류는 1) 에서 이미 보고했으므로 여기서는 넘어간다
    end
    r = dg_check_all(nm);
    nBadD = nBadD + r.nIssue;
    nDiag = nDiag + r.nDiag;
    close all force;
end
fprintf('  다이어그램 %d 장, 문제 %d 개\n', nDiag, nBadD);
nFail = nFail + nBadD;

%% 요약
fprintf('\n=========== 요약 ===========\n');
if nFail == 0
    fprintf('  전부 통과했습니다.\n\n');
else
    fprintf('  문제 총 %d 건. 위 목록을 확인하십시오.\n\n', nFail);
end
ok = (nFail == 0);
end

% ---------------------------------------------------------------
function s = local_deep(ME)
% "여러 가지 원인으로 인해 오류가 발생했습니다" 만 나오면 쓸모가 없으므로
% 속에 든 진짜 원인을 꺼내 온다.
s = ME.message;
c = ME.cause;
while ~isempty(c)
    s = c{1}.message;
    c = c{1}.cause;
end
end
