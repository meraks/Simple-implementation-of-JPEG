function [y] = jpegDeco(x, encoType)
% ========================================================
% 参数说明：
%       输入参数：
%           x：输入的编码结构体
%               一般字段：
%                   size：原图像大小
%                   type：编码类型
%                   code：编码结果
%                   quality：量化质量，默认为 1
%                   bits：原图像位数，默认为8位
%               特殊字段：
%                       type为 ‘rlc’：
%                           无特殊字段
%                       type为 ‘huffman’：
%                           numblocks：分[8，8]块数
%                       type为 ‘mix’：
%                           numblocks：分[8，8]块数
%                       type为 ‘simpleHuffman’：
%                           numblocks：分[8，8]块数
%                           dict：huffman 编码的字典
%           encoType：编码类型，与 x 的字段 type 相同时有效
%                   【含有类型为：‘rlc’、‘huffman’、‘mix’、‘simpleHuffman’】
%       输出参数：y ：8位 解码复原图
% ========================================================
narginchk(1, 2);
if nargin < 2
    encoType = 'rlc';
end
if ~isstruct(x)
    error('参数输入错误');
end
xtype = x.type;
if chooseType(encoType) ~= chooseType(xtype)
    error('编码类型(encoType)参数输入错误！');
end
type = chooseType(xtype);
m = [16 11  10  16  24  40  51  61
    12  12  14  19  26  58  60  55
    14  13  16  24  40  57  69  56
    14  17  22  29  51  87  80  62
    18  22  37  56  68  109 103 77
    24  35  55  64  81  104 113 92
    49  64  78  87  103 121 120 101
    72  92  95  98  112 100 103 99];
order = [ 1   2   6   7 15 16 28 29 ...
    3   5   8 14 17 27 30 43 ...
    4   9 13 18 26 31 42 44 ...
    10 12 19 25 32 41 45 54 ...
    11 20 24 33 40 46 53 55 ...
    21 23 34 39 47 52 56 61 ...
    22 35 38 48 51 57 60 62 ...
    36 37 49 50 58 59 63 64];
rev = order;
for k = 1:length(order)
    rev(k) = find(order == k);
end
quality = x.quality;
m = double(quality) .* m;
M = double(x.size(1));
N = double(x.size(2));

if type == 1
    rlc = x.code;
    rlc = double(rlc);
    tmp = RLCDeco(rlc);
    tmp = reshape(tmp, 8*8, []);
elseif type ==2
    xb = double(x.numblocks);             % 分块数
    y = huff2mat(x.code);               % Huffman解码
    eob = max(y(:));                           % EOB标志
    
    tmp = zeros(64, xb);   k = 1;         % 恢复原始图像经过im2col 的大小
    for j = 1:xb                                  % 每列恢复
        for i = 1:64                              % 每行
            if y(k) == eob                      % 找EOB
                k = k + 1;   break;           % 找到EOB
            else
                tmp(i, j) = y(k);
                k = k + 1;
            end
        end
    end
elseif type == 3
    code = x.code;
    xb = x.numblocks;
    tmp = mixDecode(code, xb);
    tmp = reshape(tmp, 8*8, []);
elseif type == 4
    xb = double(x.numblocks);             %  分块数
    dict = x.dict;
    code = double(x.code);
    y = huffmandeco(code, dict);
    eob = max(y(:));
    tmp = zeros(64, xb);   k = 1;
    for j = 1:xb
        for i = 1:64
            if y(k) == eob
                k = k + 1;   break;
            else
                tmp(i, j) = y(k);
                k = k + 1;
            end
        end
    end
end


tmp = tmp(rev, :);
tmpMtx = col2im(tmp, [8, 8], [M, N], 'distinct');
y = blockproc(tmpMtx, [8, 8], @(block_struct) (block_struct.data.*m) );
t = dctmtx(8);
y = blockproc(y, [8, 8], @(block_struct) (t'*block_struct.data*t) );
y = y + double(2^(x.bits - 1));
if x.bits <= 8
    y = uint8(y);
else
    y = uint16(y);
end
end

function type = chooseType(x)
switch x
    case 'rlc'
        type = 1;
    case 'huffman'
        type = 2;
    case 'mix'
        type = 3;
    case 'simpleHuffman'
        type = 4;
    otherwise
        type = 0;
end
end