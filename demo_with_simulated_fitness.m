%% 适配体序列优化演示版本 - 自动模拟适应度
% 用于测试系统功能，无需手动输入适应度
% 注意：这只是演示，实际使用时应该用真实的分子对接数据

clear; clc; close all;

fprintf('========================================\n');
fprintf('适配体序列优化系统 - 演示模式\n');
fprintf('（使用模拟适应度函数）\n');
fprintf('========================================\n\n');

%% ========== 参数设置 ==========
params.seq_length = 26;
params.bases = ['A', 'T', 'G', 'C'];
params.AF26 = 'CACGTGTTGTCTCTCTGTGTCTCGTG';
params.init_mutation_rate = 0.1;

% 遗传算法参数（简化以加快演示）
params.ga.pop_size = 15;
params.ga.generations = 5;
params.ga.crossover_rate = 0.8;
params.ga.mutation_rate = 0.1;
params.ga.elite_count = 2;

% 蚁群算法参数
params.aco.ant_count = 10;
params.aco.iterations = 4;
params.aco.alpha = 1.0;
params.aco.beta = 2.0;
params.aco.rho = 0.3;
params.aco.Q = 100;

% 混合策略参数
params.hybrid.ga_cycles = 2;
params.hybrid.top_n_for_aco = 3;

%% ========== 初始化 ==========
results.best_sequences = {};
results.best_fitness = [];
results.history = struct('sequences', {}, 'fitness', [], 'method', {});

%% ========== 混合优化主循环 ==========
for cycle = 1:params.hybrid.ga_cycles
    fprintf('\n===== 混合优化循环 %d/%d =====\n', cycle, params.hybrid.ga_cycles);
    
    %% 第一阶段：遗传算法
    fprintf('\n--- 阶段1: 遗传算法 ---\n');
    [ga_best_seqs, ga_best_fitness, ga_history] = ...
        ga_demo(params);
    
    results.history(end+1).sequences = ga_history.sequences;
    results.history(end).fitness = ga_history.fitness;
    results.history(end).method = 'GA';
    
    %% 第二阶段：蚁群算法
    fprintf('\n--- 阶段2: 蚁群算法 ---\n');
    top_n = min(params.hybrid.top_n_for_aco, length(ga_best_seqs));
    seed_sequences = ga_best_seqs(1:top_n);
    
    [aco_best_seqs, aco_best_fitness, aco_history] = ...
        aco_demo(seed_sequences, params);
    
    results.history(end+1).sequences = aco_history.sequences;
    results.history(end).fitness = aco_history.fitness;
    results.history(end).method = 'ACO';
    
    %% 更新全局最优
    all_seqs = [ga_best_seqs; aco_best_seqs];
    all_fitness = [ga_best_fitness; aco_best_fitness];
    
    [sorted_fitness, idx] = sort(all_fitness, 'descend');
    sorted_seqs = all_seqs(idx);
    
    results.best_sequences = sorted_seqs;
    results.best_fitness = sorted_fitness;
    
    fprintf('\n>>> 循环 %d 最优适应度: %.4f\n', cycle, sorted_fitness(1));
end

%% ========== 结果汇总 ==========
fprintf('\n========================================\n');
fprintf('演示完成！\n');
fprintf('========================================\n');
fprintf('全局最优适应度: %.4f\n', results.best_fitness(1));
fprintf('全局最优序列: %s\n', results.best_sequences{1});
fprintf('\nTop 5 序列:\n');
for i = 1:min(5, length(results.best_sequences))
    fprintf('%d. [%.4f] %s\n', i, results.best_fitness(i), ...
        results.best_sequences{i});
end

%% ========== 可视化 ==========
visualize_results(results);

fprintf('\n提示: 实际使用时，请运行 main_aptamer_optimizer.m\n');
fprintf('并使用真实的分子对接数据作为适应度！\n');

%% ========== 辅助函数 ==========

function [best_sequences, best_fitness, history] = ga_demo(params)
    % GA演示版本
    population = cell(params.ga.pop_size, 1);
    for i = 1:params.ga.pop_size
        if i == 1
            population{i} = params.AF26;  % 保留原始AF26
        else
            population{i} = mutate_from_seed(params.AF26, ...
                             params.init_mutation_rate, params.bases);
        end
    end
    
    fitness = simulate_fitness(population);
    history.sequences = population;
    history.fitness = fitness;
    
    for gen = 1:params.ga.generations
        [sorted_fitness, idx] = sort(fitness, 'descend');
        sorted_population = population(idx);
        
        fprintf('  代 %d: 最优=%.2f, 平均=%.2f\n', gen, ...
            sorted_fitness(1), mean(sorted_fitness));
        
        new_population = sorted_population(1:params.ga.elite_count);
        
        while length(new_population) < params.ga.pop_size
            p1 = sorted_population{randi(length(sorted_population))};
            p2 = sorted_population{randi(length(sorted_population))};
            
            if rand() < params.ga.crossover_rate
                point = randi([1, params.seq_length-1]);
                child = [p1(1:point), p2(point+1:end)];
            else
                child = p1;
            end
            
            for i = 1:length(child)
                if rand() < params.ga.mutation_rate
                    child(i) = params.bases(randi(4));
                end
            end
            
            new_population{end+1} = child;
        end
        
        new_population = new_population(1:params.ga.pop_size);
        new_fitness = simulate_fitness(new_population(params.ga.elite_count+1:end));
        fitness = [sorted_fitness(1:params.ga.elite_count); new_fitness];
        population = new_population;
        
        history.sequences = [history.sequences; population];
        history.fitness = [history.fitness; fitness];
    end
    
    [sorted_fitness, idx] = sort(fitness, 'descend');
    best_sequences = population(idx);
    best_fitness = sorted_fitness;
end

function [best_sequences, best_fitness, history] = aco_demo(seed_sequences, params)
    % ACO演示版本
    n_pos = params.seq_length;
    n_bases = 4;
    pheromone = ones(n_pos, n_bases);
    
    for s = 1:length(seed_sequences)
        seq = seed_sequences{s};
        for pos = 1:length(seq)
            base_idx = find(params.bases == seq(pos));
            pheromone(pos, base_idx) = pheromone(pos, base_idx) + 1.0;
        end
    end
    
    history.sequences = {};
    history.fitness = [];
    all_seqs = {};
    all_fitness = [];
    
    for iter = 1:params.aco.iterations
        ant_seqs = cell(params.aco.ant_count, 1);
        for ant = 1:params.aco.ant_count
            ant_seqs{ant} = construct_sequence_demo(pheromone, params);
        end
        
        ant_fitness = simulate_fitness(ant_seqs);
        
        fprintf('  迭代 %d: 最优=%.2f\n', iter, max(ant_fitness));
        
        history.sequences = [history.sequences; ant_seqs];
        history.fitness = [history.fitness; ant_fitness];
        all_seqs = [all_seqs; ant_seqs];
        all_fitness = [all_fitness; ant_fitness];
        
        pheromone = (1 - params.aco.rho) * pheromone;
        for i = 1:length(ant_seqs)
            seq = ant_seqs{i};
            delta = params.aco.Q * ant_fitness(i);
            for pos = 1:length(seq)
                base_idx = find(params.bases == seq(pos));
                pheromone(pos, base_idx) = pheromone(pos, base_idx) + delta;
            end
        end
    end
    
    [sorted_fitness, idx] = sort(all_fitness, 'descend');
    best_sequences = all_seqs(idx);
    best_fitness = sorted_fitness;
end

function seq = construct_sequence_demo(pheromone, params)
    seq = char(zeros(1, params.seq_length));
    for pos = 1:params.seq_length
        prob = pheromone(pos, :);
        prob = prob / sum(prob);
        cumprob = cumsum(prob);
        r = rand();
        base_idx = find(cumprob >= r, 1, 'first');
        seq(pos) = params.bases(base_idx);
    end
end

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
    idx = randi(4, 1, length);
    seq = bases(idx);
end

function fitness = simulate_fitness(sequences)
    % 模拟适应度函数
    % 基于一些启发式规则：GC含量、序列多样性等
    n = length(sequences);
    fitness = zeros(n, 1);
    
    for i = 1:n
        seq = sequences{i};
        
        % GC含量（最优约50%）
        gc = (sum(seq == 'G') + sum(seq == 'C')) / length(seq);
        gc_score = 100 * (1 - abs(gc - 0.5) * 2);
        
        % 序列复杂度（避免重复）
        complexity = length(unique(seq)) / 4 * 100;
        
        % 避免连续相同碱基
        max_repeat = 1;
        current_repeat = 1;
        for j = 2:length(seq)
            if seq(j) == seq(j-1)
                current_repeat = current_repeat + 1;
                max_repeat = max(max_repeat, current_repeat);
            else
                current_repeat = 1;
            end
        end
        repeat_penalty = max(0, 100 - max_repeat * 10);
        
        % 综合评分
        fitness(i) = 0.4 * gc_score + 0.3 * complexity + 0.3 * repeat_penalty;
        
        % 添加随机噪声
        fitness(i) = fitness(i) + randn() * 5;
        fitness(i) = max(0, min(100, fitness(i)));
    end
end