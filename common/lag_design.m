function [D, info] = lag_design(K, G, PM_req, extra)
%LAG_DESIGN  주파수영역 Lag 보상기 설계 (강의자료 8강의 절차를 그대로 코드로)
%
%   [D, info] = LAG_DESIGN(K, G, PM_req)
%   [D, info] = LAG_DESIGN(K, G, PM_req, extra)
%
%   Lag 보상기가 하는 일
%     Lead 와 목적이 다릅니다. Lag 는 위상을 올리지 않습니다.
%     **저주파 이득은 그대로 두고 고주파 크기를 낮춰서**
%     교차주파수를 왼쪽(느린 쪽)으로 옮깁니다.
%     플랜트 위상은 대개 저주파에서 덜 떨어져 있으므로,
%     교차주파수가 왼쪽으로 가면 **위상여유가 저절로 늘어납니다.**
%
%   $$D(s) = K\,\frac{T s + 1}{\beta T s + 1}, \qquad \beta > 1$$
%
%   설계 절차 (강의자료 8강 slide 71~72)
%     1단계  정상상태 사양으로 K 를 정한다               <- 이 함수의 입력
%     2단계  K*G 의 위상이 -180 + PM_req + extra 가 되는 주파수를 찾는다
%            그 자리를 **새 교차주파수** wc_new 로 삼는다
%     3단계  그 주파수에서 |K*G| 가 A dB 라면 그만큼 낮춰야 하므로
%            beta = 10^(A/20)
%     4단계  영점을 새 교차주파수보다 한 옥타브~한 데케이드 아래에 둔다
%            T = 10 / wc_new
%     5단계  D(s) 를 적용하고 위상여유를 다시 확인한다
%
%   왜 영점을 한참 아래에 두는가
%     Lag 도 위상을 **깎습니다**(최대 -90도). 그 깎이는 구간이 새 교차주파수와
%     겹치면 애써 번 위상여유를 도로 까먹습니다.
%     그래서 영점 1/T 를 wc_new 보다 한 데케이드 아래에 두어,
%     교차주파수 근처에서는 위상 깎임이 거의 끝나 있게 만듭니다.
%
%   Lead 와 Lag 를 언제 쓰는가
%     - 응답을 **빠르게** 하고 싶다  ->  Lead (대역폭이 넓어진다. 잡음에 약해진다)
%     - 정상상태 오차를 줄이면서 **안정하게** 하고 싶다  ->  Lag (느려진다. 잡음에 강하다)
%
%   입력
%     K      - 1단계에서 정한 이득
%     G      - 플랜트
%     PM_req - 요구 위상여유 [도]
%     extra  - 여유분 [도]. 기본 8. Lag 자신이 깎는 위상을 보상합니다.
%
%   출력
%     D    - 설계된 Lag 보상기 (이득 K 포함)
%     info - .PM_before .PM_after .beta .T .wc_new .attn_dB .zero .pole .ok
%
%   예제
%     s = tf('s');  G = 100/((s+1)*(0.2*s+1));
%     [D, info] = lag_design(1, G, 40);
%     margin(D*G)
%
%   See also LEAD_DESIGN, FREQ_SCAN, MARGIN
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 4 || isempty(extra), extra = 8; end

s = tf('s');

%% 2단계 : 새 교차주파수 찾기
[~, PM_before] = margin(K*G);
if ~isfinite(PM_before), PM_before = 0; end

w  = logspace(-4, 4, 6000);
fr = squeeze(freqresp(K*G, w));
ph = unwrap(angle(fr))*180/pi;
mg = 20*log10(abs(fr));

target_ph = -180 + PM_req + extra;

idx = find(ph >= target_ph, 1, 'last');
if isempty(idx) || idx >= numel(w)
    error('lag_design:주파수없음', ...
        ['위상이 %.1f 도가 되는 주파수를 찾지 못했습니다. ' ...
         'PM_req 가 이 플랜트로는 불가능한 값일 수 있습니다.'], target_ph);
end
w1 = w(idx);  w2 = w(idx+1);
p1 = ph(idx); p2 = ph(idx+1);
wc_new = exp(log(w1) + (target_ph - p1)*(log(w2)-log(w1))/(p2 - p1));

%% 3단계 : 그 자리의 크기만큼 낮춘다
attn_dB = interp1(log(w), mg, log(wc_new));    % 양수면 그만큼 내려야 한다
if attn_dB <= 0
    D = tf(K);
    info = struct('PM_before',PM_before, 'PM_after',PM_before, 'beta',1, ...
                  'T',0, 'wc_new',wc_new, 'attn_dB',attn_dB, ...
                  'zero',NaN, 'pole',NaN, 'ok',true, ...
                  'note','이미 그 주파수에서 크기가 0 dB 아래입니다. Lag 가 필요 없습니다.');
    return
end
beta = 10^(attn_dB/20);

%% 4단계 : 영점을 한 데케이드 아래에
T = 10 / wc_new;

%% 보상기
D = K * (T*s + 1) / (beta*T*s + 1);

%% 5단계 : 검증
[~, PM_after] = margin(D*G);

info = struct( ...
    'PM_before', PM_before, ...
    'PM_after',  PM_after,  ...
    'beta',      beta,      ...
    'T',         T,         ...
    'wc_new',    wc_new,    ...
    'attn_dB',   attn_dB,   ...
    'zero',      -1/T,      ...
    'pole',      -1/(beta*T), ...
    'ok',        PM_after >= PM_req, ...
    'note',      '');

if ~info.ok
    info.note = sprintf(['설계 후 위상여유가 %.1f 도로 요구(%.1f 도)에 못 미칩니다. ' ...
        'extra 를 늘려 보십시오.'], PM_after, PM_req);
end
end
