# 🧬 Aptamer GA-ACO Optimizer

> 基于**混合遗传算法（GA）+ 蚁群算法（ACO）** 的核酸适配体序列优化框架  
> A hybrid Genetic Algorithm + Ant Colony Optimization framework for DNA/RNA aptamer sequence design

---

## 📌 项目背景

核酸适配体（Aptamer）是一类能与靶标分子高亲和力结合的单链寡核苷酸，广泛应用于生物传感、靶向治疗和食品安全快速检测领域。传统筛选方法（SELEX）耗时长、成本高，本项目提出一种**计算机辅助的适配体序列优化方法**，将进化算法与分子对接实验相结合，在有限实验次数内快速收敛至高亲和力序列。

> This project is part of my Master's research on **computer-aided aptamer design** at Xiangtan University, focusing on integrating computational optimization with wet-lab validation (molecular docking → fluorescence spectroscopy → circular dichroism).

---

## 🔬 方法框架

```
初始种群（基于种子序列突变生成）
        │
        ▼
┌───────────────────────────────┐
│     GA 遗传算法模块            │
│  锦标赛选择 → 单点交叉 → 点变异 │
│  精英保留策略                  │
└──────────────┬────────────────┘
               │ Top-N 序列
               ▼
┌───────────────────────────────┐
│     ACO 蚁群算法模块           │
│  信息素矩阵更新（位置×碱基）    │
│  启发式信息 + 信息素挥发        │
└──────────────┬────────────────┘
               │
               ▼
       循环 N 轮（GA-ACO 交替）
               │
               ▼
        最优候选序列集合
               │
               ▼
   分子对接验证 / 荧光实验表征
```

**适应度评估采用人机交互模式**：程序每轮暂停，等待用户输入分子对接（Autodock Vina）打分结果作为适应度值，再继续下一轮优化。这样设计的目的是将计算优化与实验验证紧密耦合，避免纯计算筛选与实际结合性能脱节。

---

## 📁 文件结构

```
matlab/
├── main_aptamer_optimizer.m       # 主程序入口，参数配置 & 混合优化主循环
├── genetic_algorithm_aptamer.m    # GA模块：选择、交叉、变异、精英保留
├── ant_colony_optimizer.m         # ACO模块：信息素矩阵、概率采样、信息素更新
├── evaluate_fitness_universal.m   # 适应度评估接口（支持手动/批量两种模式）
├── batch_mode_generator.m         # 批量序列生成工具（用于一次性提交对接任务）
├── load_batch_fitness.m           # 批量读取对接结果并导入适应度数组
├── demo_with_simulated_fitness.m  # 使用模拟适应度的完整演示（无需实验数据可直接运行）
└── visualize_results.m            # 结果可视化：适应度收敛曲线、序列多样性分析
```

---

## ⚙️ 核心算法参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `pop_size` | 20 | GA 种群大小 |
| `generations` | 10 | 每轮 GA 迭代代数 |
| `crossover_rate` | 0.8 | 单点交叉概率 |
| `mutation_rate` | 0.1 | 点变异概率（每个碱基位点） |
| `elite_count` | 2 | 精英保留数量 |
| `ant_count` | 15 | 每轮蚂蚁数量 |
| `aco_iterations` | 5 | ACO 迭代次数 |
| `rho` | 0.3 | 信息素挥发率 |
| `hybrid.ga_cycles` | 3 | GA-ACO 交替循环总轮数 |

---

## 🚀 快速开始

### 环境要求
- MATLAB R2019b 及以上（无需额外工具箱）

### 运行演示（无需实验数据）
```matlab
% 使用模拟适应度函数直接运行，观察算法收敛行为
demo_with_simulated_fitness
```

### 接入真实实验数据
```matlab
% 1. 修改 main_aptamer_optimizer.m 中的种子序列
params.AF26 = 'YOUR_SEED_SEQUENCE';  % 替换为你自己的种子序列

% 2. 运行主程序
main_aptamer_optimizer

% 3. 程序暂停时，将分子对接打分结果（如 Autodock Vina binding energy）
%    转换为适应度值（取负值或线性变换），逐条输入即可
```

### 批量模式（推荐用于大规模筛选）
```matlab
% Step 1: 生成一批候选序列，导出为 FASTA 格式提交对接任务
batch_mode_generator

% Step 2: 对接完成后，将结果写入 CSV，批量导入
load_batch_fitness('docking_results.csv')
```

---

## 📊 算法特性

- **混合策略**：GA 负责全局搜索（交叉变异探索序列空间），ACO 负责局部精细化（在高适应度区域集中采样），两者互补
- **精英保留**：每代保留 top-N 个体，确保已发现的优质序列不丢失
- **人机耦合**：适应度由真实分子对接实验提供，避免代理模型误差积累
- **可扩展性**：`evaluate_fitness_universal.m` 提供统一接口，可替换为任意打分函数（AutoDock、Vina、FTMap 等）

---

## 🔗 相关工具链

本框架在实际课题中与以下工具配合使用：

| 工具 | 用途 |
|------|------|
| AutoDock Vina | 分子对接打分（适应度来源） |
| Gromacs（GPU版） | 分子动力学模拟验证 |
| PyMOL / VMD | 对接结果可视化 |
| 荧光光谱仪 | 实验表征（Kd值测定） |
| 圆二色谱（CD） | 适配体二级结构验证 |

---

## 📝 说明

- 种子序列因对应课题文章尚未发表，暂以占位符替代，不影响算法运行逻辑
- 如需复现完整实验结果，请在文章发表后联系作者
- `demo_with_simulated_fitness.m` 使用模拟函数，可完整运行并观察收敛过程

---

## 👤 作者

**冉康银** | 湘潭大学化工学院 食品科学与工程（硕士）  
研究方向：基于计算机辅助的核酸适配体设计  
Email：2644760453@qq.com
