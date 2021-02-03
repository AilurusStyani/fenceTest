function DrawDots3D(windowPtr, xyz)
% Draw a large number of dots in 3D very efficiently.
%
% Usage: moglDrawDots3D(windowPtr, xyz);
%
% This function is the 3D equivalent of the Screen('DrawDots') subfunction
% for fast drawing of 2D dots. It has mostly the same paramters as that
% function, but extended into the 3D domain. It accepts a subset of the
% parameters for that function, ie., it is less liberal in what it accepts,
% in order to allow for simpler code and maximum efficiency.
%
% As a bonus, it accepts one additional parameter 'glslshader', the
% optional handle to a GLSL shading program, e.g., as loaded from
% filesystem via LoadGLSLProgram().
%
% The routine will draw into the 3D OpenGL userspace rendering context of
% onscreen window or offscreen window (or texture) 'windowPtr'. It will
% automatically switch to that window if it isn't already active in 3D
% mode, and it will restore the drawing target to whatever was set before
% invocation in whatever mode (2D or 3D). This is a convenience feature for
% lazy users that mostly draw in 2D. If you intend to draw more stuff in 3D
% for a given frame, then you should switch your targetwindow 'windowPtr'
% into 3D mode manually via Screen('BeginOpenGL') yourself beforehand. This
% will avoid redundant and expensive context switches and increase the
% execution speed of your code!
%
% Parameters and their meaning:
%
% 'windowPtr' Handle of window or texture to draw into.
% 'xyz' A 3-by-n or 4-by-n matrix of n dots to draw. Each column defines
% one dot to draw, either as 3D position (x,y,z) or 4D position (x,y,z,w).
% Must be a double matrix!
%
%
%
% 'dot_type' optional: A setting of zero will draw rectangular dots, a
% setting of 1 will draw round dots, a setting of 2 will draw round dots of
% extra high quality if the hardware supports that. For anti-aliased dots
% you must select a setting of 1 or 2 and enable alpha blending as well.
%
% 'glslshader' optional: If omitted, shading state is not changed. If set
% to zero, then the standard fixed function OpenGL pipeline is used, like
% in Screen('DrawDots') (under most circumstances). If a positive
% glslshader handle to a GLSL shading program object is provided, that
% shader program will be used. You can use this, e.g., to bind a custom vertex
% shader to perform complex per-dot calculations very fast on the GPU.
%
% See 

% History:
% 03/01/2009  mk  Written.

% Need global GL definitions:
global GL;

% Child protection:
if isempty(GL)
    error('Need OpenGL mode to be enabled, which is not the case! Call InitializeMatlabOpenGL at start of your script first!');
end

if nargin < 1 || isempty(windowPtr)
    error('"windowPtr" window handle missing! This is required!');
end

if nargin < 2 || isempty(xyz)
    % xyz dot position matrix is empty! Nothing to do for us:
    return;
end

% Want single xyz vector as a 3 or 4 row, 1 column vector:
if (size(xyz, 1) == 1) 
% if (size(xyz, 1) == 1) && (ismember(size(xyz, 2), [3,4]))
    xyz = transpose(xyz);
end

nvc = size(xyz, 1);
nrdots = size(xyz, 2);

% % if ~(nvc == 3 || nvc == 4) || nrdots < 1
% %     error('"xyz" argument must have 3 or 4 rows for x,y,z or x,y,z,w components and at least 1 column for at least one dot to draw!');
% % end

% Is the OpenGL userspace context for this 'windowPtr' active, as required?
[previouswin, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');
PreIsOpenGLRendering = IsOpenGLRendering;

% Our target window windowPtr already active?
if previouswin ~= windowPtr
    % No. Wrong window. OpenGL rendering for this window active?
    if IsOpenGLRendering
        % Yes. We need to disable OpenGL mode for that other window and
        % switch to our window:
        Screen('EndOpenGL', windowPtr);
        
        % Our window is attached, but it is in 2D mode, not 3D mode yet:
        IsOpenGLRendering = 0;
    end
end

% Either a different window than ours is bound in 2D mode, then OpenGL
% rendering is not yet active and we need to switch to our window and to
% OpenGL rendering.
%
% Or we just switched from a different window in 3D mode to our window in
% 2D mode. Then we need to switch our window into 3D mode.
%
% In both cases, IsOpenGLRendering == false will indicate this.
%
% A third option is that our wanted window is already active and 3D OpenGL
% mode is already active. In that case IsOpenGLRendering == true and we
% don't need to do anything to switch modes:
if ~IsOpenGLRendering
    % Either some window, or our window bound in 2D mode. Need to switch to
    % our window in 3D mode:
    Screen('BeginOpenGL', windowPtr);
end

% Ok our target window and userspace OpenGL rendering context is bound, we
% can setup and execute the actual drawing:

% Reset dot size to 1.0:
glPointSize(10);

% glColor3f(1,1,0);
glEnable(GL.POINT_SMOOTH);
% % % totalnum=size(xyz,2);
% % % for i=1:totalnum
% % %     glBegin(GL.TRIANGLES)
% % %     glVertex3d(0,0);
% % %     glVertex3d(256,0);
% % %     glVertex3d(128,256);
% % %     glEnd;
% % % end

% Enable fast rendering of arrays:
glEnableClientState(GL.VERTEX_ARRAY);

% Pass a pointer to the start of the point-coordinate array:
glVertexPointer(nvc, GL.DOUBLE, 0, xyz);
% glDrawArrays(GL.POINTS, 0, nrdots);
glDrawArrays(GL.TRIANGLES, 0, nrdots);
% Disable fast rendering of arrays:
glDisableClientState(GL.VERTEX_ARRAY);
glVertexPointer(nvc, GL.DOUBLE, 0, 0);
glDisable(GL.POINT_SMOOTH);

% Our work is done. If a different window than our target window was
% active, we'll switch back to that window and its state:
if previouswin ~= windowPtr
    % Different window was active before our invocation. Need to disable
    % our 3D mode and switch back to that window (in 2D mode):
    Screen('EndOpenGL', previouswin);
    
    % Was that window in 3D mode, i.e., OpenGL rendering for that window was active?
    if PreIsOpenGLRendering
        % Yes. We need to switch that window back into 3D OpenGL mode: 
        Screen('BeginOpenGL', previouswin);
    end
else
    % Our window was active beforehand. Was it in 2D mode? In that case we
    % need to switch our window back to 2D mode. Otherwise we'll just stay
    % in 3D mode:
    if ~PreIsOpenGLRendering
        % Was in 2D mode. We need to switch back to 2D:
        Screen('EndOpenGL', windowPtr);
    end
end

% Switchback complete. The graphics system is the same state as it was
% before our invocation.
return;
