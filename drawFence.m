function drawFence(Fence3D,width,interval,movingBox,win)
global SCREEN
global GL

if ~Fence3D
    %% draw 2D fence
    fenceNumC = floor(SCREEN.widthM/(width+interval));
    fenceCSingle = double(mod(SCREEN.widthM,width+interval)~=0);
    fenceNumR = floor(SCREEN.heightM/(width+interval));
    fenceRSingle = double(mod(SCREEN.heightM,width+interval)~=0);
    fenPix = floor(SCREEN.widthPix/fenceNumC);
    rectMetrix = zeros(4,fenceNumC+fenceCSingle+fenceNumR+fenceRSingle);
    for i = 1:fenceNumC+fenceCSingle
        if i>fenceNumC
            rectMetrix(:,i) = [(i-1)*fenPix, 0, SCREEN.widthPix, SCREEN.heightPix];
        else
            rectMetrix(:,i) = [(i-1)*fenPix, 0, (i-1)*fenPix+fenPix/(width+interval)*width, SCREEN.heightPix];
        end
    end
    
    for i = fenceNumC+fenceCSingle+1 : fenceNumC+fenceCSingle+fenceNumR+fenceRSingle
        if i >fenceNumC+fenceCSingle+fenceNumR
            rectMetrix(:,i) = [0, (i-fenceNumC-fenceCSingle-1)*fenPix, SCREEN.widthPix, SCREEN.heightPix];
        else
            rectMetrix(:,i) = [0, (i-fenceNumC-fenceCSingle-1)*fenPix, SCREEN.widthPix, (i-fenceNumC-fenceCSingle-1)*fenPix+fenPix/(width+interval)*width];
        end
    end
     Screen('FillRect',win,[255 255 0],rectMetrix);
else
    %% draw 3D fence
    fenceNumC = ceil((max(movingBox)-min(movingBox))/(width+interval));
    fenceNumR = ceil(SCREEN.heightM*1.1/(width+interval));
    
    for i = 1:fenceNumC
        glPushMatrix();
        glTranslatef(min(movingBox)+(i-1)*(width+interval),0,-SCREEN.distance);
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
        glTranslatef(-(min(movingBox)+(i-1)*(width+interval)),0,SCREEN.distance);
        glPopMatrix();
    end
    for i = 1:fenceNumR
        glPushMatrix();
        glTranslatef(0,0,-SCREEN.distance);
        glBegin(GL.QUADS);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( min(movingBox), (i-1)*(width+interval)-SCREEN.heightM/2, 0);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( min(movingBox), (i-1)*(width+interval)-SCREEN.heightM/2+width, 0);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( max(movingBox), (i-1)*(width+interval)-SCREEN.heightM/2+width, 0);
        
        %     glColor4f(color1(1),color1(2),color1(3), colorAlpha);
        glVertex3f( max(movingBox), (i-1)*(width+interval)-SCREEN.heightM/2, 0);
        
        glEnd();
        glTranslatef(0,0,SCREEN.distance);
        glPopMatrix();
    end
end