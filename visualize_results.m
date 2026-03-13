function visualize_results(results)
%% 可视化优化结果
% 输入:
%   results - 结果结构体

%% 准备数据
all_fitness = [];
all_methods = {};

for i = 1:length(results.history)
    all_fitness = [all_fitness; results.history(i).fitness];
    n = length(results.history(i).fitness);
    all_methods = [all_methods; repmat({results.history(i).method}, n, 1)];
end

%% 创建图形窗口
figure('Position', [100, 100, 1200, 800], 'Name', '适配体序列优化结果');

%% 子图1: 适应度进化曲线
subplot(2, 2, 1);
plot(all_fitness, 'b-', 'LineWidth', 1.5);
hold on;

% 标记GA和ACO阶段
ga_indices = find(strcmp(all_methods, 'GA'));
aco_indices = find(strcmp(all_methods, 'ACO'));

if ~isempty(ga_indices)
    plot(ga_indices, all_fitness(ga_indices), 'ro', 'MarkerSize', 4);
end
if ~isempty(aco_indices)
    plot(aco_indices, all_fitness(aco_indices), 'gs', 'MarkerSize', 4);
end

xlabel('评估次数');
ylabel('适应度');
title('适应度进化曲线');
legend('所有评估', 'GA阶段', 'ACO阶段', 'Location', 'best');
grid on;

%% 子图2: 最优适应度趋势
subplot(2, 2, 2);
cummax_fitness = cummax(all_fitness);
plot(cummax_fitness, 'r-', 'LineWidth', 2);
xlabel('评估次数');
ylabel('最优适应度');
title('历史最优适应度趋势');
grid on;

%% 子图3: 适应度分布直方图
subplot(2, 2, 3);
histogram(all_fitness, 20, 'FaceColor', [0.3, 0.6, 0.9]);
xlabel('适应度');
ylabel('频数');
title('适应度分布');
grid on;

% 添加统计信息
mean_fit = mean(all_fitness);
std_fit = std(all_fitness);
text_str = sprintf('均值: %.2f\n标准差: %.2f', mean_fit, std_fit);
text(0.6, 0.9, text_str, 'Units', 'normalized', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

%% 子图4: Top 10序列对比
subplot(2, 2, 4);
n_display = min(10, length(results.best_fitness));
bar(results.best_fitness(1:n_display), 'FaceColor', [0.2, 0.7, 0.4]);
xlabel('序列排名');
ylabel('适应度');
title('Top 10 序列适应度对比');
grid on;
xticks(1:n_display);

%% 保存图形
saveas(gcf, 'optimization_results.png');
fprintf('可视化结果已保存到: optimization_results.png\n');

%% 额外图形：碱基组成分析
figure('Position', [150, 150, 1000, 600], 'Name', '碱基组成分析');

% 分析最优序列的碱基组成
n_analyze = min(5, length(results.best_sequences));
base_composition = zeros(n_analyze, 4); % A, T, G, C

for i = 1:n_analyze
    seq = results.best_sequences{i};
    base_composition(i, 1) = sum(seq == 'A') / length(seq);
    base_composition(i, 2) = sum(seq == 'T') / length(seq);
    base_composition(i, 3) = sum(seq == 'G') / length(seq);
    base_composition(i, 4) = sum(seq == 'C') / length(seq);
end

subplot(1, 2, 1);
bar(base_composition, 'grouped');
xlabel('序列排名');
ylabel('碱基比例');
title('Top 5 序列碱基组成');
legend('A', 'T', 'G', 'C', 'Location', 'best');
grid on;

% GC含量分析
subplot(1, 2, 2);
gc_content = (base_composition(:, 3) + base_composition(:, 4)) * 100;
bar(gc_content, 'FaceColor', [0.8, 0.4, 0.2]);
xlabel('序列排名');
ylabel('GC含量 (%)');
title('Top 5 序列GC含量');
grid on;
ylim([0, 100]);

% 添加最优GC含量线
hold on;
optimal_gc = mean(gc_content);
plot([0, n_analyze+1], [optimal_gc, optimal_gc], 'r--', 'LineWidth', 2);
legend('GC含量', sprintf('平均值 (%.1f%%)', optimal_gc), 'Location', 'best');

saveas(gcf, 'base_composition_analysis.png');
fprintf('碱基组成分析已保存到: base_composition_analysis.png\n');

end
