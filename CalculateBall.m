function CalculateBall(metrix,ballPosition,ballSize,starSize)
clear global STARDATA
global STARDATA;
j=1;
for i = 1:size(metrix,1)
    STARDATA.x(j) = ballPosition(1)+metrix(i,1)*ballSize-ballSize/2-starSize/2;
    STARDATA.y(j) = ballPosition(2)+metrix(i,2)*ballSize-ballSize/2-starSize/2;
    STARDATA.z(j) = ballPosition(3);
    j=j+1;
    STARDATA.x(j) = ballPosition(1)+metrix(i,1)*ballSize-ballSize/2;
    STARDATA.y(j) = ballPosition(2)+metrix(i,2)*ballSize-ballSize/2+starSize/2;
    STARDATA.z(j) = ballPosition(3);
    j=j+1;
    STARDATA.x(j) = ballPosition(1)+metrix(i,1)*ballSize-ballSize/2+starSize/2;
    STARDATA.y(j) = ballPosition(2)+metrix(i,2)*ballSize-ballSize/2-starSize/2;
    STARDATA.z(j) = ballPosition(3);
    j=j+1;
end