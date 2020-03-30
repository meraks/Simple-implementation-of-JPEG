function decode = mixDecode( code, blocks)
load ACpara.mat

% truerow = height/8; %8*8大小块
% truecol = width/8;
isBlockStart = 1; %判断是否处于每一个块的开始
BlockPoint = 1; %当前处于块中的位置
% BlockRow = 1; %计数解码了多少行个块
% BlockCol = 1; %计数解码了多少列个块
decode = zeros(1, blocks*64);
intBlock = zeros(1, 64); %解码后的1*64数组
DCFomer = 0; %保存前一块的DC分量
DCLen = 0; %直流分量尺寸
ACLen = 0; %当前交流分量尺寸
i = 1; %计数处于整个字符串所在位置
j = 1; %计数码字偏移
cnt = 0;

while 1
    if isBlockStart == 1 %是块开头则计算DC分量，不是则计算AC分量
        i = i + DCLen + ACLen;
        if (i >= length(code))
            break;
        end
        ACLen = 0;
        j = 1;
        DCcode = '';
        dcint = []; %清零int型编码
        while 1 %不停寻找码字，直到码字出现，进行解码DC操作，并退出循环
            id = ismember(DC,code(i:i + j));
            [m,n] = find (id == 1); %寻找码字
            if isempty(m)
                j = j + 1;
            else
                DCPre = code(i:i + j); %前缀码
                DCLen = DClength(n); %尺寸
                if DCLen == 0
                    DCpara = 0;
                    break
                end
                DCcode(1,1:DCLen) = code(i + j + 1:i + j + DCLen); %尾码
                DCpara = 0; %存放算出的十六分量值
                for m = 1 : DCLen %转为int值
                    dcint(m) = str2num(DCcode(m));
                end
                if dcint(1) == 1 %判断正负
                    for m = 1:DCLen
                        DCpara = DCpara + dcint(m) * 2 ^ (DCLen - m);
                    end
                else
                    for m = 1:DCLen
                        if dcint(m) == 0
                            dcint(m) = 1;
                        else
                            dcint(m) = 0;
                        end
                        DCpara = DCpara + dcint(m) * 2 ^ (DCLen - m);
                    end
                    DCpara = -DCpara;
                end
                break
            end
        end
        isBlockStart = 0;
        BlockPoint = BlockPoint + 1;
        intBlock(1) = DCpara + DCFomer;
        DCFomer = intBlock(1);
        
    else
        i = i + j + DCLen + ACLen + 1;
        if (i >= length(code))
            break;
        end
        DCLen = 0;
        ACcode = '';
        acint = [];
        j = 1;
        while 1
            id = ismember(AC,code(i:i + j));
            [m,n] = find (id == 1);
            if isempty(m)
                j = j + 1;
            elseif m == 1 && n == 1 %为结束码
                BlockPoint = 64;
                ACLen = 4;
                ACpara = 0;
                runlength = 0;
                break
            elseif m == 16 && n == 1 %为超长码
                runlength = 15;
                ACpara = 0;
                ACLen = 0;
                break;
            else
                ACPre = code(i:i + j);
                runlength = m - 1;
                ACLen = AClength(n - 1);
                ACcode(1,1:ACLen) = code(i + j + 1:i + j + ACLen);
                ACpara = 0;
                for m = 1 : ACLen
                    acint(m) = str2num(ACcode(m));
                end
                if acint(1) == 1
                    for m = 1:ACLen
                        ACpara = ACpara + acint(m) * 2 ^ (ACLen - m);
                    end
                else
                    for m = 1:ACLen
                        if acint(m) == 0
                            acint(m) = 1;
                        else
                            acint(m) = 0;
                        end
                        ACpara = ACpara + acint(m) * 2 ^ (ACLen - m);
                    end
                    ACpara = -ACpara;
                end
                break
            end
        end
        intBlock(BlockPoint + runlength) = ACpara;
        if BlockPoint == 64
            isBlockStart = 1;
            BlockPoint = 0;
            decode(cnt*64+1: cnt*64+64) = intBlock;
            cnt = cnt + 1;
            intBlock(1:64) = 0;
        end
        BlockPoint = BlockPoint + runlength + 1;
    end
    if (i >= length(code))
        break;
    end
end