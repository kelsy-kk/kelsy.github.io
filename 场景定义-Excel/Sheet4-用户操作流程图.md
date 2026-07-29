# 场景定义 · 用户操作流程图

> 数据来源：`Sheet4-用户操作逻辑.csv`  
> 对应原型：`业务流程产品原型/index.html` · 场景定义模块

---

## 总览：四条用户路径

```mermaid
flowchart TB
    subgraph entry [入口]
        E1[二级导航 · 场景定义]
        E2[Hub · 新建流程]
    end

    subgraph pathA [路径 A · 浏览与选用预置场景]
        A1[场景定义列表页]
        A2[场景流程开发]
        A3[流程开发工作台]
    end

    subgraph pathB [路径 B · 创建自定义场景]
        B1[新建业务场景]
        B2[编辑页组装模块]
        B3[保存模板]
        B4[列表页 / 可共享态]
    end

    subgraph pathC [路径 C · 管理已有自定义场景]
        C1[自定义场景卡片]
        C2[编辑 / 上下线]
        C3[场景流程开发]
    end

    subgraph pathD [路径 D · 从新建流程选用场景]
        D1[选择模板弹窗]
        D2[流程开发工作台]
    end

    E1 --> A1
    E1 --> B1
    E1 --> C1
    E2 --> D1

    A1 --> A2 --> A3
    B1 --> B2 --> B3 --> B4
    C1 --> C2
    C2 --> C3 --> A3
    D1 --> D2
    B4 -.可选.-> D1
    A1 -.路径 A.-> A2
```

---

## 路径 A · 浏览与选用预置场景

| 步骤 | 用户操作 | 系统响应 | 结果状态 |
|------|----------|----------|----------|
| 1 | 点击二级导航「场景定义」 | 打开列表页，展示引导 + 预置 + 自定义 | 浏览态 |
| 2 | （可选）输入搜索词 | 过滤卡片 | 浏览态 |
| 3 | 点击预置卡片「场景流程开发」 | `startNewFlowFromModuleTemplate` 进入工作台 | 流程开发态 |
| 4 | 在工作台操作 | 左侧首模块选中，右侧展示操作流程分段 | 流程开发态 |

```mermaid
flowchart TD
    Start([开始]) --> S1[点击二级导航「场景定义」]
    S1 --> R1[系统：打开列表页<br/>展示引导区 + 预置场景 + 自定义场景]
    R1 --> StateBrowse1((浏览态))

    StateBrowse1 --> S2{是否搜索?}
    S2 -->|是| S2a[输入搜索词]
    S2a --> R2a[系统：实时过滤卡片]
    R2a --> StateBrowse1
    S2 -->|否| S3

    S3[点击预置卡片「场景流程开发」]
    S3 --> R3[系统：startNewFlowFromModuleTemplate<br/>初始化 devPath / opFlowVisitStack]
    R3 --> StateDev((流程开发态))

    StateDev --> S4[在工作台按场景路径操作]
    S4 --> R4[系统：左侧选中首模块<br/>右侧展示大模块分段 + 小操作步骤]
    R4 --> StateDev

    style StateBrowse1 fill:#f5f7fa,stroke:#667085
    style StateDev fill:#e6f7ff,stroke:#1677ff
    style S3 fill:#2563eb,color:#fff
```

---

## 路径 B · 创建自定义场景

| 步骤 | 用户操作 | 系统响应 | 结果状态 |
|------|----------|----------|----------|
| 1 | 点击「+ 新增业务场景」 | 进入空白编辑页 | 编辑态 |
| 2 | 左栏点击操作 chip | 右侧追加；同 leafId 不可重复 | 编辑态 |
| 3 | （可选）大模块 ↑↓ | 整组与相邻大模块交换 | 编辑态 |
| 4 | （可选）小操作 × | 移除该操作；左栏 chip 恢复可点 | 编辑态 |
| 5 | 填写名称、描述，选择上线/下线 | 表单赋值 | 编辑态 |
| 6 | 点击「保存模板」 | 校验 → 写 localStorage → 回列表 Toast | 列表态 |
| 7 | （可选）点击「上线」 | 新建流程弹窗可见该场景 | 可共享态 |

```mermaid
flowchart TD
    Start([开始]) --> S1[点击「新建业务场景」<br/>或「+ 新增业务场景」]
    S1 --> R1[系统：进入空白编辑页<br/>centerOverride = template-editor]
    R1 --> StateEdit((编辑态))

    StateEdit --> S2[左栏点击操作 chip]
    S2 --> R2{同 leafId 下<br/>是否已存在?}
    R2 -->|是| ToastDup[Toast：不可重复添加]
    ToastDup --> StateEdit
    R2 -->|否| R2ok[系统：右侧流程预览追加操作<br/>左栏 chip 禁用]
    R2ok --> StateEdit

    StateEdit --> Opt1{调整顺序?}
    Opt1 -->|大模块 ↑↓| R3[系统：moveGroup 整组换位]
    R3 --> StateEdit
    Opt1 -->|小操作 ×| R4[系统：移除单条操作]
    R4 --> StateEdit
    Opt1 -->|否| S5

    S5[填写场景名称 / 描述<br/>选择上线或下线胶囊]
    S5 --> StateEdit

    StateEdit --> S6[点击「保存模板」]
    S6 --> V1{校验通过?<br/>名称非空且 ≥1 模块}
    V1 -->|否| ToastErr[Toast 提示错误]
    ToastErr --> StateEdit
    V1 -->|是| R6[系统：saveCustomTemplate<br/>写 bp_custom_flow_templates_v1]
    R6 --> R6b[返回列表页 + 成功 Toast]
    R6b --> StateList((列表态))

    StateList --> Opt2{是否上线?}
    Opt2 -->|点击「上线」| R7[系统：published = true]
    R7 --> StateShare((可共享态))
    Opt2 -->|保持下线| StateList

    StateShare --> R8[新建流程弹窗可见该场景<br/>卡片显示「场景流程开发」]
    StateShare --> End([结束 / 可进入路径 C 或 D])

    style StateEdit fill:#fff7e6,stroke:#d48806
    style StateList fill:#f5f7fa,stroke:#667085
    style StateShare fill:#e6f7ff,stroke:#1677ff
    style S6 fill:#2563eb,color:#fff
```

---

## 路径 C · 管理已有自定义场景

| 步骤 | 用户操作 | 系统响应 | 结果状态 |
|------|----------|----------|----------|
| 1 | 列表找到自定义卡片 | 展示徽标、创建人、时间、开发思路 | 浏览态 |
| 2 | 点击「编辑」 | 回填名称、描述、模块顺序、上线状态 | 编辑态 |
| 3 | 点击「下线」 | published=false，按钮变「上线」 | 已下线 |
| 4 | 点击「上线」 | published=true，显示「场景流程开发」 | 已上线 |
| 5 | 已上线时点击「场景流程开发」 | 进入工作台 | 流程开发态 |

```mermaid
flowchart TD
    Start([开始]) --> S1[在列表找到自定义场景卡片]
    S1 --> R1[系统：展示状态徽标<br/>创建人｜时间｜开发思路链路]
    R1 --> StateBrowse((浏览态))

    StateBrowse --> Branch{用户操作}

    Branch -->|编辑| S2[点击「编辑」]
    S2 --> R2[系统：goToTemplateEditor<br/>回填名称 / 描述 / 模块 / 上线状态]
    R2 --> StateEdit((编辑态))
    StateEdit --> SaveOrCancel{保存或取消}
    SaveOrCancel -->|保存| R2b[写 localStorage 回列表]
    SaveOrCancel -->|取消| R2c[不保存回列表]
    R2b --> StateBrowse
    R2c --> StateBrowse

    Branch -->|下线| S3[点击「下线」]
    S3 --> R3[系统：setCustomTemplatePublished false]
    R3 --> R3b[隐藏「场景流程开发」<br/>新建流程弹窗不展示]
    R3b --> StateOff((已下线))

    Branch -->|上线| S4[点击「上线」]
    S4 --> R4[系统：setCustomTemplatePublished true]
    R4 --> R4b[显示「场景流程开发」按钮]
    R4b --> StateOn((已上线))

    Branch -->|复制| SCopy[点击「复制」]
    SCopy --> RCopy[系统：duplicateCustomTemplate<br/>生成「副本 · 名称」]
    RCopy --> StateBrowse

    StateOff --> StateBrowse
    StateOn --> S5{点击场景流程开发?}
    S5 -->|是| R5[系统：startNewFlowFromCustomTemplate]
    R5 --> StateDev((流程开发态))
    S5 -->|否| StateBrowse

    StateDev --> End([结束])

    style StateBrowse fill:#f5f7fa,stroke:#667085
    style StateEdit fill:#fff7e6,stroke:#d48806
    style StateOff fill:#fff7e6,stroke:#d48806
    style StateOn fill:#e6f7ff,stroke:#1677ff
    style StateDev fill:#e6f7ff,stroke:#1677ff
```

---

## 路径 D · 从新建流程选用场景

| 步骤 | 用户操作 | 系统响应 | 结果状态 |
|------|----------|----------|----------|
| 1 | Hub 页点击「新建流程」 | 打开「选择模板」弹窗 | 弹窗态 |
| 2 | 选择预置或已上线自定义卡片 | `startNewFlowFromModuleTemplate` | 流程开发态 |
| 3 | 进入工作台 | 操作流程按场景分组展示 | 流程开发态 |

```mermaid
flowchart TD
    Start([开始 · Hub 工作台]) --> S1[点击「新建流程」]
    S1 --> R1[系统：打开 bpNewFlowBackdrop 弹窗<br/>标题「新建流程 · 选择模板」]
    R1 --> StateModal((弹窗态))

    StateModal --> R1b[弹窗展示：<br/>全部预置场景 + 已上线自定义场景]
    R1b --> S2[用户选择场景卡片]
    S2 --> R2[系统：startNewFlowFromModuleTemplate<br/>关闭弹窗]
    R2 --> R2b[初始化 opFlowModuleLeafIds<br/>devPathFlowState / opFlowVisitStack]
    R2b --> StateDev((流程开发态))

    StateDev --> S3[在工作台操作]
    S3 --> R3[系统：左侧操作导航<br/>右侧操作流程按 leafId 大模块分段]
    R3 --> Note[各阶段可跳跃、可多次实例化<br/>不强制按顺序执行]
    Note --> StateDev

    style StateModal fill:#f9f0ff,stroke:#722ed1
    style StateDev fill:#e6f7ff,stroke:#1677ff
    style S1 fill:#2563eb,color:#fff
```

---

## 状态机总图（结果状态流转）

```mermaid
stateDiagram-v2
    [*] --> 浏览态: 进入场景定义列表

    浏览态 --> 编辑态: 新建 / 编辑自定义场景
    浏览态 --> 弹窗态: Hub · 新建流程
    浏览态 --> 流程开发态: 预置 · 场景流程开发

    编辑态 --> 列表态: 保存模板
    编辑态 --> 浏览态: 取消 / 返回

    列表态 --> 可共享态: 上线
    列表态 --> 浏览态: 停留列表

    可共享态 --> 浏览态: 下线
    可共享态 --> 弹窗态: 新建流程可选用

    浏览态 --> 已下线: 自定义场景 · 下线
    浏览态 --> 已上线: 自定义场景 · 上线
    已下线 --> 已上线: 上线
    已上线 --> 已下线: 下线
    已上线 --> 流程开发态: 场景流程开发

    弹窗态 --> 流程开发态: 选择模板
    流程开发态 --> [*]: 完成 / 退出工作台
```

---

## 使用说明

| 文件 | 说明 |
|------|------|
| `Sheet4-用户操作逻辑.csv` | Excel 原始步骤表 |
| 本文档 | Mermaid 流程图，可在 VS Code / Cursor / GitHub 中预览 |
| 在线渲染 | 复制代码块到 [Mermaid Live Editor](https://mermaid.live) 可导出 PNG/SVG |

### 导出为图片（可选）

```bash
# 需安装 @mermaid-js/mermaid-cli
npx @mermaid-js/mermaid-cli -i flow.mmd -o flow.png
```
