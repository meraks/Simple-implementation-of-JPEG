function y = RLCDeco(x)
if mod(length(x), 2) ~= 0
    error('提供的行程编码有误！');
end
if ~isnumeric(x) 
    error('提供参数需为数值型！');
end
x = reshape(x, [2, length(x)/2])';
xm = size(x, 1);
numOfCodes = sum(x);
y = zeros(1, numOfCodes(1));
p = 1;
for i=1:xm
    cnt = x(i, 1);
    tmp = x(i, 2);
    q = p + cnt - 1;
    y(p: q) = ones(1, cnt)*tmp;
    p = q + 1;
end