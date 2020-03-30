function [encode] = jpegEnco(x, quality, encoType)
% ========================================================
% 参数说明：
%       输入参数：
%           x ：8位原图（仅支持2维图像）
%           quality：量化质量
%           encoType：编码类型
%                   【含有类型为：‘rlc’、‘huffman’、‘mix’、‘simpleHuffman’】
%       输出参数：
%           encode：输入的编码结构体
%               一般字段：
%                   size：原图像大小
%                   type：编码类型
%                   code：编码结果
%                   quality：压缩质量，默认为 1
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
% ========================================================
if nargin < 3
    encoType = 'rlc';
end
if nargin < 2
    quality = 1;
end
if ~ismatrix(x) || ~isreal(x) ||  ~isnumeric(x) || ~isa(x, 'uint8')
    error('仅支持8位图像!');
end

switch encoType
    case 'rlc'
        type = 1;
    case 'huffman'
        type = 2;
    case 'mix'
        type = 3;
    case 'simpleHuffman'
        type = 4;
    otherwise
        error('编码类型错误');
end
m = [16 11  10  16  24  40  51  61
    12  12  14  19  26  58  60  55
    14  13  16  24  40  57  69  56
    14  17  22  29  51  87  80  62
    18  22  37  56  68  109 103 77
    24  35  55  64  81  104 113 92
    49  64  78  87  103 121 120 101
    72  92  95  98  112 100 103 99] .* quality;
order = [ 1   2   6   7 15 16 28 29 ...
    3   5   8 14 17 27 30 43 ...
    4   9 13 18 26 31 42 44 ...
    10 12 19 25 32 41 45 54 ...
    11 20 24 33 40 46 53 55 ...
    21 23 34 39 47 52 56 61 ...
    22 35 38 48 51 57 60 62 ...
    36 37 49 50 58 59 63 64];
[M, N] = size(x);
x = double(x) - 128;
t = dctmtx(8);
y = blockproc(x, [8, 8], @(block_struct) (t*block_struct.data*t') );
y = blockproc(y, [8, 8], @(block_struct) (round(block_struct.data./m)) );

y = im2col(y, [8, 8], 'distinct');
y = y(order, :);

if type == 1
    rlc = RLCEnco(y(:));
    encode = struct;
    encode.code = int8(rlc);
    encode.size = uint16([M, N]);
    encode.type = 'rlc';
    encode.quality = uint16(quality);
    encode.bits = uint16(8);
elseif type == 2
    xb = size(y, 2);   
    eob = max(y(:)) + 1;               % 创建EOB
    % 获得压缩前序列
    r = zeros(numel(y) + size(y, 2), 1);
    count = 0;
    for j = 1:xb                   
        i = find(y(:, j), 1, 'last' );  % 找到最后一个非0元素
        if isempty(i)                   
            i = 0;
        end
        p = count + 1;
        q = p + i;
        r(p:q) = [y(1:i, j); eob];      % 从EOB开始截断
        count = count + i + 1;         
    end
    
    r((count + 1):end) = [];           % 删除未使用的r的空间
    
    encode           = struct;
    encode.size      = uint16([M N]);
    encode.bits      = uint16(8);
    encode.numblocks = uint16(xb);
    encode.quality   = uint16(quality);
    encode.code   = mat2huff(r);
    encode.type = 'huffman';
elseif type == 3
    xb = size(y, 2);
    FormerDC = 0;
    lastcode = '';
    for i = 1:xb
        line = y(:, i);
        strcode = mixEncode(line,FormerDC); %编码
        lastcode = [lastcode,strcode];
        FormerDC = line(1);
    end
    encode           = struct;
    encode.size      = uint16([M N]);
    encode.bits      = uint16(8);
    encode.numblocks = uint16(xb);
    encode.quality   = uint16(quality);
    encode.code   = lastcode;
    encode.type = 'mix';
elseif type == 4
        xb = size(y, 2);   
    eob = max(y(:)) + 1;               % 创建EOB
    % 获得压缩前序列
    r = zeros(numel(y) + size(y, 2), 1);
%     r = r+ 128;     
    count = 0;
    for j = 1:xb                   
        i = find(y(:, j), 1, 'last' );  % 找到最后一个非0元素
        if isempty(i)                   
            i = 0;
        end
        p = count + 1;
        q = p + i;
        r(p:q) = [y(1:i, j); eob];      % 从EOB开始截断
        count = count + i + 1;         
    end
    r((count + 1):end) = [];           % 删除未使用的r的空间
    % 简单Huffman 编码
    len = length(r);
    symbols = min(r): max(r);
    P = zeros(1, length(symbols));
    cnt = 1;
    for i = min(r): max(r)
        P(cnt)=length(find(r==i))/len;  %统计概率
        cnt = cnt + 1;
    end
    dict = huffmandict(symbols, P);
    code = huffmanenco(r, dict);
    encode = struct;
    encode.size = uint16([M N]);
    encode.bits = uint16(8);
    encode.numblocks = uint16(xb);
    encode.quality = uint16(quality);
    encode.code = code;
    encode.type = 'simpleHuffman';
    encode.dict = dict;
end


