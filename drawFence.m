function drawFence(Fence3D,width,interval,win)
global SCREEN
global TRIALINFO
global GL

% in 2D
if ~Fence3D
    fenceNum = floor(SCREEN.widthM/(width+interval));
    fenPix = floor(SCREEN.widthPix/fenceNum);
    rectMetrix = zeros(4,fenceNum+double(mod(SCREEN.widthM,width+interval)~=0));
    for i = 1:fenceNum
        rectMetrix(:,i) = [(i-1)*fenPix, 0, (i-1)*fenPix+fenPix/(width+interval)*width, SCREEN.heightPix];
    end
    if mod(SCREEN.widthM,width+interval)~=0
        rectMetrix(:,end) = [fenceNum*fenPix, 0, SCREEN.widthPix, SCREEN.heightPix];
    end
     Screen('FillRect',win,[255 255 0],rectMetrix);
else
    fenceNum = ceil(max(TRIALINFO.movingBox)-min(TRIALINFO.movingBox))*1.1/(width+interval);
    
    for i = 1:fenceNum
        glPushMatrix();
        glTranslatef(min(TRIALINFO.movingBox)+(i-1)*(width+interval),0,-SCREEN.distance);
        glBegin(GL.QUADS);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( 0, -SCREEN.heightM/2, 0);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( 0, +SCREEN.heightM/2, 0);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( 0+width, +SCREEN.heightM/2, 0);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( 0+width, -SCREEN.heightM/2, 0);
        
        glEnd();
        glTranslatef(-(min(TRIALINFO.movingBox)+(i-1)*(width+interval)),0,SCREEN.distance);
        glPopMatrix();
    end
end