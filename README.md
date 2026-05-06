# MvvmDemoApp

一个基于 `SwiftUI + MVVM` 的示例项目，用于演示用户信息与 Banner 列表的加载、缓存、错误处理和依赖注入。

## 项目特性

- 使用 `MVVM` 分层组织视图、状态和数据访问逻辑
- 使用 `Moya` 统一封装网络请求
- 使用 `UserDefaults` 做本地缓存
- 支持缓存过期控制（TTL）
- 支持下拉式刷新逻辑中的强制刷新
- 网络失败时优先回退到旧缓存，降低页面完全失败的概率
- 刷新失败时保留已有内容，避免整页被错误态覆盖

## 项目结构

```text
MVVMDemoApp
├── App
│   ├── MVVMDemoApp.swift
│   └── AppEnvironment.swift
├── Models
│   ├── User.swift
│   └── Banner.swift
├── Networking
│   ├── DemoAPI.swift
│   └── NetworkProvider.swift
├── Repositories
│   ├── UserRepository.swift
│   └── BannerRepository.swift
├── Storage
│   ├── UserStorage.swift
│   └── BannerStorage.swift
├── Support
│   ├── AppError.swift
│   └── CachedEntry.swift
├── ViewModels
│   ├── UserViewModel.swift
│   └── BannerViewModel.swift
├── Views
│   ├── ContentView.swift
│   ├── ErrorStateView.swift
│   └── EmptyStateView.swift
└── Resources
    └── Assets.xcassets
```

## 架构说明

### 1. View

`ContentView` 负责页面展示和交互，不直接处理网络或缓存逻辑。  
界面通过 `UserViewModel` 和 `BannerViewModel` 驱动，按照以下优先级渲染：

- 首次加载且无数据时显示加载态
- 有数据时优先显示内容
- 无数据且失败时显示错误态
- 无数据且无错误时显示空态

### 2. ViewModel

`UserViewModel` 和 `BannerViewModel` 负责：

- 管理页面状态，如 `isLoading`、`errorMessage`
- 调用 Repository 拉取数据
- 处理刷新逻辑
- 忽略取消请求带来的无效错误提示

### 3. Repository

`UserRepository` 和 `BannerRepository` 负责协调网络与缓存：

- 优先读取有效缓存
- 强制刷新时跳过有效缓存
- 网络成功后写入本地缓存
- 网络失败时尝试回退到过期缓存

### 4. Storage

`UserStorage` 和 `BannerStorage` 使用 `UserDefaults` 持久化缓存数据，借助 `CachedEntry` 保存：

- 实际业务数据
- 缓存写入时间

并通过 TTL 判断缓存是否过期。

### 5. Networking

`NetworkProvider` 对 `MoyaProvider` 做了异步封装，统一负责：

- 发起请求
- 解码返回模型
- 错误映射
- 将 Swift 并发任务取消传递到底层网络请求

## 当前示例数据

项目内 `DemoAPI` 使用 `sampleData` 提供示例返回，便于本地演示：

- 用户信息接口：`/api/user`
- Banner 列表接口：`/api/banners`

默认 `NetworkProvider` 使用 `MoyaProvider.immediatelyStub`，因此项目可直接本地运行，不依赖真实服务端。

## 运行方式

## 环境要求

- Xcode
- iOS SwiftUI 运行环境

## 启动步骤

1. 使用 Xcode 打开 `MVVMDemoApp.xcodeproj`
2. 选择模拟器或真机
3. 运行项目

## 关键实现说明

### 刷新策略

点击页面右上角“刷新”按钮时：

- 用户信息和 Banner 会同时触发 `forceRefresh`
- 如果请求成功，界面更新为最新数据
- 如果请求失败，但本地仍有旧缓存，界面继续展示旧内容

### 缓存策略

- 默认缓存 TTL 为 `1800` 秒
- TTL 内优先直接返回缓存
- TTL 过期后请求网络
- 若网络失败，则尝试回退到旧缓存

### 错误处理

统一使用 `AppError` 表达错误类型：

- `network`
- `storage`
- `invalidData`
- `cancelled`

## 后续可扩展方向

- 接入真实后端 API
- 将缓存层替换为数据库或文件存储
- 为 Repository 和 ViewModel 增加单元测试
- 增加 Banner 图片加载与点击跳转能力
- 引入更完整的日志与监控能力
