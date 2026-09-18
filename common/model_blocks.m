function out = model_blocks(modelName, form)
%MODEL_BLOCKS  Simulink 모델 안의 블록을 하나씩 한국어로 설명한다 (한 곳에만 적는다)
%
%   T   = MODEL_BLOCKS(모델이름)             설명 표 (cell 배열)
%   txt = MODEL_BLOCKS(모델이름, 'note')     Simulink 주석용 여러 줄 글자
%   txt = MODEL_BLOCKS(모델이름, 'table')    강의노트·스크립트용 마크다운 표
%   MODEL_BLOCKS(모델이름, 'print')          명령창에 표로 찍는다
%
%   왜 이 파일이 있는가
%     같은 설명을 (1) .slx 안의 주석, (2) 실행 스크립트, (3) 강의노트
%     세 군데에 따로 적으면 언젠가 반드시 어긋납니다.
%     그래서 **여기 한 곳에만 적고** 세 군데가 이것을 불러다 씁니다.
%
%   표의 세 칸
%     1) 블록 이름   — 모델에서 보이는 그 이름
%     2) 기능         — 이 블록이 계산하는 것
%     3) 모델에서의 역할 — 이 모델에서 맡은 자리. **수업에서 그대로 읽어도 되게** 씁니다
%
%   예제
%     model_blocks('W02_MSD_ThreeWays', 'print')
%     txt = model_blocks('W13_PolePlacement', 'note');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 2 || isempty(form), form = 'cell'; end

switch modelName

case 'W01_OpenClosed'
T = {
'목표값 r',        'Step. 시각 0 에서 1 로 뛰는 신호',        '우리가 시스템에 시키는 것. 지령이다'
'Kff',            'Gain. 상수를 곱한다',                    '개루프가 목표에 맞게 미리 계산해 둔 보정값 1/G(0)'
'외란 합산 개루프',  'Sum. 두 신호를 더한다',                  '플랜트에 들어가기 직전에 외란을 섞는 자리'
'플랜트 개루프',    'Transfer Fcn. 분자·분모 계수로 동작한다',  '질량-스프링-댐퍼. 우리가 못 바꾸는 대상'
'Kr',             'Gain',                                 '폐루프 쪽 지령 보정. 두 방식을 같은 조건으로 견주려고'
'오차 계산',       'Sum. + 와 - 로 뺄셈을 한다',             '목표에서 출력을 뺀다. 이 뺄셈이 곧 피드백이다'
'비례이득 K',      'Gain',                                 '오차를 얼마나 세게 밀 것인가. 오늘의 유일한 손잡이'
'외란 합산 폐루프',  'Sum',                                  '개루프와 **똑같은 자리**에 같은 외란을 넣는다'
'플랜트 폐루프',    'Transfer Fcn',                          '위쪽과 완전히 같은 플랜트. 다른 것은 연결뿐이다'
'외란 d',         'Step. 지정한 시각에 뛴다',                '중간에 밀어 보는 방해. 두 구조의 차이가 여기서 드러난다'
'Mux',            'Signal Routing. 신호를 한 다발로 묶는다',  '계산은 안 한다. Scope 한 화면에 여러 개를 넣으려고'
'To Workspace',   '신호를 MATLAB 작업공간으로 내보낸다',       '스크립트에서 그림을 그리려면 값이 필요하다'
'Scope',          '신호를 그래프로 보여 준다',                '실행하면 자동으로 열린다'
};

case 'W02_MSD_ThreeWays'
T = {
'입력 힘 F',           'Step',                                  '세 경로에 **똑같은 힘**을 동시에 넣는다'
'힘의 합',             'Sum. 부호가 + - - 이다',                 'ma = F - kx - b·dx/dt 의 오른쪽을 그대로 만든다'
'나누기 m',            'Gain. 1/m 을 곱한다',                    '힘을 질량으로 나누면 가속도. F=ma 를 옮긴 것'
'적분1 가속도에서 속도',  'Integrator. 시간에 대해 적분한다',        '가속도를 적분하면 속도. 기호가 1/s 다'
'적분2 속도에서 위치',    'Integrator',                            '속도를 적분하면 위치. 2계라서 적분기가 둘이다'
'댐퍼 b',             'Gain',                                  '속도에 비례하는 힘. 속도를 앞으로 되먹여 만든다'
'스프링 k',           'Gain',                                  '위치에 비례하는 힘. 위치를 앞으로 되먹여 만든다'
'전달함수 블록',        'Transfer Fcn. 분자·분모 계수를 받는다',    '경로 B. 5절에서 구한 G(s)=1/(ms²+bs+k) 그 자체'
'상태공간 블록',        'State-Space. 행렬 A,B,C,D 를 받는다',     '경로 C. 12-2절에서 만든 네 행렬 그 자체'
'Mux',                'Signal Routing',                        '세 경로를 한 화면에 겹쳐 보려고'
'To Workspace',       '작업공간으로 내보낸다',                    'y_A, y_B, y_C 로 각 경로의 답을 따로 받는다'
'Scope 세 경로 비교',   '그래프',                                 '겹치는지 눈으로 확인하는 자리'
};

case 'W03_Pendulum_NonlinVsLin'
T = {
'입력 토크',              'Constant. 일정한 값을 낸다',        '오늘은 0 으로 두고 **초기 각도만으로** 움직인다'
'토크 합산 비선형',        'Sum',                              '중력토크와 감쇠토크를 모아 회전 방정식을 만든다'
'관성으로 나누기 비선형',   'Gain. 1/J 를 곱한다',              '토크를 관성으로 나누면 각가속도'
'적분 (비선형) 두 개',     'Integrator',                       '각가속도 → 각속도 → 각도. 여기도 2계라 둘이다'
'감쇠 b 비선형',          'Gain',                             '각속도에 비례해 막는 힘'
'sin 여기가 비선형',       'Trigonometric Function. sin 을 계산',  '**이 블록 하나가 비선형의 정체다**'
'중력토크 비선형',         'Gain. m·g·l 을 곱한다',            'sin 을 지난 값에 곱해 중력 토크를 만든다'
'아래쪽 선형 경로',        '위와 블록 구성이 **완전히 같다**',    '딱 하나, sin 블록이 없다'
'Mux',                   'Signal Routing',                   '두 각도를 한 화면에'
'Scope 두 모델 비교',      '그래프',                            '작은 각에서는 겹치고 큰 각에서는 갈라진다'
};

case 'W04_SecondOrder_Sweep'
T = {
'목표값 r',            'Step',                        '계단 지령'
'오차 계산',            'Sum (+ -)',                   '목표에서 출력을 뺀다'
'wn 제곱',             'Gain. ωn² 을 곱한다',          '오차를 얼마나 세게 밀 것인가'
'가속도 합산',          'Sum (+ -)',                   '미는 힘에서 감쇠를 뺀다'
'적분1 속도',           'Integrator',                  '가속도를 적분하면 속도'
'적분2 위치',           'Integrator',                  '속도를 적분하면 출력'
'감쇠 2 zeta wn',      'Gain. 2ζωn 을 곱한다',         '**ζ 가 들어가는 유일한 자리.** 속도를 되먹인다'
'To Workspace',        '작업공간으로',                  '스크립트가 ζ 를 바꿔 가며 결과를 모은다'
'Scope 계단응답',       '그래프',                        'ζ 를 바꿀 때 모양이 어떻게 변하는지'
};

case 'W05_SteadyStateError'
T = {
'목표 각속도 r',   'Step',                              '지령'
'오차 e',         'Sum (+ -)',                         '목표에서 실제 속도를 뺀다'
'비례이득 Kp',     'Gain',                              '**지금** 의 오차에 비례해 민다'
'적분기',         'Integrator',                         '오차를 시간에 대해 쌓아 둔다'
'적분이득 Ki',     'Gain',                              '쌓아 둔 값을 얼마나 쓸 것인가. **0 으로 두면 P 제어**가 된다'
'제어입력 u',      'Sum (+ +)',                         '비례 몫과 적분 몫을 더한다'
'DC 모터 속도 모델', 'Transfer Fcn',                      '1절에서 두 식을 연립해 얻은 그 전달함수'
'To Workspace',   '작업공간으로',                        'y_sim(속도)과 e_sim(오차)을 따로 받는다'
'Scope 두 개',     '그래프',                             '출력과 오차를 각각 본다. 오차가 0 으로 가는지가 관심사'
};

case 'W06_Rlocus_Verify'
T = {
'목표 각도 r',       'Step',                                    '지령'
'오차',             'Sum (+ -)',                               '목표에서 각도를 뺀다'
'비례이득 K',        'Gain',                                    '근궤적에서 고른 그 K 를 여기 넣는다'
'구동기 포화',       'Saturation. 위아래 한계를 넘으면 잘라 낸다',   '**근궤적이 모르는 것.** 모터 드라이버의 전압 한계'
'DC 모터 위치 모델',  'Transfer Fcn',                             '5주차에서 만든 3차 모델'
'To Workspace',     '작업공간으로',                              'y_sim(각도)과 u_sim(전압)을 따로 받는다'
'Scope 두 개',       '그래프',                                   '**제어입력 쪽을 반드시 보십시오.** 잘렸는지가 여기 보인다'
};

case 'W07_Design_Verify'
T = {
'목표값 r',        'Step. 0 에서 1 로 한 번 뛴다',                 '지령. **위아래 두 루프에 똑같은 것**이 들어간다'
'오차 이상 / 실제', 'Sum (+ -)',                                   '목표에서 출력을 뺀다. 두 루프가 같은 구조다'
'K 이상 / 실제',    'Gain. K_des 를 곱한다',                        'W07_04 에서 설계한 그 이득. 위아래 값이 같다'
'구동기 한계',      'Saturation. u_lim 을 넘으면 잘라 낸다',         '**아래쪽에만 있다.** 두 루프의 유일한 차이가 이것이다'
'플랜트 이상 / 실제','Transfer Fcn. numG2 / denG2',                  'G(s) = 1 / (s(s+2)(s+5)). 위아래 완전히 같다'
'Mux 출력',        'Signal Routing. 세 신호를 한 줄로 묶는다',       '이상 출력 · 실제 출력 · 지령을 한 화면에 겹쳐 본다'
'Mux 입력',        'Signal Routing. 두 신호를 묶는다',              '이상 제어입력과 잘린 제어입력을 나란히 본다'
'Scope 출력',      '그래프',                                       '**두 곡선이 겹치면 설계가 맞은 것**이다'
'Scope 제어입력',   '그래프',                                       '한계선 ±u_lim 에 닿는지 여기서 확인한다'
'To Workspace 4개', '작업공간으로',                                 'y_ideal, y_real, u_ideal, u_real 을 스크립트에서 다시 그린다'
};

case 'W07_PD_Noise'
T = {
'목표 각도 r',      'Step',                                       '지령. 위아래 두 루프에 같은 것이 들어간다'
'측정 잡음',        'Band-Limited White Noise. 정해진 세기의 무작위 신호', '실제 센서에 늘 있는 잡음. 아주 작게 준다'
'오차 PD / Lead',   'Sum (+ -)',                                  '목표에서 **잡음이 섞인 측정값**을 뺀다'
'Kp',              'Gain',                                       'PD 의 비례 몫'
'미분 du dt',       'Derivative. 신호를 시간으로 미분한다',           '**이 블록이 오늘의 범인이다.** 잡음을 그대로 증폭한다'
'Kd',              'Gain',                                       'PD 의 미분 몫'
'Lead 보상기',      'Transfer Fcn. (s+z)/(s+p) 꼴',                'PD 와 목적은 같은데 분모가 있어 고주파가 막힌다'
'플랜트 PD / Lead', 'Transfer Fcn',                                '**두 루프의 플랜트는 완전히 같다.** 제어기만 다르다'
'측정 PD / Lead',   'Sum (+ +)',                                   '출력에 잡음을 더해 "센서가 준 값" 을 만든다'
'Mux 두 개',        'Signal Routing',                              '각도끼리, 제어입력끼리 묶어 나란히 본다'
'Scope 제어입력',    '그래프',                                      '**여기가 오늘의 그림이다.** 세로 눈금을 꼭 보십시오'
};

case 'W09_SineSweep'
T = {
'사인 입력',      'Sine Wave. 정해진 주파수의 사인파를 낸다',  '**주파수를 하나씩 바꿔 가며** 넣어 볼 신호'
'플랜트 G(s)',    'Transfer Fcn',                            '재려는 대상. 되먹임이 없다는 점을 보십시오'
'To Workspace',  '작업공간으로',                              '입력과 출력을 둘 다 받아야 크기비와 위상차를 잰다'
'Mux / Scope',   '묶어서 그래프로',                            '입력과 출력을 겹쳐 보면 지연이 눈에 보인다'
};

case 'W10_Margin_Check'
T = {
'목표값 r',      'Step',                                        '지령'
'오차',          'Sum (+ -)',                                   '**이 근처를 잘라서** 개루프를 뽑는다'
'비례이득 K',     'Gain',                                        '여유를 바꿔 보는 손잡이'
'시간지연',       'Transport Delay. 신호를 정해진 시간만큼 늦춘다',  '통신·계산 지연을 흉내 낸다. **위상만 깎는다**'
'플랜트 G(s)',    'Transfer Fcn',                                 '대상'
'To Workspace',  '작업공간으로',                                  '응답을 받아 그림을 그린다'
'Scope 두 개',    '그래프',                                       '지연을 키우면 언제 발산하는지 본다'
};

case 'W11_PID_AntiWindup'
T = {
'목표 속도 r',    'Step',                                          '지령. 크게 주면 포화가 걸린다'
'오차 계산',      'Sum (+ -)',                                      '목표에서 속도를 뺀다'
'PID',           'PID Controller. P·I·D 를 한 블록에 담고 있다',      '더블클릭하면 **Tune 버튼**과 anti-windup 설정이 있다'
'DC 모터',        'Transfer Fcn',                                   '속도 모델'
'To Workspace',  '작업공간으로',                                     'y_sim(속도)과 u_sim(전압)'
'Scope 두 개',    '그래프',                                          '전압이 한계에 **붙어 있는 시간**이 와인드업이 자라는 구간'
};

case 'W12_StateSpace_Modes'
T = {
'입력 u',        'Step',                                       '오늘은 크기를 0 으로 둔다. **초기조건만으로** 움직인다'
'상태공간 모델',   'State-Space. 행렬 A,B,C,D 와 **초기조건**을 받는다', '더블클릭해 Initial conditions 칸을 보십시오. 전달함수에는 없다'
'To Workspace',  '작업공간으로',                                 'C 를 단위행렬로 두어 **상태를 전부** 꺼낸다'
'Scope 상태',     '그래프',                                      '고유벡터 방향에서 출발하면 지수함수 하나가 된다'
};

case 'W13_PolePlacement'
T = {
'지령 r',        'Step',                                          '목표 각도'
'Kr',           'Gain',                                           '극배치는 극점만 옮긴다. 직류이득은 이 상수가 맞춘다'
'합산',          'Sum (+ -)',                                      '지령에서 상태궤환 몫을 뺀다'
'구동기 포화',    'Saturation',                                     '켜고 끄며 실물의 한계를 흉내 낸다'
'플랜트',        'State-Space. C 를 단위행렬로 두었다',               '**상태를 전부 꺼내야** 상태궤환을 쓸 수 있다'
'상태궤환 K',     'Gain. 스칼라가 아니라 **행벡터**다',               'Multiplication 을 Matrix(K*u) 로 두어야 한다'
'To Workspace',  '작업공간으로',                                    'x_sim(상태 전부)과 u_sim(제어입력)'
'Scope',        '그래프',                                          '상태가 어떻게 움직이는지'
};

case 'W14_ObserverBased'
T = {
'입력 u',       'Step',                                            '두 갈래에 **같은 입력**이 들어간다'
'실제 플랜트',   'State-Space. 초기조건 x0 가 있다',                   '위쪽 갈래. 진짜 시스템'
'분배',         'Demux. 한 다발을 여러 신호로 **푼다**',               'Mux 의 반대. 출력 y 와 상태 전부를 갈라 낸다'
'센서 잡음',     'Band-Limited White Noise',                        '측정에 섞이는 잡음. 관측기를 빠르게 하면 이것이 커진다'
'잡음 더하기',   'Sum (+ +)',                                        '참값에 잡음을 더해 "센서가 준 값" 을 만든다'
'u 와 y',       'Mux',                                              '관측기가 받는 것은 **이 둘뿐**이다'
'관측기',        'State-Space. A-LC 와 [B L] 을 넣었다',              '아래쪽 갈래. 초기조건이 0 이라 아무것도 모르고 시작한다'
'To Workspace', '작업공간으로',                                       'x_real 과 x_hat 을 따로 받아 겹쳐 그린다'
'Scope 비교',    '그래프',                                            '실제와 추정이 만나는 순간을 본다'
};

otherwise
    error('model_blocks:unknown', '설명이 등록되지 않은 모델입니다: %s', modelName);
end

switch lower(form)
    case 'cell'
        out = T;
    case 'note'
        % Simulink 주석용.
        %
        % [주의 1] 주석 이름에 **보통 슬래시 `/` 를 쓰면 안 됩니다.**
        %          Simulink 가 블록 경로 구분자로 읽어서
        %          "이름이 ...인 새 주석은 추가할 수 없음" 오류가 납니다.
        %          그런데 설명에는 1/m, 1/s, (s+z)/(s+p) 처럼 슬래시가 꼭 필요합니다.
        %          그래서 **나눗셈 기호 U+2215 로 바꿔 넣습니다.** 화면에는 똑같이 보입니다.
        %
        % [주의 2] 주석은 마크다운을 렌더링하지 않습니다.
        %          굵게 표시 ** 를 그대로 두면 별표가 글자로 보이므로 지웁니다.
        lines = cell(size(T,1)+2, 1);
        lines{1} = '이 모델의 블록을 하나씩 읽으면 이렇습니다.';
        lines{2} = '';
        for i = 1:size(T,1)
            lines{i+2} = sprintf('  %s  —  %s  →  %s', T{i,1}, T{i,2}, T{i,3});
        end
        out = strjoin(lines, newline);
        out = strrep(out, '**', '');
        out = strrep(out, '/', char(8725));   % U+2215 DIVISION SLASH
    case 'table'
        lines = { '% | 블록 | 기능 | 모델에서의 역할 |', '% |---|---|---|' };
        for i = 1:size(T,1)
            lines{end+1} = sprintf('%% | `%s` | %s | %s |', T{i,1}, T{i,2}, T{i,3}); %#ok<AGROW>
        end
        out = strjoin(lines, newline);
    case 'print'
        % 명령창에는 굵게가 없으므로 ** 를 지웁니다.
        % 그리고 한글은 화면에서 두 칸을 차지하므로 %-22s 로는 줄이 안 맞습니다.
        % local_pad 가 **글자 수가 아니라 화면 폭**으로 채웁니다.
        w1 = 24; w2 = 46;
        fprintf('\n  %s  %s  %s\n', local_pad('블록',w1), ...
                local_pad('기능',w2), '모델에서의 역할');
        fprintf('  %s  %s  %s\n', repmat('-',1,w1), repmat('-',1,w2), repmat('-',1,30));
        for i = 1:size(T,1)
            c = strrep(T(i,:), '**', '');
            fprintf('  %s  %s  %s\n', local_pad(c{1},w1), local_pad(c{2},w2), c{3});
        end
        fprintf('\n');
        out = T;
    otherwise
        error('model_blocks:form', 'form 은 cell / note / table / print 중 하나여야 합니다.');
end
end


function s = local_pad(s, w)
%LOCAL_PAD  화면 폭 w 가 되도록 오른쪽을 빈칸으로 채운다
%
%  한글·한자·전각기호는 명령창에서 **두 칸**을 차지합니다.
%  그래서 numel(s) 로 세면 표가 어긋납니다. 여기서는 각 글자가
%  두 칸짜리인지 보고 실제 화면 폭을 계산합니다.
c = double(s);
wide = (c >= 4352 & c <= 4607) | (c >= 8986 & c <= 8987) | ...
       (c >= 11904 & c <= 42191) | (c >= 44032 & c <= 55203) | ...
       (c >= 63744 & c <= 64255) | (c >= 65281 & c <= 65376);
disp_w = numel(c) + sum(wide);
if disp_w < w
    s = [s repmat(' ', 1, w - disp_w)];
end
end
