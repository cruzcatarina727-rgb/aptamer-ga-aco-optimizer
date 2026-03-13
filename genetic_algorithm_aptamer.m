function [best_sequences, best_fitness, history] = genetic_algorithm_aptamer(params)
%% 遗传算法优化适配体序列
% 输入:
%   params - 参数结构体
% 输出:
%   best_sequences - 最优序列集合
%   best_fitness - 对应的适应度值
%   history - 优化历史记录

%% 初始化种群
fprintf('初始化GA种群...\n');
population = cell(params.ga.pop_size, 1);
for i = 1:params.ga.pop_size
    if i == 1
        population{i} = params.AF26;  % 保留原始AF26
    else
        population{i} = mutate_from_seed(params.AF26, ...
                         params.init_mutation_rate, params.bases);
    end
end

% 初始化适应度数组
fitness = zeros(params.ga.pop_size, 1);
history.sequences = {};
history.fitness = [];

%% 评估初始种群适应度
fprintf('评估初始种群适应度（需要手动输入）...\n');
fitness = evaluate_fitness_manual(population);

% 记录初始种群
history.sequences = [history.sequences; population];
history.fitness = [history.fitness; fitness];

%% 遗传算法主循环
for gen = 1:params.ga.generations
    fprintf('\n--- GA 第 %d/%d 代 ---\n', gen, params.ga.generations);
    
    % 排序种群（降序）
    [sorted_fitness, idx] = sort(fitness, 'descend');
    sorted_population = population(idx);
    
    fprintf('当前代最优适应度: %.4f\n', sorted_fitness(1));
    fprintf('当前代平均适应度: %.4f\n', mean(sorted_fitness));
    
    % 精英保留
    new_population = sorted_population(1:params.ga.elite_count);
    new_fitness = sorted_fitness(1:params.ga.elite_count);
    
    % 生成新个体
    while length(new_population) < params.ga.pop_size
        % 选择父代（锦标赛选择）
        parent1 = tournament_selection(sorted_population, sorted_fitness, 3);
        parent2 = tournament_selection(sorted_population, sorted_fitness, 3);
        
        % 交叉
        if rand() < params.ga.crossover_rate
            [child1, child2] = crossover(parent1, parent2);
        else
            child1 = parent1;
            child2 = parent2;
        end
        
        % 变异
        child1 = mutate(child1, params.ga.mutation_rate, params.bases);
        child2 = mutate(child2, params.ga.mutation_rate, params.bases);
        
        % 添加到新种群
        new_population{end+1} = child1;
        if length(new_population) < params.ga.pop_size
            new_population{end+1} = child2;
        end
    end
    
    % 裁剪到种群大小
    new_population = new_population(1:params.ga.pop_size);
    
    % 评估新个体的适应度（只评估非精英个体）
    fprintf('评估新个体适应度...\n');
    new_individuals = new_population(params.ga.elite_count+1:end);
    new_individuals_fitness = evaluate_fitness_manual(new_individuals);
    
    % 合并适应度
    fitness = [new_fitness; new_individuals_fitness];
    population = new_population;
    
    % 记录历史
    history.sequences = [history.sequences; population];
    history.fitness = [history.fitness; fitness];
end

%% 返回最优结果
[sorted_fitness, idx] = sort(fitness, 'descend');
sorted_population = population(idx);

% 返回前10个最优序列
n_best = min(10, length(sorted_population));
best_sequences = sorted_population(1:n_best);
best_fitness = sorted_fitness(1:n_best);

fprintf('\nGA优化完成！\n');
fprintf('最优适应度: %.4f\n', best_fitness(1));
fprintf('最优序列: %s\n', best_sequences{1});

end

%% ========== 辅助函数 ==========

function seq = mutate_from_seed(seed, mutation_rate, bases)
    % 基于种子序列进行随机突变，生成初始种群个体
    seq = seed;
    for i = 1:length(seed)
        if rand() < mutation_rate
            current = seed(i);
            other = bases(bases ~= current);
            seq(i) = other(randi(length(other)));
        end
    end
end

function seq = generate_random_sequence(length, bases)
    % 生成随机DNA/RNA序列
    idx = randi(length(bases), 1, length);
    seq = bases(idx);
end

function parent = tournament_selection(population, fitness, k)
    % 锦标赛选择
    n = length(population);
    contestants_idx = randperm(n, k);
    contestants_fitness = fitness(contestants_idx);
    [~, winner_idx] = max(contestants_fitness);
    parent = population{contestants_idx(winner_idx)};
end

function [child1, child2] = crossover(parent1, parent2)
    % 单点交叉
    len = length(parent1);
    point = randi([1, len-1]);
    
    child1 = [parent1(1:point), parent2(point+1:end)];
    child2 = [parent2(1:point), parent1(point+1:end)];
end

function mutated = mutate(sequence, mutation_rate, bases)
    % 点变异
    mutated = sequence;
    for i = 1:length(sequence)
        if rand() < mutation_rate
            % 随机替换为其他碱基
            current_base = sequence(i);
            other_bases = bases(bases ~= current_base);
            mutated(i) = other_bases(randi(length(other_bases)));
        end
    end
end

function fitness = evaluate_fitness_manual(sequences)
    % 手动输入适应度
    n = length(sequences);
    fitness = zeros(n, 1);
    
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
end