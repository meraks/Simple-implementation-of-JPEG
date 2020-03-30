function encode = RLCEnco(x)
len = length(x);
encode = zeros(1, 2*len);
i = 1;
cnt = 1;
while i <= len
    tmp = x(i);
    numOfTmp = 1;
    while i < len && tmp == x(i+1)
        i = i+1;
        numOfTmp = numOfTmp+1;
    end
    i = i+1;
    encode(cnt*2-1:cnt*2) = [numOfTmp tmp];
    cnt = cnt +1;
end
encode(cnt*2-1:end) = [];
    