%% 适配体序列优化主程序
% 混合遗传算法 + 蚁群算法优化框架
%
% 依赖脚本（需在同一目录下）:
%   genetic_algorithm_aptamer.m  - GA优化模块
%   ant_colony_optimizer.m       - ACO优化模块
%   visualize_results.m          - 结果可视化
%
% 使用流程:
%   1. 运行本脚本
%   2. 程序每次需要评估序列时自动暂停，等待用户输入适应度值
%   3. 输入完成后程序自动继续，直至优化结束

clear; clc; close all;

fprintf('========================================\n');
fprintf('    适配体序列优化系统\n');
fprintf('    混合 GA + ACO 优化框架\n');
fprintf('========================================\n\n');
fprintf('说明：程序在每次需要适应度数据时会自动暂停，\n');
fprintf('      请完成分子对接实验后逐条输入结果。\n\n');

%% ========== 参数设置 ==========
params.seq_length         = 26;
params.bases              = ['A', 'T', 'G', 'C'];
params.AF26               = 'XXXXXXXXXXXXXXXXXXXXXXXXXX';  % 种子序列
params.init_mutation_rate = 0.1;                            % 初始种群突变率

% 遗传算法参数
params.ga.pop_size        = 20;   % 种群大小
params.ga.generations     = 10;   % 迭代代数
params.ga.crossover_rate  = 0.8;  % 交叉概率
params.ga.mutation_rate   = 0.1;  % 变异概率
params.ga.elite_count     = 2;    % 精英保留数量

% 蚁群算法参数
params.aco.ant_count      = 15;   % 蚂蚁数量
params.aco.iterations     = 5;    % 迭代次数
params.aco.alpha          = 1.0;  % 信息素权重
params.aco.beta           = 2.0;  % 启发式信息权重
params.aco.rho            = 0.3;  % 信息素挥发率
params.aco.Q              = 100;  % 信息素强化系数

% 混合策略参数
params.hybrid.ga_cycles     = 3;  % GA+ACO循环次数
params.hybrid.top_n_for_aco = 5;  % 传递给ACO的种子序列数量

%% ========== 初始化结果结构 ==========
results.best_sequences = {};
results.best_fitness   = [];
results.history        = struct('sequences', {{}}, 'fitness', [], 'method', '');
results.history        = results.history([]);

fprintf('按任意键开始优化...\n');
pause;

%% ========== 混合优化主循环 ==========
for cycle = 1:params.hybrid.ga_cycles

    fprintf('\n========================================\n');
    fprintf('  混合优化循环 %d / %d\n', cycle, params.hybrid.ga_cycles);
    fprintf('========================================\n');

    %% --- 阶段1：遗传算法 ---
    fprintf('\n>>> 阶段1: 遗传算法（GA）\n');
    fprintf('    种群大小: %d，迭代代数: %d\n', ...
        params.ga.pop_size, params.ga.generations);

    [ga_best_seqs, ga_best_fitness, ga_history] = ...
        genetic_algorithm_aptamer(params);

    entry_ga.sequences = ga_history.sequences;
    entry_ga.fitness   = ga_history.fitness;
    entry_ga.method    = 'GA';
    results.history(end+1) = entry_ga;

    fprintf('\nGA阶段完成 - 最优适应度: %.4f\n', ga_best_fitness(1));
    fprintf('GA最优序列: %s\n', ga_best_seqs{1});

    %% --- 阶段2：蚁群算法 ---
    fprintf('\n>>> 阶段2: 蚁群算法（ACO）\n');
    top_n = min(params.hybrid.top_n_for_aco, length(ga_best_seqs));
    seed_sequences = ga_best_seqs(1:top_n);
    fprintf('    使用GA Top-%d序列作为ACO种子\n', top_n);
    fprintf('    蚂蚁数量: %d，迭代次数: %d\n', ...
        params.aco.ant_count, params.aco.iterations);

    [aco_best_seqs, aco_best_fitness, aco_history] = ...
        ant_colony_optimizer(seed_sequences, params);

    entry_aco.sequences = aco_history.sequences;
    entry_aco.fitness   = aco_history.fitness;
    entry_aco.method    = 'ACO';
    results.history(end+1) = entry_aco;

    fprintf('\nACO阶段完成 - 最优适应度: %.4f\n', aco_best_fitness(1));
    fprintf('ACO最优序列: %s\n', aco_best_seqs{1});

    %% --- 合并本轮结果，更新全局最优 ---
    all_seqs    = [results.best_sequences; ga_best_seqs;    aco_best_seqs];
    all_fitness = [results.best_fitness;   ga_best_fitness; aco_best_fitness];

    [sorted_fitness, idx] = sort(all_fitness, 'descend');
    sorted_seqs = all_seqs(idx);
    [unique_seqs, unique_fitness] = remove_duplicates(sorted_seqs, sorted_fitness);

    n_keep = min(5, length(unique_seqs));
    results.best_sequences = unique_seqs(1:n_keep);
    results.best_fitness   = unique_fitness(1:n_keep);

    fprintf('\n>>> 循环 %d 结束 - 全局最优适应度: %.4f\n', ...
        cycle, results.best_fitness(1));
end

%% ========== 最终结果汇总 ==========
fprintf('\n========================================\n');
fprintf('优化完成！\n');
fprintf('========================================\n');
fprintf('全局最优适应度: %.4f\n', results.best_fitness(1));
fprintf('全局最优序列:   %s\n\n', results.best_sequences{1});

fprintf('Top %d 序列汇总：\n', length(results.best_sequences));
fprintf('%-6s  %-8s  %s\n', '排名', '适应度', '序列');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:length(results.best_fitness)
    fprintf('%-6d  %-8.4f  %s\n', i, results.best_fitness(i), ...
        results.best_sequences{i});
end

%% ========== 各轮迭代详细记录输出 ==========
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
report_file = sprintf('aptamer_detail_%s.txt', timestamp);
fid = fopen(report_file, 'w');

fprintf('\n========================================\n');
fprintf('各轮迭代序列适应度详细记录\n');
fprintf('========================================\n');
fprintf(fid, '适配体序列优化 - 各轮迭代详细记录\n');
fprintf(fid, '生成时间: %s\n', datestr(now));
fprintf(fid, '================================================\n\n');

ga_cycle  = 0;
aco_cycle = 0;

for h = 1:length(results.history)
    method = results.history(h).method;
    seqs   = results.history(h).sequences;
    fits   = results.history(h).fitness;

    if strcmp(method, 'GA')
        ga_cycle = ga_cycle + 1;
        header = sprintf('【循环 %d - GA 阶段】共 %d 条记录', ga_cycle, length(seqs));
    else
        aco_cycle = aco_cycle + 1;
        header = sprintf('【循环 %d - ACO 阶段】共 %d 条记录', aco_cycle, length(seqs));
    end

    fprintf('\n%s\n', header);
    fprintf(fid, '\n%s\n', header);
    fprintf('%-6s  %-8s  %s\n', '编号', '适应度', '序列');
    fprintf(fid, '%-6s  %-8s  %s\n', '编号', '适应度', '序列');
    fprintf('%s\n', repmat('-', 1, 55));
    fprintf(fid, '%s\n', repmat('-', 1, 55));

    for k = 1:length(seqs)
        fprintf('%-6d  %-8.4f  %s\n', k, fits(k), seqs{k});
        fprintf(fid, '%-6d  %-8.4f  %s\n', k, fits(k), seqs{k});
    end
end

% Top-5 汇总
fprintf('\n========================================\n');
fprintf('Top 5 最优序列\n');
fprintf('========================================\n');
fprintf('%-6s  %-8s  %s\n', '排名', '适应度', '序列');
fprintf('%s\n', repmat('-', 1, 55));
fprintf(fid, '\n================================================\n');
fprintf(fid, 'Top 5 最优序列\n');
fprintf(fid, '================================================\n');
fprintf(fid, '%-6s  %-8s  %s\n', '排名', '适应度', '序列');
fprintf(fid, '%s\n', repmat('-', 1, 55));

for i = 1:length(results.best_fitness)
    fprintf('%-6d  %-8.4f  %s\n', i, results.best_fitness(i), results.best_sequences{i});
    fprintf(fid, '%-6d  %-8.4f  %s\n', i, results.best_fitness(i), results.best_sequences{i});
end

fclose(fid);
fprintf('\n详细记录已保存到: %s\n', report_file);

%% ========== 保存结果 ==========
save_file = sprintf('aptamer_results_%s.mat', timestamp);
save(save_file, 'results', 'params');
fprintf('结果已保存到: %s\n', save_file);

%% ========== 可视化 ==========
fprintf('\n正在生成可视化图表...\n');
visualize_results(results);

%% ========== 本地辅助函数 ==========

function [unique_seqs, unique_fitness] = remove_duplicates(sequences, fitness)
    n    = length(sequences);
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
    unique_seqs    = sequences(keep);
    unique_fitness = fitness(keep);
end
