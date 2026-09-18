function [D, info] = lead_design(K, G, PM_req, extra)
%LEAD_DESIGN  주파수영역 Lead 보상기 설계 (강의자료 8강의 5단계를 그대로 코드로)
%
%   [D, info] = LEAD_DESIGN(K, G, PM_req)
%   [D, info] = LEAD_DESIGN(K, G, PM_req, extra)
%
%   Lead 보상기가 하는 일
%     **위상을 끌어올려 위상여유를 벌어 준다.** 시간영역으로 옮기면
%     오버슈트가 줄고 응답이 빨라집니다. 근궤적에서 배운 PD 와 같은 물건인데,
%     고주파 이득이 무한히 커지지 않도록 극점을 하나 붙여 놓은 것입니다.
%
%   $$D(s) = K\,\frac{T s + 1}{\alpha T s + 1}, \qquad 0 < \alpha < 1$$
%
%   설계 5단계 (강의자료 8강 slide 37~39)
%     1단계  정상상태 사양으로 K 를 먼저 정한다        <- 이 함수의 입력
%     2단계  K*G 의 현재 위상여유를 잰다
%     3단계  모자란 각을 구한다.  phi = PM_req - PM_now + extra
%     4단계  alpha = (1 - sin phi) / (1 + sin phi)
%     5단계  |K*G| 가 10*log10(alpha) dB 인 주파수를 wm 으로 잡고
%            T = 1 / (wm * sqrt(alpha))
%
%   왜 5단계에서 그 주파수를 고르는가
%     Lead 는 wm = 1/(T*sqrt(alpha)) 에서 위상을 가장 많이(phi 만큼) 올리고,
%     바로 그 자리에서 크기를 1/sqrt(alpha) 배 (= -10*log10(alpha) dB) 올립니다.
%     그러니 보상 후 그 주파수가 새 교차주파수(0 dB)가 되게 하려면
%     보상 전 크기가 그만큼 **아래**에 있어야 합니다. 그것이 10*log10(alpha) dB 입니다.
%
%   입력
%     K      - 1단계에서 정한 이득 (정상상태 오차 사양이 정한다)
%     G      - 플랜트 (센서까지 포함한 개루프 대상)
%     PM_req - 요구 위상여유 [도]
%     extra  - 여유분 [도]. 기본 5. 3단계에서 더한다.
%              Lead 가 교차주파수를 오른쪽으로 밀면 플랜트 위상이 더 떨어지므로
%              조금 더 벌어 두는 것이 관례입니다.
%
%   출력
%     D    - 설계된 Lead 보상기 (이득 K 를 포함한 전달함수)
%     info - 중간 계산값 구조체
%            .PM_before .PM_after .alpha .T .wm .phi .zero .pole .ok
%
%   주의
%     한 단으로 올릴 수 있는 위상은 실용적으로 **60도 정도까지**입니다.
%     (alpha 가 0.07 보다 작아지면 고주파 이득이 너무 커집니다.)
%     그보다 더 필요하면 Lead 를 두 단으로 나누십시오. 8강 Example 7-3 이 그 예입니다.
%
%   예제
%     s = tf('s');  G = 1/(s*(s+1));
%     [D, info] = lead_design(100, G, 50);
%     margin(D*G)
%
%   See also LAG_DESIGN, FREQ_SCAN, MARGIN
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 4 || isempty(extra), extra = 5; end

s = tf('s');

%% 2단계 : 현재 위상여유
[~, PM_before] = margin(K*G);
if ~isfinite(PM_before), PM_before = 0; end

%% 3단계 : 모자란 각
phi = PM_req - PM_before + extra;
if phi <= 0
    % 이미 만족한다면 보상기가 필요 없다. 그대로 돌려준다.
    D = tf(K);
    info = struct('PM_before', PM_before, 'PM_after', PM_before, ...
                  'alpha', 1, 'T', 0, 'wm', NaN, 'phi', phi, ...
                  'zero', NaN, 'pole', NaN, 'ok', true, ...
                  'note', '이미 위상여유를 만족합니다. Lead 가 필요 없습니다.');
    return
end
if phi >= 75
    warning('lead_design:phi큼', ...
        ['한 단으로 %.1f 도를 올리려 합니다. alpha 가 너무 작아져 고주파 이득이 ' ...
         '과도해집니다. Lead 를 두 단으로 나누는 것을 권합니다.'], phi);
end

%% 4단계 : alpha
alpha = (1 - sind(phi)) / (1 + sind(phi));

%% 5단계 : wm 찾기 — |K G| 가 10*log10(alpha) dB 인 주파수
target_dB = 10*log10(alpha);            % 음수다
w  = logspace(-3, 4, 4000);
m  = 20*log10(squeeze(abs(freqresp(K*G, w))));

idx = find(m >= target_dB, 1, 'last');  % 크기가 내려오면서 목표를 지나는 마지막 점
if isempty(idx) || idx >= numel(w)
    error('lead_design:wm없음', ...
        ['크기 곡선이 %.2f dB 를 지나지 않습니다. K 를 다시 확인하십시오.'], target_dB);
end
% 두 점 사이를 로그축에서 선형보간
w1 = w(idx);   w2 = w(idx+1);
m1 = m(idx);   m2 = m(idx+1);
wm = exp(log(w1) + (target_dB - m1)*(log(w2)-log(w1))/(m2 - m1));

T = 1 / (wm * sqrt(alpha));

%% 보상기
D = K * (T*s + 1) / (alpha*T*s + 1);

%% 검증
[~, PM_after] = margin(D*G);

info = struct( ...
    'PM_before', PM_before, ...
    'PM_after',  PM_after,  ...
    'alpha',     alpha,     ...
    'T',         T,         ...
    'wm',        wm,        ...
    'phi',       phi,       ...
    'zero',      -1/T,      ...
    'pole',      -1/(alpha*T), ...
    'ok',        PM_after >= PM_req, ...
    'note',      '');

if ~info.ok
    info.note = sprintf(['설계 후 위상여유가 %.1f 도로 요구(%.1f 도)에 못 미칩니다. ' ...
        'extra 를 늘리거나 Lead 를 두 단으로 나누십시오.'], PM_after, PM_req);
end
end
