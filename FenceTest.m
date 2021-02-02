% environment: Matlab R2017a+, Psychtoolbox 3, Eyelink
%
clear all STARDATA
close all

global TRIALINFO
global SCREEN
global GL
global FRUSTUM

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
SCREEN.distance = 0.6;% m

TRIALINFO.deviation = 0.063; % initial binocular deviation, m
deviationAdjust     = 0.002; % how fast to adjust the deviation by key pressing, m

TRIALINFO.fenceWidth = 0.1;  % m
TRIALINFO.fenceInterval = 0.1; % m

% for SCREEN
SCREEN.distance = 0.6;% m

% set keyboard
KbName('UnifyKeyNames');
skipKey   = KbName('space');
escape    = KbName('ESCAPE');
leftKey   = KbName('LeftArrow');
rightKey  = KbName('RightArrow');
upArror   = KbName('UpArrow');
cKey      = KbName('c'); % force calibration, temporally not in use
enter     = KbName('Return');
ballUpKey = KbName('w');
ballDownKey = KbName('s');
ballRightKey = KbName('a');
ballLeftKey = KbName('d');
2DFenceKey = KbName('2@');
3DFenceKey = KbName('3#');
fenceWidthIncrease = KbName('.>');
fenceWidthDecrease = KbName(',<');

pageUp = KbName('pageup'); % increase binocular deviation
pageDown = KbName('pagedown'); % decrease binocular deviation

eyelinkMode = false; % 1/ture: eyelink is in recording; 0/false: eyelink is not on call

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
SCREEN.widthM = width/1000; % mm to m
SCREEN.heightM = height/1000; % mm to m

SCREEN.refreshRate = Screen('NominalFrameRate', SCREEN.screenId);
calculateFrustum();

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
    pause(1); % wait a little bit, in case the key press during calibration influence the following keyboard check
end

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
