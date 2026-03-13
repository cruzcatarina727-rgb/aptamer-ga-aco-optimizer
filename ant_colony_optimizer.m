function [best_sequences, best_fitness, history] = ant_colony_optimizer(seed_sequences, params)
%% 蚁群算法优化适配体序列
% 输入:
%   seed_sequences - 种子序列（来自GA的最优解）
%   params - 参数结构体
% 输出:
%   best_sequences - 最优序列集合
%   best_fitness - 对应的适应度值
%   history - 优化历史记录

%% 初始化信息素矩阵
fprintf('初始化ACO信息素矩阵...\n');
n_positions = params.seq_length;
n_bases = length(params.bases);

% 信息素矩阵 [位置 x 碱基类型]
pheromone = ones(n_positions, n_bases);

% 基于种子序列初始化信息素
for s = 1:length(seed_sequences)
    seq = seed_sequences{s};
    for pos = 1:length(seq)
        base_idx = find(params.bases == seq(pos));
        pheromone(pos, base_idx) = pheromone(pos, base_idx) + 1.0;
    end
end

% 归一化
pheromone = pheromone / sum(pheromone(:)) * n_positions * n_bases;

% 启发式信息（初始为均匀分布，可以根据碱基特性调整）
heuristic = ones(n_positions, n_bases);

% 历史记录
history.sequences = {};
history.fitness = [];
all_sequences = {};
all_fitness = [];

%% ACO主循环
for iter = 1:params.aco.iterations
    fprintf('\n--- ACO 第 %d/%d 次迭代 ---\n', iter, params.aco.iterations);
    
    % 蚂蚁构造解
    ant_sequences = cell(params.aco.ant_count, 1);
    
    for ant = 1:params.aco.ant_count
        ant_sequences{ant} = construct_sequence(pheromone, heuristic, ...
            params.aco.alpha, params.aco.beta, params.bases);
    end
    
    % 评估适应度
    fprintf('评估蚂蚁构造的序列适应度...\n');
    ant_fitness = evaluate_fitness_manual(ant_sequences);
    
    % 记录历史
    history.sequences = [history.sequences; ant_sequences];
    history.fitness = [history.fitness; ant_fitness];
    all_sequences = [all_sequences; ant_sequences];
    all_fitness = [all_fitness; ant_fitness];
    
    % 更新信息素
    pheromone = update_pheromone(pheromone, ant_sequences, ant_fitness, ...
        params.aco.rho, params.aco.Q, params.bases);
    
    % 显示当前最优
    [best_iter_fitness, best_iter_idx] = max(ant_fitness);
    fprintf('本次迭代最优适应度: %.4f\n', best_iter_fitness);
    fprintf('本次迭代最优序列: %s\n', ant_sequences{best_iter_idx});
end

%% 返回最优结果
[sorted_fitness, idx] = sort(all_fitness, 'descend');
sorted_sequences = all_sequences(idx);

% 去重（保留适应度最高的）
[unique_seqs, unique_fitness] = remove_duplicates(sorted_sequences, sorted_fitness);

% 返回前10个最优序列
n_best = min(10, length(unique_seqs));
best_sequences = unique_seqs(1:n_best);
best_fitness = unique_fitness(1:n_best);

fprintf('\nACO优化完成！\n');
fprintf('最优适应度: %.4f\n', best_fitness(1));
fprintf('最优序列: %s\n', best_sequences{1});

end

%% ========== 辅助函数 ==========

function sequence = construct_sequence(pheromone, heuristic, alpha, beta, bases)
    % 蚂蚁构造序列
    [n_positions, n_bases] = size(pheromone);
    sequence = char(zeros(1, n_positions));
    
    for pos = 1:n_positions
        % 计算选择概率
        tau = pheromone(pos, :) .^ alpha;  % 信息素
        eta = heuristic(pos, :) .^ beta;   % 启发式信息
        prob = tau .* eta;
        prob = prob / sum(prob);
        
        % 轮盘赌选择
        cumprob = cumsum(prob);
        r = rand();
        base_idx = find(cumprob >= r, 1, 'first');
        
        sequence(pos) = bases(base_idx);
    end
end

function pheromone = update_pheromone(pheromone, sequences, fitness, rho, Q, bases)
    % 更新信息素
    [n_positions, n_bases] = size(pheromone);
    
    % 信息素挥发
    pheromone = (1 - rho) * pheromone;
    
    % 信息素增强
    for i = 1:length(sequences)
        seq = sequences{i};
        delta = Q * fitness(i);  % 适应度越高，增强越多
        
        for pos = 1:length(seq)
            base_idx = find(bases == seq(pos));
            pheromone(pos, base_idx) = pheromone(pos, base_idx) + delta;
        end
    end
    
    % 限制信息素范围，避免过早收敛
    tau_min = 0.1;
    tau_max = 10.0;
    pheromone = max(tau_min, min(tau_max, pheromone));
end

function [unique_seqs, unique_fitness] = remove_duplicates(sequences, fitness)
    % 去除重复序列
    n = length(sequences);
    keep = true(n, 1);
    
    for i = 1:n-1
        if keep(i)
            for j = i+1:n
                if strcmp(sequences{i}, sequences{j})
                    keep(j) = false;
                end
            end
        end
    end
    
    unique_seqs = sequences(keep);
    unique_fitness = fitness(keep);
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
