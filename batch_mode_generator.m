%% 批量评估模式 - 适配体序列优化
% 该脚本允许您预先准备适应度数据，避免在优化过程中频繁输入
% 使用方法：
% 1. 运行此脚本生成待评估序列
% 2. 进行分子对接实验
% 3. 在fitness_data.txt中填写适应度值
% 4. 运行主程序继续优化

clear; clc;

%% 生成待评估序列
fprintf('========================================\n');
fprintf('批量评估模式 - 序列生成\n');
fprintf('========================================\n\n');

% 参数设置
seq_length = 40;
bases = ['A', 'T', 'G', 'C'];
num_sequences = input('请输入要生成的序列数量（建议20-50）: ');

% 生成随机序列
sequences = cell(num_sequences, 1);
for i = 1:num_sequences
    idx = randi(length(bases), 1, seq_length);
    sequences{i} = bases(idx);
end

%% 导出序列到文件
output_file = 'sequences_to_evaluate.txt';
fid = fopen(output_file, 'w');
fprintf(fid, '待评估适配体序列列表\n');
fprintf(fid, '生成时间: %s\n', datestr(now));
fprintf(fid, '序列长度: %d\n', seq_length);
fprintf(fid, '序列数量: %d\n\n', num_sequences);
fprintf(fid, '序列编号\t序列\n');
fprintf(fid, '============================================\n');

for i = 1:num_sequences
    fprintf(fid, '%d\t%s\n', i, sequences{i});
end

fclose(fid);
fprintf('\n序列已导出到: %s\n', output_file);

%% 创建适应度数据模板
template_file = 'fitness_data_template.txt';
fid = fopen(template_file, 'w');
fprintf(fid, '适应度数据文件\n');
fprintf(fid, '说明: 请在每个序列后面填写其适应度值（0-100）\n');
fprintf(fid, '格式: 序列编号 序列 适应度值\n\n');

for i = 1:num_sequences
    fprintf(fid, '%d\t%s\t\n', i, sequences{i});
end

fclose(fid);
fprintf('适应度模板已创建: %s\n', template_file);

%% 保存序列数据
save('batch_sequences.mat', 'sequences', 'seq_length', 'bases');
fprintf('\n序列数据已保存到: batch_sequences.mat\n');

fprintf('\n========================================\n');
fprintf('下一步操作：\n');
fprintf('1. 对 %s 中的序列进行分子对接实验\n', output_file);
fprintf('2. 在 %s 中填写适应度值\n', template_file);
fprintf('3. 运行 load_batch_fitness.m 加载数据\n');
fprintf('4. 运行主优化程序\n');
fprintf('========================================\n');
