# Moments iOS App

个人想法发布工具，支持文字+图片+标签，数据同步至博客。

## 技术栈

* **UI** : SwiftUI
* **架构** : MVVM
* **最低版本** : iOS 17.0+
* **依赖** : Kingfisher (图片加载)

## 项目结构

```
Moments/
├── MomentsApp.swift              # App入口
├── ContentView.swift             # 根视图
├── Models/                       # 数据模型
├── ViewModels/                   # 业务逻辑
├── Views/                        # UI组件
├── Services/                     # API调用
├── Utils/                        # 工具函数
└── Resources/                    # 资源文件
```

## 数据模型

```swift
struct Thought: Codable, Identifiable {
    let id: String                    // MongoDB ObjectId
    var content: String
    var images: [ThoughtImage]
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var visibility: Visibility?       // .public | .private | .unlisted
}

struct ThoughtImage: Codable {
    let url: String
    let width: Int
    let height: Int
    var blurhash: String?
}

enum Visibility: String, Codable {
    case `public` = "public"
    case `private` = "private"
    case unlisted = "unlisted"
}
```

## 核心功能

| 功能     | 优先级 | 说明                         |
| -------- | ------ | ---------------------------- |
| 发布想法 | P0     | 文字+图片(最多9张)+标签      |
| 浏览列表 | P0     | 时间倒序，下拉刷新，上拉加载 |
| 查看详情 | P0     | 图片大图浏览                 |
| 删除想法 | P0     | 左滑删除，二次确认           |
| 编辑想法 | P1     | 修改文字/图片/标签           |
| 标签筛选 | P1     | 按标签过滤列表               |

## 图片处理规则

上传前在 iOS 端压缩：

* 宽度 > 1920px 时等比缩放至 1920px
* JPEG 压缩质量 0.8
* 获取压缩后尺寸信息

## UX 要求

* **触觉反馈** : 发布成功、删除确认、标签选择时触发 Haptic
* **动画** : 列表项淡入、删除滑出、图片渐显
* **手势** : 下拉刷新、左滑删除、图片捏合缩放
* **深色模式** : 自动跟随系统

## 图片布局规则

* 1张: 宽度占满，高度自适应(最大300pt)
* 2张: 并排 1:1
* 3张: 左1大右2小
* 4张: 2x2 网格
* 5-9张: 3列网格

## 前端概念映射

| 前端       | SwiftUI                  |
| ---------- | ------------------------ |
| useState   | @State                   |
| useContext | @Environment             |
| useEffect  | .onAppear / .task        |
| fetch      | URLSession + async/await |
| map 渲染   | ForEach                  |
| Flexbox    | VStack / HStack          |
| onClick    | Button / .onTapGesture   |

## 代码规范

* 使用 `@Observable` 管理 ViewModel 状态
* 网络请求统一用 async/await
* 敏感数据存 Keychain，普通配置存 UserDefaults
* 组件拆分粒度参考：单个文件不超过 200 行

## 详细 PRD

见 `docs/PRD.md`
