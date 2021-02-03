function metrix = StarMetrix()
metrix1 = [2 1;3 1;4 1;3 2;3 3;3 4;2 5;3 5;4 5]; % I
metrix2 = [1 5;2 5;3 5;4 5;5 5;3 1;3 2;3 3;3 4]; % T
metrix3 = [1 1;2 2;3 3;4 4;5 5;5 1;4 2;2 4;1 5]; % X
metrix4 = [1 1;1 2;1 3;1 4;1 5;2 3;3 3;4 3;5 1;5 2;5 3;5 4;5 5]; % H
metrix5 = [2 1;3 1;3 2;3 3;3 4;2 5;3 5;4 5]; % J
metrix = {metrix1/max(metrix1(:)), metrix2/max(metrix2(:)), ...
    metrix3/max(metrix3(:)), metrix4/max(metrix4(:)), metrix5/max(metrix5(:))};
