function fitness_map = load_batch_fitness(filename)
%% 从文件加载批量适应度数据
% 输入:
%   filename - 适应度数据文件名
% 输出:
%   fitness_map - 序列到适应度的映射（containers.Map）

if nargin < 1
    filename = 'fitness_data.txt';
end

fprintf('正在从 %s 读取适应度数据...\n', filename);

% 初始化
fitness_map = containers.Map();

% 打开文件
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件: %s', filename);
end

% 跳过文件头
line_count = 0;
while ~feof(fid)
    line = fgetl(fid);
    line_count = line_count + 1;
    
    % 跳过空行和注释行
    if isempty(line) || startsWith(strtrim(line), '%') || ...
       startsWith(strtrim(line), '说明') || startsWith(strtrim(line), '格式') || ...
       startsWith(strtrim(line), '适应度数据') || contains(line, '序列编号')
        continue;
    end
    
    % 解析数据行：编号 序列 适应度
    parts = strsplit(strtrim(line), '\t');
    
    if length(parts) >= 3
        try
            seq_num = str2double(parts{1});
            sequence = strtrim(parts{2});
            fitness_value = str2double(parts{3});
            
            % 验证数据
            if ~isnan(seq_num) && ~isempty(sequence) && ~isnan(fitness_value)
                fitness_map(sequence) = fitness_value;
                fprintf('  [%d] %s -> %.2f\n', seq_num, sequence, fitness_value);
            end
        catch
            warning('第 %d 行数据格式错误，已跳过', line_count);
        end
    end
end

fclose(fid);

fprintf('\n成功加载 %d 个序列的适应度数据\n', fitness_map.Count);

% 保存到全局变量供其他函数使用
global BATCH_FITNESS_MAP;
BATCH_FITNESS_MAP = fitness_map;

end
