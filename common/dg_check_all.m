function rep = dg_check_all(name, verbose)
%DG_CHECK_ALL  한 파일이 그린 블록선도를 **전부** 검사한다
%
%   dg_reset()                     % 검사 전에 보관함을 비운다
%   run('W01_LectureNote_src.m')   % 파일을 실행하면 그림이 그려지고 기록된다
%   rep = dg_check_all('W01')      % 그려진 그림을 전부 검사
%
%   왜 dg_check 가 아니라 이것을 쓰는가
%     dg_check 는 **마지막에 그린 한 장**만 봅니다.
%     강의노트에는 그림이 여러 장 들어가므로 전부 봐야 합니다.
%     dg_new 를 부를 때마다 앞 그림이 보관함에 쌓이고,
%     이 함수가 보관함을 처음부터 끝까지 훑습니다.
%
%   검사 항목은 dg_check 와 같습니다 (끊긴 선, 관통, 겹침, 외톨이, 도화지 밖).
%
%   출력  rep - 구조체
%     rep.ok      전부 문제 없으면 true
%     rep.nDiag   검사한 그림 수
%     rep.nIssue  문제 총 개수
%     rep.msg     문제 설명
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(name),    name = '(이름 없음)'; end
if nargin < 2 || isempty(verbose), verbose = true;       end

% 아직 보관함에 안 들어간 마지막 그림도 넣는다
cur = getappdata(0, 'DG_REG');
lg  = getappdata(0, 'DG_LOG');
if isempty(lg), lg = {}; end
if ~isempty(cur) && (~isempty(cur.boxes) || ~isempty(cur.arrows))
    lg{end+1} = cur;
end

msg = string.empty;
for i = 1:numel(lg)
    setappdata(0, 'DG_REG', lg{i});
    r = dg_check(sprintf('%s 그림 %d', name, i), false);
    for k = 1:numel(r.msg)
        msg(end+1) = sprintf('그림 %d : %s', i, r.msg(k)); %#ok<AGROW>
    end
end
setappdata(0, 'DG_REG', cur);

rep = struct('ok', isempty(msg), 'nDiag', numel(lg), ...
             'nIssue', numel(msg), 'msg', msg);

if verbose
    if numel(lg) == 0
        fprintf('  [--] %s : 그린 다이어그램 없음\n', name);
    elseif rep.ok
        fprintf('  [OK] %s : 다이어그램 %d 장, 문제 없음\n', name, numel(lg));
    else
        fprintf('  [!] %s : 다이어그램 %d 장 중 문제 %d 개\n', ...
                name, numel(lg), numel(msg));
        for i = 1:numel(msg)
            fprintf('        - %s\n', msg(i));
        end
    end
end
end
