function fitness = evaluate_fitness_universal(sequences, mode)
%% 通用适应度评估函数
% 输入:
%   sequences - 待评估序列集合
%   mode - 'manual' (手动输入) 或 'batch' (批量模式)
% 输出:
%   fitness - 适应度数组

if nargin < 2
    mode = 'manual';
end

n = length(sequences);
fitness = zeros(n, 1);

if strcmp(mode, 'batch')
    %% 批量模式：从预加载的数据中获取
    global BATCH_FITNESS_MAP;
    
    if isempty(BATCH_FITNESS_MAP)
        error('批量模式错误：未加载适应度数据。请先运行 load_batch_fitness()');
    end
    
    fprintf('\n从批量数据中获取 %d 个序列的适应度...\n', n);
    
    found_count = 0;
    for i = 1:n
        seq = sequences{i};
        if isKey(BATCH_FITNESS_MAP, seq)
            fitness(i) = BATCH_FITNESS_MAP(seq);
            found_count = found_count + 1;
            fprintf('  [%d/%d] %s -> %.2f (已找到)\n', i, n, seq, fitness(i));
        else
            % 未找到的序列，提示用户手动输入
            fprintf('  [%d/%d] %s -> 未找到\n', i, n, seq);
            fprintf('    请输入此序列的适应度值: ');
            fitness(i) = input('');
            
            % 添加到映射中
            BATCH_FITNESS_MAP(seq) = fitness(i);
        end
    end
    
    fprintf('\n批量模式：成功获取 %d/%d 个适应度值\n', found_count, n);
    
elseif strcmp(mode, 'manual')
    %% 手动模式：逐个输入
    fprintf('\n需要评估 %d 个序列的适应度\n', n);
    fprintf('请进行分子对接实验，然后输入适应度值\n');
    fprintf('（建议范围: 0-100，数值越大表示结合能力越强）\n\n');
    
    for i = 1:n
        fprintf('序列 %d/%d: %s\n', i, n, sequences{i});
        
        % 循环直到获得有效输入
        valid_input = false;
        while ~valid_input
            fitness_input = input('请输入适应度值: ');
            if isnumeric(fitness_input) && isscalar(fitness_input) && fitness_input >= 0
                fitness(i) = fitness_input;
                valid_input = true;
            else
                fprintf('无效输入！请输入非负数值。\n');
            end
        end
    end
    
    fprintf('\n适应度评估完成！\n');
    
else
    error('未知模式: %s。请使用 ''manual'' 或 ''batch''', mode);
end

end
