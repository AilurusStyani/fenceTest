function calculateFrustum(deltaDegree)
global TRIALINFO;
global FRUSTUM;
global SCREEN;

FRUSTUM.clipNear = SCREEN.distance*2/3; % m
FRUSTUM.clipFar = 3; % m
FRUSTUM.top = (FRUSTUM.clipNear / SCREEN.distance) * (SCREEN.heightM / 2.0);
FRUSTUM.bottom = (FRUSTUM.clipNear / SCREEN.distance) * (-SCREEN.heightM / 2.0);

if nargin ==1
    % left eye
    FRUSTUM.sinisterRight = (FRUSTUM.clipNear / SCREEN.distance) * (SCREEN.widthM / 2.0 + TRIALINFO.deviation / 2.0);
    FRUSTUM.sinisterLeft = (FRUSTUM.clipNear / SCREEN.distance) * (-SCREEN.widthM / 2.0 + TRIALINFO.deviation / 2.0);
    
    % right eye
    FRUSTUM.dexterRight = (FRUSTUM.clipNear / SCREEN.distance) * (SCREEN.widthM / 2.0 - TRIALINFO.deviation / 2.0);
    FRUSTUM.dexterLeft = (FRUSTUM.clipNear / SCREEN.distance) * (-SCREEN.widthM / 2.0 - TRIALINFO.deviation / 2.0);
    
    FRUSTUM.checkRight = (FRUSTUM.clipFar / SCREEN.distance) * (SCREEN.widthM / 2.0 + TRIALINFO.deviation / 2.0);
    FRUSTUM.checkLeft = (FRUSTUM.clipFar / SCREEN.distance) * (-SCREEN.widthM / 2.0 - TRIALINFO.deviation / 2.0);
elseif nargin == 2
    delta = FRUSTUM.clipNear * sind(deltaDegree);
    % left eye
    FRUSTUM.sinisterRight = (FRUSTUM.clipNear / SCREEN.distance) * (SCREEN.widthM / 2.0 + TRIALINFO.deviation / 2.0)+delta;
    FRUSTUM.sinisterLeft = (FRUSTUM.clipNear / SCREEN.distance) * (-SCREEN.widthM / 2.0 + TRIALINFO.deviation / 2.0)+delta;
    
    % right eye
    FRUSTUM.dexterRight = (FRUSTUM.clipNear / SCREEN.distance) * (SCREEN.widthM / 2.0 - TRIALINFO.deviation / 2.0)+delta;
    FRUSTUM.dexterLeft = (FRUSTUM.clipNear / SCREEN.distance) * (-SCREEN.widthM / 2.0 - TRIALINFO.deviation / 2.0)+delta;
    
    FRUSTUM.checkRight = (FRUSTUM.clipFar / SCREEN.distance) * (SCREEN.widthM / 2.0 + TRIALINFO.deviation / 2.0)+FRUSTUM.clipFar * sind(deltaDegree);
    FRUSTUM.checkLeft = (FRUSTUM.clipFar / SCREEN.distance) * (-SCREEN.widthM / 2.0 - TRIALINFO.deviation / 2.0)+FRUSTUM.clipFar * sind(deltaDegree);
end