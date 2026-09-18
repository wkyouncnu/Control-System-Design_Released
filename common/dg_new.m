function ax = dg_new(W, H, ttl)
%DG_NEW  블록선도를 그릴 빈 도화지를 준비한다
%
%   ax = dg_new(W, H)
%   ax = dg_new(W, H, '제목')
%
%   왜 필요한가
%     제어를 배울 때 가장 헷갈리는 것은 "신호가 어디서 어디로 가는가" 입니다.
%     식만 보면 알기 어렵습니다. 그림으로 보면 바로 보입니다.
%     이 함수와 dg_block, dg_sum, dg_arrow 로 블록선도를 코드로 그립니다.
%
%   입력
%     W   - 도화지 가로 크기 (기본 10)
%     H   - 도화지 세로 크기 (기본 4)
%     ttl - 그림 제목 (생략 가능)
%
%   출력
%     ax  - 준비된 axes 핸들
%
%   좌표 약속
%     왼쪽 아래가 (0,0), 오른쪽 위가 (W,H) 입니다.
%     블록의 위치는 항상 **블록 한가운데**의 좌표로 지정합니다.
%
%   예제
%     dg_new(10, 3);
%     dg_block(5, 1.5, 2, 1, 'G(s)');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(W), W = 10; end
if nargin < 2 || isempty(H), H = 4;  end

% 자동 검사를 위한 기록장을 새로 연다.
% dg_block / dg_sum / dg_arrow 가 여기에 자기 좌표를 적어 두고,
% dg_check 가 나중에 읽어서 끊긴 선이나 겹친 블록을 찾는다.
% 앞서 그린 그림은 버리지 않고 보관함(DG_LOG)에 옮겨 둔다.
% 그래야 dg_check_all 이 한 파일 안의 그림을 **전부** 검사할 수 있다.
prev = getappdata(0, 'DG_REG');
if ~isempty(prev) && (~isempty(prev.boxes) || ~isempty(prev.arrows))
    lg = getappdata(0, 'DG_LOG');
    if isempty(lg), lg = {}; end
    lg{end+1} = prev;
    setappdata(0, 'DG_LOG', lg);
end
setappdata(0, 'DG_REG', struct('W', W, 'H', H, 'boxes', {{}}, 'arrows', {{}}));

% 반드시 **새 도화지**를 만든다.
% 바로 앞에서 rlocus 를 그렸다면 현재 축이 Control System Toolbox 의
% 전용 차트라서, 거기에 cla/hold 를 걸면
% "삭제된 그래픽스 객체로 플로팅하려고 했습니다" 오류가 난다.
ax = axes(figure('Color', 'w'));
hold(ax, 'on');
axis(ax, 'equal');
xlim(ax, [0 W]);
ylim(ax, [0 H]);
axis(ax, 'off');
set(ax, 'Color', 'w');

if nargin >= 3 && ~isempty(ttl)
    title(ax, ttl, 'FontSize', 12, 'FontWeight', 'bold');
end
end
