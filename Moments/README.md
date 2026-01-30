# Moments

一个轻量级的个人想法记录工具，支持文字+图片+标签，数据同步至博客。

## 技术栈

- **UI**: SwiftUI
- **架构**: MVVM
- **最低版本**: iOS 17.0+
- **依赖**: Kingfisher (图片加载)

## 快速开始

### 1. 在 Xcode 中创建项目

1. 打开 Xcode，选择 **File → New → Project**
2. 选择 **iOS → App**
3. 填写项目信息：
   - **Product Name**: `Moments`
   - **Team**: 选择你的开发者账号
   - **Organization Identifier**: `cc.lucky` (或你自己的)
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`
4. 选择保存位置为 `/Users/zqqcee/Projects/moment` 的**上级目录**
5. 创建项目

### 2. 导入源代码

1. 删除 Xcode 自动生成的 `ContentView.swift` 和 `MomentsApp.swift`
2. 将 `Moments/` 文件夹下的所有文件拖入 Xcode 项目
3. 确保选中 "Copy items if needed" 和 "Create groups"

### 3. 添加 Kingfisher 依赖

1. 在 Xcode 中选择 **File → Add Package Dependencies**
2. 输入包地址: `https://github.com/onevcat/Kingfisher`
3. 选择版本规则: **Up to Next Major Version** (7.0.0)
4. 点击 **Add Package**

### 4. 配置项目

1. 在项目设置中，将 **iOS Deployment Target** 设置为 **17.0**
2. 将 `Info.plist` 添加到项目中
3. 将 `Assets.xcassets` 添加到项目中

### 5. 运行

选择模拟器或真机，点击运行按钮即可。

## 项目结构

```
Moments/
├── MomentsApp.swift              # App入口
├── ContentView.swift             # 根视图
├── Models/                       # 数据模型
│   ├── Thought.swift
│   ├── APIResponse.swift
│   └── AppError.swift
├── ViewModels/                   # 业务逻辑
│   ├── ThoughtListViewModel.swift
│   └── ComposeViewModel.swift
├── Views/                        # UI组件
│   ├── ThoughtList/
│   ├── Compose/
│   ├── Detail/
│   ├── Tags/
│   └── Common/
├── Services/                     # API调用
│   ├── APIClient.swift
│   ├── ThoughtService.swift
│   └── MockDataProvider.swift
├── Utils/                        # 工具函数
│   ├── HapticManager.swift
│   └── ImageCompressor.swift
└── Resources/                    # 资源文件
    └── Assets.xcassets
```

## 功能列表

| 功能 | 状态 | 说明 |
|------|------|------|
| 浏览列表 | ✅ | 时间倒序，下拉刷新，上拉加载 |
| 发布想法 | ✅ | 文字+图片(最多9张)+标签 |
| 查看详情 | ✅ | 图片大图浏览 |
| 删除想法 | ✅ | 左滑删除，二次确认 |
| 标签筛选 | ✅ | 按标签过滤列表 |
| 编辑想法 | ✅ | 修改文字/图片/标签 |

## 后续工作

1. **对接真实 API**: 修改 `APIClient.swift` 中的 `baseURL`
2. **图片上传**: 实现 OSS 直传功能
3. **用户认证**: 实现登录功能，存储 Token 到 Keychain

## 开发说明

当前使用 Mock 数据进行开发，所有数据保存在内存中。要切换到真实 API：

1. 在 `ThoughtListViewModel` 中将 `MockThoughtService()` 替换为 `ThoughtService()`
2. 配置 `APIClient` 的 `baseURL` 和认证 Token
