---
task_id: "20260509-custom-arm-software-framework"
task_name: "自定义机械臂 ROS2 软件框架（对标 el_a3_ros）"
owner: ""
status: "intake"
current_stage: "intake"
next_action: "评审 01-plan.md 后执行 confirm-plan；首版实现前创建 doc/arm_ros_stack/architecture.md"
priority: "P2"
blocked_reason: ""
due_date: ""
created_at: "2026-05-09"
updated_at: "2026-05-09"
# 产品路线已确认：A → B，全过程贯彻 D（见 Intake「已确认产品路线」）
---

# Task Card

## 生命周期状态机
- `intake` -> `planned` -> `implementing` -> `reviewing` -> `retrospecting` -> `done`
- 任意状态可转 `blocked`（阻塞解除后回到原状态继续）

## 任务目标
- **陈述**：已完成自有机械臂硬件设计与组装；拟以仓库内参考实现 `src/reference/EDULITE_A3/el_a3_ros` 为蓝图，搭建与硬件匹配的 ROS2 软件整体框架，并将大目标拆解为可执行子任务与验收点。
- **价值**：在统一栈（ros2_control、描述包、规划/遥操作可选分层）上形成可演进的骨架，避免后续功能在无边界的情况下堆叠。

## 约束与边界
- **已知约束**（负责人可补充）：
  - 参考栈：ROS 2 Humble 方向与 `el_a3_ros` 包边界一致（`*_hardware` / `*_description` / `*_moveit_config` / `*_teleop` 等），具体电机总线与驱动与自有硬件对齐时可能偏离 A3 的 CAN/Robstride 假设。
  - 仓库现状：`readme.md` 描述容器与镜像流程；自有「项目代码」目录在 intake 时尚未建立；参考代码在 `src/reference/EDULITE_A3/`。
- **阶段一非目标（Plan 可再收紧）**：量产级安全认证、完整产测流水线、商用 UI —— 默认不作为首版框架必达项。

## 验收标准
- **AC-01（文档）**：在 `01-plan.md` 中给出与本机硬件一致的 **软件分层图 + 包/仓库布局建议**（可对照 `el_a3_ros` 包矩阵），并列出 **≥8 条可指派子任务**，每条含输入/输出/依赖顺序。
- **AC-02（对标完整性）**：明确每个拟建包与参考包 `el_a3_hardware`、`el_a3_description`、`el_a3_moveit_config`、`el_a3_teleop` 的 **映射关系**（复用 /  fork 改 / 新建理由）及 **首版是否纳入** MoveIt2 / 遥操作。
- **AC-03（环境与可重复性）**：说明开发校验环境（本仓 `docker` 脚本、目标架构 amd64/arm64）与 **最小「能起控制器或仿真」成功路径**，即便首版仅为 mock hardware + URDF 也应写清命令级验收草案。
- **AC-04（待负责人确认栅格）**：任务卡中「仍待确认」表在 `plan-task` 后应闭合或显式带 **plan 默认假设**；**产品路线（A→B+D）已书面确认**；**owner** 仍须补全。

## 关键路径
- **代码路径**：
  - 参考 ROS2 栈：`src/reference/EDULITE_A3/el_a3_ros/`（含 README 包结构说明）。
  - 同源 SDK/工具：`src/reference/EDULITE_A3/el_a3_sdk/`（与 `el_a3_ros` 的交叉引用见 SDK 文档）。
  - 待建：建议落地于 `src/project/` 或与负责人约定的新根目录（在 `01-plan.md` 敲定）。
- **文档路径**：`readme.md`（环境与容器）；本任务 `agent_workspace/tasks/20260509-custom-arm-software-framework/`。

## 里程碑
- [x] Plan 完成（`01-plan.md`）
- [ ] Implement 完成（`02-implement.md`）
- [ ] Review 完成（`03-review.md`）
- [ ] Retro 完成（`04-retro.md`）

---

## Intake：证据锚定
- **相关文档**：`readme.md`；`src/reference/EDULITE_A3/README.md`；`src/reference/EDULITE_A3/el_a3_ros/README.md`、`ROS_INTERFACE_REFERENCE.md`（若存在）；`el_a3_hardware/HARDWARE_INTERFACE.md`。
- **相关代码/模块**：参考实现整树 `el_a3_ros/`；本仓库尚无独立「产品」ROS 包（需新建）。
- **本轮与证据的关系**：☑ 新建问题空间　☑ 以参考仓库为对比锚点落实骨架　□ 仅补充 SCM（主 SCM 不在本仓根目录时需后续衔接 `common_doc`）。

## Intake：深度理解（口号 → 可设计对象）
| 负责人用语 | 在机械臂软件语境中通常对应 |
|------------|---------------------------|
| 整体框架 | 包边界、launch 组合、控制与规划数据流、硬件抽象与 URDF 单一事实来源 |
| 参考 el_a3_ros | 包级模板 + ros2_control 生命周期 +（可选）MoveIt 与遥操作分层 |
| 与自有硬件对齐 | 关节数/限位/传动比、总线与驱动插件、标定与 URDF 参数同源策略 |

**综合推断（弱假设，请确认或推翻）**：
- ~~首版优先打通「描述 + ros2_control + …」~~ **已由负责人确认**：先做 **A（真机/控制闭环）**，再做 **B（仿真 + MoveIt）**；**D（工具链/SDK 与参数同源）** 在 A、B 全过程持续考虑（标定产物、xacro/ROS 参数工作流、与 `el_a3_sdk` 对齐的可选集成），不单列为「全部完成 A/B 之后才启动」的第三阶段。

## Intake：产品方案谱系（先选侧重点）

| 路线 | 一句话定位 | 最匹配的侧重点 | 通常付出的代价 | 第一版验收叙事 |
|------|------------|----------------|----------------|----------------|
| A. 控制闭环优先 | 先跑通 `ros2_control` + 真实/半真实驱动最小集 | 短时间内在机台上能动、能录包 | 规划/示教功能滞后 | 能在指定 launch 下 broadcast joint_states 并跟踪轨迹 |
| B. 仿真与 MoveIt 优先 | mock hardware + MoveIt + RViz 交互规划 | 算法与任务空间大、依赖少硬件 | 与真机差异需二次集成 | demo launch 内完成规划—执行闭环 |
| C. 遥操作与示教优先 | 手柄/外部指令笛卡尔或关节增量 | 人机调试快 | 安全与标定要求高，易堆技术债 | 定义清晰的 teleop 话题契约与安全限速 |
| D. 工具链/SDK 一体 | 对齐 `el_a3_sdk` 标定与诊断工具 | 参数与文档同源 | 工程量大、边界扩张 | 标定产出可自动生成 xacro/ros 参数片段 |

**侧重点速配**：
- 若最在乎 **尽快上真机验证机械与电气** → 倾向 **A**。
- 若最在乎 **算法/任务先期不依赖硬件** → 倾向 **B**。
- 若最在乎 **调试与数据采集体验** → 倾向 **C**（常需与 A 组合）。
- 若最在乎 **长期可维护与参数工作流** → 在 A/B 基础上加 **D** 的元素。

### 已确认产品路线

| 字段 | 内容 |
|------|------|
| **选型** | **A + B + D**（不选 C：遥操作示教非当前主线；若后续需要再增列） |
| **阶段顺序** | **先 A**：真机侧 `ros2_control` + 驱动最小集 + joint 命令/状态可观测；**再 B**：mock/仿真侧 MoveIt + RViz（或等价）规划—执行闭环；**D 横切**：自 A 起规划参数与标定工件如何进入 URDF/xacro、controller YAML 及可选 `el_a3_sdk` 工具链，避免「手改参数」与文档漂移。 |
| **对产品含义** | 第一版对外叙事先强调「能上电、能控、能录包/验收轨迹」；第二阶段补齐「不依赖实机也能做任务与算法验证」；全程保留「标定/诊断产出 → 版本化配置」的挂钩点。 |
| **隐含优先级** | A 闭环未完成前，B 可走并行工程但 **验收顺序**以 A 为先；D 不要求一次性做满 SDK 全部能力，但 plan 须写明 **最小 D 契约**（例如惯量/限位/链路的导出路径）。 |

## Intake：工程命题（收窄，含 Plan 默认）

**Plan 侧默认**（与已确认 A→B+D 对齐；细节可在 `plan-task` 中改写）：
1. ROS 发行版按本仓容器/README 对齐 **Humble**；工作空间布局参考 `el_a3_ros` 多包 colcon 工程。
2. **阶段 A**：**description 包（URDF/xacro）** + **hardware 最小可用实现** + **controllers YAML 与 control launch**，验收贴近「实机或指定硬件路径下 joint_states + 轨迹跟随」；**阶段 B**：在 mock/sim 上建立 **MoveIt 配置包** 与 demo/robot launch，验收贴近「规划—执行闭环」。
3. **D（横切）**：在 A、B 各工作包中定义 **参数同源**（标定/工具导出 → xacro 片段或 YAML 生成步骤），对标参考仓库中 SDK 与 `inertia_params.yaml`、标定脚本等模式，规模可最小化但接口要可扩展。
4. 自有硬件与 A3 不一致处：**新包名/主题前缀** 与 A3 解耦；能从参考包 **拷贝改名** 的尽量模板化并维护 **差异表**。
5. 文档验收以本任务 `01-plan.md` + 后续 `doc/` 或包内 README 片段为准（不强制扩张 `readme.md` 除非负责人要求）。

### 负责人已确认

| # | 命题 | 答复 | Plan 解读 |
|---|------|------|-----------|
| 1 | 首版必选路线（A/B/C/D 或组合） | **A、B、D**；顺序 **先 A 后 B**；**D 在过程中持续考虑** | 实施计划按 **两主阶段（A→B）+ D 横切** 组织：里程碑 1=A，里程碑 2=B；工作拆分时每条任务标注是否含 D 产出（参数/工具链挂钩）。**不包含 C** 除非另行通知。 |
| 2 | 电机/总线与 A3 是否同类 | _仍待负责人书面确认_ | **Plan 默认**：按 **不同类** 规划 T5（见 `01-plan.md`）；若确认同类可收敛为「适配层为主、少重写」 |
| 3 | 目标上位系统（仅 ROS CLI / MoveIt / 自研 UI） | _仍待确认_（B 含 MoveIt；是否还要自研 UI 未定） | |

### 仍待确认
- 负责人 **owner**。
- 硬件 **DOF / 总线 / 驱动** 与 A3 差异的**书面确认**（当前工程假设见 `01-plan.md`「Plan 默认假设」）。
- 首版是否必须 **实机** 验收：plan 采用 **A 默认真机、B 可无实机**；若需调整，在评审 plan 时推翻。

### 已收敛至 Plan（查阅 `01-plan.md`）
- URDF/CAD、IK、多臂/工具等开放题：`01-plan.md` →「仍待确认项 → Plan 默认假设」。

## Intake：开放问题（在 `01-plan.md` 收敛）
- 已写入 `01-plan.md`「Plan 默认假设」；若负责人推翻默认，请同步修订 `architecture.md` 修订记录。

## Intake：风险与待确认
- **风险**：硬件与 A3 驱动模型差异导致 **hardware_interface 无法直接移植**，工期集中在底层驱动与标定而非「框架搭壳」。
- **待指派**：`owner` 字段目前为空，需在 plan 确认前指定责任人。

## 执行日志
| 时间 | 事件 | 操作人 | 说明 |
|------|------|--------|------|
| 2026-05-09 | create-task | agent | 初始化任务目录与索引；intake 按 Researcher v1.1 分层写入任务卡 |
| 2026-05-09 | 确认产品路线 | owner（聊天记录） | 选型 A+B+D；顺序先 A 后 B；D 在 A/B 过程中贯彻（非「最后才做」的独立尾段） |
| 2026-05-09 | plan-task | agent | 归档 `01-plan.md`：分层图、10 子任务 T1–T10、`el_a3_*` 映射、环境/A·B 最小路径、R1–R3 取舍 |

## 最终结论
- _任务完成后填写_
