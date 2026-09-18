function report = verify_runnable(only)
%VERIFY_RUNNABLE  학생이 실제로 돌리는 방식 그대로 전부 실행해 본다
%
%   verify_runnable()        전 주차
%   verify_runnable('W07')   한 주차만
%   R = verify_runnable();   결과를 구조체로 받는다
%
%   왜 verify_all 과 따로 있는가
%     `verify_all` 은 **만드는 쪽**을 검사합니다 (원본이 도는가, mlx 가 깨졌는가).
%     이 함수는 **쓰는 쪽**을 검사합니다. 학생이 파일을 열어 실행하는
%     그 상황을 그대로 재현합니다.
%
%   네 가지를 봅니다
%     (1) 실습 스크립트  — 자기 폴더에서, 앞의 변수가 하나도 없는 상태로
%     (2) 강의노트 .mlx  — 파일을 열고 [모두 실행] 을 누른 것과 같게
%     (3) Simulink 모델  — 스크립트 없이 열어서 Ctrl+T 를 누른 것과 같게
%     (4) 숙제와 해답    — 위 (2) 와 같은 방식
%
%   각 항목은 **깨끗한 작업공간**에서 시작합니다.
%   앞 파일이 남긴 변수 덕분에 우연히 도는 경우를 잡아내기 위해서입니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1, only = ''; end

root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
run(fullfile(root, 'setup_path.m'));

wk = dir(fullfile(root, 'W*'));
wk = wk([wk.isdir]);
[~, ord] = sort({wk.name});  wk = wk(ord);
if ~isempty(only)
    wk = wk(startsWith({wk.name}, only));
end

report = struct('kind', {}, 'file', {}, 'ok', {}, 'msg', {}, 'sec', {});

fprintf('\n==================================================================\n');
fprintf('  실행 검증 — 학생이 여는 방식 그대로\n');
fprintf('==================================================================\n');

for w = 1:numel(wk)
    wd  = fullfile(root, wk(w).name);
    key = extractBefore(wk(w).name, '_');
    fprintf('\n[%s] %s\n', key, wk(w).name);

    % ---------- (1) 실습 스크립트 ----------
    sc = dir(fullfile(wd, 'W*_0*.m'));
    for i = 1:numel(sc)
        report(end+1) = local_run_script(fullfile(sc(i).folder, sc(i).name), '스크립트'); %#ok<AGROW>
    end

    % ---------- (2) 강의노트 ----------
    nt = dir(fullfile(wd, '*LectureNote.mlx'));
    for i = 1:numel(nt)
        report(end+1) = local_run_mlx(fullfile(nt(i).folder, nt(i).name), '강의노트'); %#ok<AGROW>
    end

    % ---------- (3) Simulink 모델 (스크립트 없이) ----------
    md = dir(fullfile(wd, '*.slx'));
    for i = 1:numel(md)
        report(end+1) = local_run_model(fullfile(md(i).folder, md(i).name)); %#ok<AGROW>
    end

    % ---------- (4) 숙제와 해답 ----------
    hw = dir(fullfile(wd, 'hw', '*.mlx'));
    for i = 1:numel(hw)
        report(end+1) = local_run_mlx(fullfile(hw(i).folder, hw(i).name), '숙제'); %#ok<AGROW>
    end
end

%% 요약
nOK  = sum([report.ok]);
nBad = numel(report) - nOK;
fprintf('\n==================================================================\n');
fprintf('  요약 : %d 개 중 %d 개 통과, %d 개 실패\n', numel(report), nOK, nBad);
fprintf('  전체 소요 %.0f 초\n', sum([report.sec]));
if nBad > 0
    fprintf('\n  실패 목록\n');
    bad = report(~[report.ok]);
    for i = 1:numel(bad)
        fprintf('   [!] %-10s %-34s %s\n', bad(i).kind, bad(i).file, local_short(bad(i).msg));
    end
else
    fprintf('  전부 통과했습니다.\n');
end
fprintf('==================================================================\n\n');

if nargout == 0, clear report; end
end


% ======================================================================
function r = local_run_script(fp, kind)
%  자기 폴더로 옮겨 가서, 앞의 변수를 전부 지우고 실행한다
[fdir, base, ext] = fileparts(fp);
r = struct('kind', kind, 'file', [base ext], 'ok', false, 'msg', '', 'sec', 0);
old = pwd;  t0 = tic;
%  [주의] 실습 스크립트는 맨 위에 `clear all` 이 있습니다.
%         이 함수 안에서 그냥 `run` 하면 **이 함수의 변수까지 지워집니다.**
%         그래서 base 작업공간에서 돌립니다. 그러면 clear 가 base 만 건드립니다.
cmd = sprintf('run(''%s'')', fp);
try
    cd(fdir);
    evalin('base', 'clear variables');           % 앞 파일의 흔적을 지운다
    evalc('evalin(''base'', cmd)');
    r.ok = true;
catch ME
    r.msg = ME.message;
end
r.sec = toc(t0);
cd(old);  close all force;  bdclose all;
fprintf('   %s %-34s %-8s %5.1f s%s\n', local_mark(r.ok), r.file, kind, r.sec, ...
        local_tail(r));
end


% ======================================================================
function r = local_run_mlx(fp, kind)
%  .mlx 를 임시로 복사해 [모두 실행] 과 같게 돌린다
%  원본을 건드리지 않으려고 복사본을 쓴다 (실행 결과가 파일에 박히기 때문)
[~, base, ext] = fileparts(fp);
r = struct('kind', kind, 'file', [base ext], 'ok', false, 'msg', '', 'sec', 0);
tmp = fullfile(tempdir, sprintf('vr_%s%s', base, ext));
t0 = tic;
try
    copyfile(fp, tmp, 'f');
    evalin('base', 'clear variables');
    matlab.internal.liveeditor.executeAndSave(tmp);
    % [핵심] 라이브 스크립트의 실행 오류는 **예외로 안 올라옵니다.**
    %        .mlx 안 matlab/output.xml 에 <type>error</type> 로 기록됩니다.
    %        예외만 잡으면 오류가 난 문서도 통과한 것처럼 보입니다.
    r.msg = local_mlx_error(tmp);
    r.ok  = isempty(r.msg);
catch ME
    r.msg = ME.message;
end
if isfile(tmp), delete(tmp); end
r.sec = toc(t0);
close all force;  bdclose all;
fprintf('   %s %-34s %-8s %5.1f s%s\n', local_mark(r.ok), r.file, kind, r.sec, ...
        local_tail(r));
end


% ======================================================================
function r = local_run_model(fp)
%  스크립트 없이 모델만 열어서 돌린다 (Ctrl+T 와 같다)
%  PreLoadFcn 이 제대로 값을 채우는지 보는 것이 목적이다
[~, name] = fileparts(fp);
r = struct('kind', '모델', 'file', [name '.slx'], 'ok', false, 'msg', '', 'sec', 0);
t0 = tic;
cmd = sprintf('sim(''%s'');', name);
try
    bdclose all;
    evalin('base', 'clear variables');           % PreLoadFcn 만으로 돌아야 한다
    load_system(fp);
    evalc('evalin(''base'', cmd)');
    r.ok = true;
catch ME
    r.msg = ME.message;
end
r.sec = toc(t0);
bdclose all;  close all force;
fprintf('   %s %-34s %-8s %5.1f s%s\n', local_mark(r.ok), r.file, '모델', r.sec, ...
        local_tail(r));
end


% ======================================================================
function s = local_mark(ok)
if ok, s = '[OK]'; else, s = '[!!]'; end
end

function s = local_tail(r)
if r.ok, s = ''; else, s = ['   <- ' local_short(r.msg)]; end
end

function s = local_short(m)
m = regexprep(char(m), '\s+', ' ');
if strlength(m) > 110, s = [char(extractBefore(m, 110)) ' ...']; else, s = m; end
end

function msg = local_mlx_error(mlxPath)
%LOCAL_MLX_ERROR  실행한 .mlx 안에 기록된 오류 메시지를 꺼낸다
%
%  .mlx 는 zip 이고, 실행 결과는 matlab/output.xml 에 들어 있습니다.
%  오류가 난 셀은 <type>error</type> 로 표시되고 바로 뒤 <text> 가 메시지입니다.
%  오류가 없으면 빈 문자열을 돌려줍니다.
msg = '';
d = fullfile(tempdir, ['vr_unz_' char(matlab.lang.internal.uuid)]);
try
    unzip(mlxPath, d);
    op = fullfile(d, 'matlab', 'output.xml');
    if isfile(op)
        t = fileread(op);
        if contains(t, '<type>error</type>')
            tk = regexp(t, '<type>error</type>\s*<outputData>\s*<text>(.*?)</text>', ...
                        'tokens', 'once');
            if ~isempty(tk), msg = tk{1};
            else,            msg = '실행 중 오류가 기록되었습니다';
            end
        end
    else
        msg = 'output.xml 이 없습니다 (실행이 안 된 것으로 보입니다)';
    end
catch ME
    msg = ['결과 확인 실패 : ' ME.message];
end
if isfolder(d), rmdir(d, 's'); end
end
