% environment: Matlab R2017a+, Psychtoolbox 3, Eyelink
clear global STARDATA
global TRIALINFO;
global SCREEN;
global GL;
global FRUSTUM;
global STARDATA;

subjectName = inputdlg({'Please input participant''s initials.'},'Subject Name',1,{''},'on');
if isempty(subjectName)
    return
end
fileName = ['FenceTest_' subjectName{1} '_' datestr(now,'yymmddHHMM')];
saveDir = fullfile(pwd,'data');
mkdir(saveDir);
curdir = pwd;

%% PARAMETERS
% for SCREEN
SCREEN.distance = 60;% cm

TRIALINFO.deviation = 6.3; % initial binocular deviation, cm
deviationAdjust     = 0.2; % how fast to adjust the deviation by key pressing, cm

TRIALINFO.fenceWidth = 1;  % cm
TRIALINFO.fenceInterval = 6; % cm
fenceModifySpeed = 1;

% for movement
initialPosition = [0 0 0];
velocity = [0 0 0];
TRIALINFO.acceleration   = [1 0 0];

initialBallPosition = [0 0 -200];
ballVelocity = [0 0 0];
ballSize = 10; % cm
starSize = 0.8; % cm
TRIALINFO.ballAcceleration = [1 1 0];

TRIALINFO.maxVelocity = 10;
TRIALINFO.movingBox = [-100 100];

Fence3D = false;
eyelinkMode = false; % 1/ture: eyelink will be in recording; 0/false: eyelink is not on call

% set keyboard
KbName('UnifyKeyNames');
skipKey   = KbName('space'); % change a photo
escape    = KbName('ESCAPE');
leftKey   = KbName('LeftArrow');
rightKey  = KbName('RightArrow');
upArror   = KbName('UpArrow'); % position set to 0
cKey      = KbName('c'); % force calibration, temporally not in use
enterKey = KbName('Return'); % stop all
ballUpKey = KbName('w');
ballDownKey = KbName('s');
ballRightKey = KbName('a');
ballLeftKey = KbName('d');
Fence2DKey = KbName('2@');
Fence3DKey = KbName('3#');
fenceWidthIncrease = KbName('.>');
fenceWidthDecrease = KbName(',<');
markerKey = KbName('m');
pageUp = KbName('pageup'); % increase binocular deviation
pageDown = KbName('pagedown'); % decrease binocular deviation

metrixNum = 0;
markerNum = 0;
position = initialPosition;
ballPosition = initialBallPosition;
starMetrix = StarMetrix();
metrix = starMetrix{mod(metrixNum,length(starMetrix))+1};
CalculateBall(metrix,ballPosition,ballSize,starSize);

%% Initial OpenGL
Screen('Preference', 'SkipSyncTests', 0); % for recording

AssertOpenGL;
InitializeMatlabOpenGL;

if max(Screen('Screens')) > 1
    SCREEN.screenId = max(Screen('Screens'))-1;
else
    SCREEN.screenId = max(Screen('Screens'));
end

PsychImaging('PrepareConfiguration');

% Define background color:
whiteBackground = WhiteIndex(SCREEN.screenId);
blackBackground = BlackIndex(SCREEN.screenId);

% Open a double-buffered full-screen window on the main displays screen.
[win , winRect] = PsychImaging('OpenWindow', SCREEN.screenId, blackBackground);

SCREEN.widthPix = winRect(3);
SCREEN.heightPix = winRect(4);
SCREEN.center = [SCREEN.widthPix/2, SCREEN.heightPix/2];

[width, height] = Screen('DisplaySize', SCREEN.screenId);
SCREEN.widthM = width/10; % mm to cm
SCREEN.heightM = height/10; % mm to cm

SCREEN.refreshRate = Screen('NominalFrameRate', SCREEN.screenId);

calculateFrustum();
% calculateCondition();

Screen('BeginOpenGL', win);
% Enable proper occlusion handling via depth tests:
glEnable(GL.DEPTH_TEST);
glClear;
Screen('EndOpenGL', win);

%% initial eyelink
if eyelinkMode
    tempName = 'TEMP1'; % need temp name because Eyelink only know hows to save names with 8 chars or less. Will change name using matlab's moveFile later.
    dummymode=0; % set to 1 to run in dummymode (using mouse as pseudo-eyetracker)
    
    el=EyelinkInitDefaults(win);
    %     el.backgroundcolour = BlackIndex(el.window);
    %     el.foregroundcolour = GrayIndex(el.window);
    %     el.msgfontcolour    = WhiteIndex(el.window);
    %     el.imgtitlecolour   = WhiteIndex(el.window);
    el.calibrationtargetsize=1;  % size of calibration target as percentage of screen
    el.calibrationtargetwidth=0.5; % width of calibration target's border as percentage of screen
    
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        Eyelink('ShutDown');
        Screen('CloseAll');
        return
    end
    
    testi = Eyelink('Openfile', tempName);
    if testi~=0
        fprintf('Cannot create EDF file ''%s'' ', fileName);
        cleanup;
        Eyelink('ShutDown');
        Screen('CloseAll');
        return
    end
    
    %   SET UP TRACKER CONFIGURATION
    Eyelink('command', 'calibration_type = HV9');
    %	set parser (conservative saccade thresholds)
    Eyelink('command', 'saccade_velocity_threshold = 35');
    Eyelink('command', 'saccade_acceleration_threshold = 9500');
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,HREF,GAZERES,AREA,STATUS,INPUT,HTARGET');
    Eyelink('command', 'online_dcorr_refposn = %1d, %1d', SCREEN.center(1), SCREEN.center(2));
    Eyelink('command', 'online_dcorr_maxangle = %1d', 30.0);
    % you must call this function to apply the changes from above
    EyelinkUpdateDefaults(el);
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    % do a final check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);
    
    eye_used = Eyelink('EyeAvailable');
    
    try
        switch eye_used
            case el.BINOCULAR
                disp('tracker indicates binocular')
            case el.LEFT_EYE
                error('tracker indicates left eye')
            case el.RIGHT_EYE
                error('tracker indicates right eye')
            case -1
                error('eyeavailable returned -1')
            otherwise
                eye_used
                error('unexpected result from eyeavailable')
        end
    catch
        cleanup;
        Eyelink('ShutDown');
        Screen('CloseAll');
        return
    end
    
    Eyelink('StartRecording');
    
    Eyelink('message', 'SYNCTIME');	 	 % zero-plot time for EDFVIEW
    
    errorCheck=Eyelink('checkrecording'); 		% Check recording status */
    if(errorCheck~=0)
        fprintf('Eyelink checked wrong status.\n');
        cleanup;  % cleanup function
        Eyelink('ShutDown');
        Screen('CloseAll');
    end
    
    calibrateCkeck = tic;
    pause(0.5); % wait a little bit, in case the key press during calibration influence the following keyboard check
end

keyReleased = true;
frameNum = 0;
marker = [];

cameraIndex.position = [];
cameraIndex.velocity = [];
ballIndex.position = [];
ballIndex.velocity = [];
%% main part
while true
    % keyboard function
    [keyIsDown, ~, keyCode]=KbCheck;
    if keyReleased
        if keyIsDown
            keyReleased = false;
            if keyCode(skipKey)
                metrix = starMetrix{mod(metrixNum,length(starMetrix))+1};
                metrixNum = metrixNum+1 ;
            end
            
            if keyCode(upArror)
                position = initialPosition;
                ballPosition = initialBallPosition;
            end
            if keyCode(escape)
                break
            end
            
            if keyCode(pageUp)
                TRIALINFO.deviation = TRIALINFO.deviation + deviationAdjust;
                disp(['binocular deviation: ' num2str(TRIALINFO.deviation)]);
                calculateFrustum();
            end
            if keyCode(pageDown)
                if TRIALINFO.deviation > deviationAdjust
                    TRIALINFO.deviation = TRIALINFO.deviation - deviationAdjust;
                    disp(['binocular deviation: ' num2str(TRIALINFO.deviation)]);
                    calculateFrustum();
                end
            end
            
            if keyCode(leftKey)
                velocityi  = velocity - TRIALINFO.acceleration;
                if abs(velocity)<=TRIALINFO.maxVelocity
                    velocity = velocityi;
                end
            end
            if keyCode(rightKey)
                velocityi  = velocity + TRIALINFO.acceleration;
                if abs(velocity)<=TRIALINFO.maxVelocity
                    velocity = velocityi;
                end
            end
            
            if eyelinkMode
                if keyCode(cKey)
                    EyelinkDoTrackerSetup(el);
                    % do a final check of calibration using driftcorrection
                    EyelinkDoDriftCorrection(el);
                    
                    Eyelink('StartRecording');
                    Eyelink('message', 'Force calibration finished');
                    error=Eyelink('checkrecording'); 		% Check recording status */
                    if(error~=0)
                        fprintf('Eyelink checked wrong status.\n');
                        cleanup;  % cleanup function
                        Eyelink('ShutDown');
                        Screen('CloseAll');
                    end
                    WaitSecs(0.3); % wait a bit
                end
                if keyCode(markerKey)
                    Eyelink('message', ['Marker ' num2str(markerNum)]);
                    markerNum = markerNum+1;
                    marker = cat(1,marker,[markerNum, frameNum]);
                end
            end
            
            if keyCode(enterKey)
                velocity = [0 0 0];
                ballVelocity = [0 0 0];
            end
            
            if keyCode(ballUpKey)
                ballVelocityi = ballVelocity + [0 1 0] .* TRIALINFO.ballAcceleration;
                if abs(ballVelocityi)<=TRIALINFO.maxVelocity
                    ballVelocity = ballVelocityi;
                end
            end
            if keyCode(ballDownKey)
                ballVelocityi = ballVelocity + [0 -1 0] .* TRIALINFO.ballAcceleration;
                if abs(ballVelocityi)<=TRIALINFO.maxVelocity
                    ballVelocity = ballVelocityi;
                end
            end
            if keyCode(ballRightKey)
                ballVelocityi = ballVelocity + [1 0 0] .* TRIALINFO.ballAcceleration;
                if abs(ballVelocityi)<=TRIALINFO.maxVelocity
                    ballVelocity = ballVelocityi;
                end
            end
            if keyCode(ballLeftKey)
                ballVelocityi = ballVelocity + [-1 0 0] .* TRIALINFO.ballAcceleration;
                if abs(ballVelocityi)<=TRIALINFO.maxVelocity
                    ballVelocity = ballVelocityi;
                end
            end
            
            if keyCode(Fence2DKey)
                Fence3D = false;
                disp('2D fence');
            elseif keyCode(Fence3DKey)
                Fence3D = true;
                disp('3D fence');
            end
            
            if keyCode(fenceWidthIncrease)
                TRIALINFO.fenceWidth = TRIALINFO.fenceWidth+fenceModifySpeed;  % cm
                TRIALINFO.fenceInterval = TRIALINFO.fenceInterval+fenceModifySpeed; % cm
                disp(['Fence width: ' num2str( TRIALINFO.fenceWidth)]);
                disp(['Fence interval: ' num2str( TRIALINFO.fenceInterval)]);
            end
            if keyCode(fenceWidthDecrease)
                TRIALINFO.fenceWidth = TRIALINFO.fenceWidth-fenceModifySpeed;  % cm
                TRIALINFO.fenceInterval = TRIALINFO.fenceInterval-fenceModifySpeed; % cm
                disp(['Fence width: ' num2str( TRIALINFO.fenceWidth)]);
                disp(['Fence interval: ' num2str( TRIALINFO.fenceInterval)]);
            end
        end
    end
    if ~keyIsDown
        keyReleased = true;
    end
    
    % calculate current position
    positioni = position + velocity;
    ballPositioni = ballPosition + ballVelocity;
    if min(positioni(1:2))>=min(TRIALINFO.movingBox) && max(positioni(1:2))<=max(TRIALINFO.movingBox)
        position = positioni;
    else
        velocity = -velocity;
        ballVelocity = -ballVelocity;
    end
    if min(ballPositioni(1:2))>=min(TRIALINFO.movingBox) && max(ballPositioni(1:2))<=max(TRIALINFO.movingBox)
        ballPosition = ballPositioni;
    else
        velocity = -velocity;
        ballVelocity = -ballVelocity;
    end
    
    %% start drawing
    CalculateBall(metrix,ballPosition,ballSize,starSize);
    
    Screen('BeginOpenGL',win);
    glClear(GL.DEPTH_BUFFER_BIT);
    glClear(GL.COLOR_BUFFER_BIT);
    
    % left eye
    glColorMask(GL.TRUE, GL.FALSE, GL.FALSE, GL.FALSE);
    glMatrixMode(GL.PROJECTION);
    glLoadIdentity;
    glFrustum( FRUSTUM.sinisterLeft,FRUSTUM.sinisterRight, FRUSTUM.bottom, FRUSTUM.top, FRUSTUM.clipNear, FRUSTUM.clipFar);
    glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;
    gluLookAt(position(1)-TRIALINFO.deviation,position(2),position(3),...
        position(1)-TRIALINFO.deviation,position(2),position(3)-SCREEN.distance, ...
        0,1,0)
    glClearColor(0,0,0,0);
    glColor3f(1.0,1.0,0.0);
    DrawDots3D(win,[STARDATA.x ; STARDATA.y; STARDATA.z]);
    
    glEnable(GL.BLEND);
    glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
    
    if Fence3D
        drawFence(Fence3D,TRIALINFO.fenceWidth,TRIALINFO.fenceInterval,win);
    end
    
    % right eye
    glColorMask(GL.FALSE, GL.TRUE, GL.FALSE, GL.FALSE);
    glMatrixMode(GL.PROJECTION);
    glLoadIdentity;
    glFrustum( FRUSTUM.dexterLeft,FRUSTUM.dexterRight, FRUSTUM.bottom, FRUSTUM.top, FRUSTUM.clipNear, FRUSTUM.clipFar);
    glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;
    gluLookAt(position(1)+TRIALINFO.deviation,position(2),position(3),...
        position(1)+TRIALINFO.deviation,position(2),position(3)-SCREEN.distance,...
        0,1,0)
    glClearColor(0,0,0,0);
    glColor3f(1.0,1.0,0.0);
    DrawDots3D(win,[STARDATA.x ; STARDATA.y; STARDATA.z]);
    
    if ~Fence3D
        Screen('EndOpenGL',win);
        drawFence(Fence3D,TRIALINFO.fenceWidth,TRIALINFO.fenceInterval,win);
    else
        drawFence(Fence3D,TRIALINFO.fenceWidth,TRIALINFO.fenceInterval,win);
        Screen('EndOpenGL',win);
    end
    
    Screen('DrawingFinished',win);
    Screen('Flip',win,0,0);
    
    cameraIndex.position = cat(1,cameraIndex.position,position);
    cameraIndex.velocity = cat(1,cameraIndex.velocity,velocity);
    ballIndex.position = cat(1,ballIndex.position,ballPosition);
    ballIndex.velocity = cat(1,ballIndex.velocity,ballVelocity);
    frameNum = frameNum+1;
end

if eyelinkMode
    
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    try
        fprintf('Receiving data file ''%s''\n',fileName);
        status=Eyelink('ReceiveFile',tempName ,saveDir,1);
        if status > 0
            fprintf('ReceiveFile status %d\n ', status);
        end
        if exist(fileName, 'file')==2
            fprintf('Data file ''%s'' can be found in '' %s\n',fileName, pwd);
        end
    catch
        fprintf('Problem receiving data file ''%s''\n',fileName);
    end
    
    cd (saveDir);
    save(fullfile(saveDir, fileName));
    movefile(fullfile(saveDir,[tempName,'.edf']),fullfile(saveDir,[fileName,'.edf']));
    Eyelink('ShutDown');
end

save(fullfile(saveDir,fileName),'TRIALINFO','cameraIndex','ballIndex','SCREEN','marker');

Screen('CloseAll');
sca;
clearvars;

%% functions
function cleanup
chk=Eyelink('checkrecording');
if chk~=0
    disp('problem: wasn''t recording but should have been')
end
Eyelink('stoprecording');
ShowCursor;
Priority(oldPriority);
status=Eyelink('closefile');
if status ~=0
    disp(sprintf('closefile error, status: %d',status))
end
status=Eyelink('ReceiveFile',edfFile,pwd,1);
if status~=0
    fprintf('problem: ReceiveFile status: %d\n', status);
end
if 2==exist(edfFile, 'file')
    fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
else
    disp('unknown where data file went')
end
Eyelink('shutdown');
end
