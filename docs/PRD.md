# PRD: 个人想法发布 iOS App Moments

## 1. 概述

### 1.1 产品名称

**Moments** (或 Memos / Thoughts)

### 1.2 一句话描述

一个轻量级的个人想法记录工具，支持文字+图片+标签，数据同步至 luckycc.cc 博客。

### 1.3 背景

* 图片存储：阿里云OSS，上传前压缩
* 博客展示：独立页面（不在本PRD范围内）
* 开发者背景：前端开发，通过此项目学习iOS开发

---

## 2. 数据结构设计

### 2.1 核心实体：Thought

```typescript
interface Thought {
  // 基础字段
  id: string;                    // MongoDB ObjectId (转为string)
  content: string;               // 文字内容，支持多行
  
  // 媒体
  images: Image[];               // 图片数组，最多9张
  
  // 分类
  tags: string[];                // 标签数组，如 ["随想", "技术"]
  
  // 时间
  createdAt: string;             // ISO 8601, 创建时间
  updatedAt: string;             // ISO 8601, 最后更新时间
  
  // 扩展性预留（当前不实现，但结构支持）
  visibility?: 'public' | 'private' | 'unlisted';  // 可见性
  location?: Location;           // 地理位置
  mood?: string;                 // 心情标签
  weather?: string;              // 天气
}

interface Image {
  url: string;                   // 完整URL
  thumbnailUrl?: string;         // 缩略图URL（可选，OSS图片处理生成）
  width: number;                 // 原始宽度
  height: number;                // 原始高度
  blurhash?: string;             // BlurHash占位符（可选）
}

interface Location {
  latitude: number;
  longitude: number;
  name?: string;                 // 地点名称，如 "杭州市"
}
```

### 2.2 数据库结构 (MongoDB)

 **Database** : `luckycc`
 **Collection** : `thoughts`

```javascript
// 文档结构
{
  _id: ObjectId("..."),
  content: "今天的想法...",
  images: [
    {
      url: "https://oss.luckycc.cc/thoughts/2024/01/abc.jpg",
      thumbnailUrl: "https://oss.luckycc.cc/thoughts/2024/01/abc_thumb.jpg",
      width: 1920,
      height: 1080,
      blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
    }
  ],
  tags: ["随想", "灵感"],
  
  // 扩展字段（当前可选）
  visibility: "public",  // "public" | "private" | "unlisted"
  location: {
    latitude: 30.2741,
    longitude: 120.1551,
    name: "杭州市"
  },
  mood: null,
  weather: null,
  
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-01-15T10:30:00Z")
}
```

 **索引** :

```javascript
// 创建索引
db.thoughts.createIndex({ createdAt: -1 })           // 时间倒序查询
db.thoughts.createIndex({ tags: 1 })                  // 标签筛选
db.thoughts.createIndex({ visibility: 1 })            // 可见性筛选
db.thoughts.createIndex({ tags: 1, createdAt: -1 })   // 复合索引：按标签筛选+时间排序
```

---

## 3. 功能需求

### 3.1 功能列表

| ID | 功能     | 优先级 | 描述                         |
| -- | -------- | ------ | ---------------------------- |
| F1 | 发布想法 | P0     | 文字+图片+标签               |
| F2 | 浏览列表 | P0     | 时间倒序，下拉刷新，上拉加载 |
| F3 | 查看详情 | P0     | 图片大图浏览                 |
| F4 | 删除想法 | P0     | 左滑删除，二次确认           |
| F5 | 编辑想法 | P1     | 修改文字/图片/标签           |
| F6 | 标签筛选 | P1     | 按标签过滤列表               |
| F7 | 标签管理 | P2     | 常用标签快速选择             |
| F8 | 离线草稿 | P2     | 发布失败时保存               |

### 3.2 详细描述

#### F1: 发布想法

 **输入组件** :

* 文字输入框：多行，自适应高度，placeholder "记录此刻的想法..."
* 图片选择：支持相册选择和拍照，最多9张，支持拖拽排序
* 标签选择：输入新标签或从历史标签中选择

**图片处理** (上传前，在iOS端完成):

```
1. 读取原图
2. 如果宽度 > 1920px，等比缩放至 1920px
3. JPEG压缩，quality = 0.8
4. 获取压缩后的尺寸信息
5. 上传至后端
```

 **发布流程** :

```
1. 用户点击发布
2. 显示loading状态，禁用发布按钮
3. 如有图片，依次上传（可考虑并发上传）
4. 图片全部上传成功后，创建thought记录
5. 成功：清空输入，刷新列表，轻触反馈(Haptic)
6. 失败：保留输入内容，显示错误信息
```

#### F2: 浏览列表

 **布局** : 类似朋友圈/Twitter的timeline

* 每条想法显示：内容、图片网格、标签、时间
* 图片布局规则：
  * 1张：宽度占满，高度自适应（最大300pt）
  * 2张：并排，1:1
  * 3张：左1大右2小
  * 4张：2x2网格
  * 5-9张：3列网格

 **交互** :

* 下拉刷新 (UIRefreshControl)
* 上拉加载更多 (无限滚动)
* 点击图片进入全屏浏览

#### F6: 标签筛选

 **入口** : 列表页顶部的标签栏（横向滚动）
 **交互** :

* 点击标签进行筛选
* 再次点击取消筛选
* 显示"全部"选项

---

## 4. iOS 技术方案

### 4.1 技术栈选择

| 类别     | 选择                               | 理由                                     |
| -------- | ---------------------------------- | ---------------------------------------- |
| UI框架   | **SwiftUI**                  | 声明式UI，类似React，前端友好            |
| 架构     | **MVVM**                     | 与SwiftUI配合好，类似前端的组件+状态管理 |
| 网络     | **URLSession + async/await** | 原生，类似fetch API                      |
| 图片加载 | **Kingfisher**               | 类似前端的图片懒加载库                   |
| 状态管理 | **@Observable (iOS 17+)**    | 类似React的useState/useContext           |

### 4.2 项目结构

```
Moments/
├── MomentsApp.swift              # App入口，类似index.tsx
├── ContentView.swift             # 根视图
│
├── Models/                       # 数据模型，类似TypeScript的interface
│   ├── Thought.swift
│   └── APIResponse.swift
│
├── ViewModels/                   # 业务逻辑，类似custom hooks
│   ├── ThoughtListViewModel.swift
│   ├── ComposeViewModel.swift
│   └── TagsViewModel.swift
│
├── Views/                        # UI组件，类似React components
│   ├── ThoughtList/
│   │   ├── ThoughtListView.swift
│   │   ├── ThoughtCard.swift
│   │   └── ThoughtImageGrid.swift
│   ├── Compose/
│   │   ├── ComposeView.swift
│   │   ├── ImagePicker.swift
│   │   └── TagInput.swift
│   └── Common/
│       ├── AsyncImageView.swift
│       └── LoadingView.swift
│
├── Services/                     # API调用
│   └── APIClient.swift
│
├── Utils/                        # 工具函数
│   ├── ImageCompressor.swift
│   └── KeychainHelper.swift
│
└── Resources/
    └── Assets.xcassets           # 图片资源
```

### 4.3 前端 → iOS 概念映射

这张表帮助你快速理解iOS开发：

| 前端概念                         | iOS/SwiftUI 对应               | 示例                                                       |
| -------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| `useState`                     | `@State`                     | `@State private var text = ""`                           |
| `useContext`                   | `@Environment`               | `@Environment(\.colorScheme) var colorScheme`            |
| `props`                        | View参数                       | `struct Card: View { let title: String }`                |
| `useEffect`                    | `.onAppear`/`.task`        | `.task { await loadData() }`                             |
| `fetch`                        | `URLSession`+`async/await` | `let data = try await URLSession.shared.data(from: url)` |
| `map`渲染列表                  | `ForEach`                    | `ForEach(items) { item in Text(item.name) }`             |
| 条件渲染 `{condition && <X/>}` | `if`语句                     | `if isLoading { ProgressView() }`                        |
| CSS Flexbox                      | `VStack`/`HStack`          | `VStack { Text("A"); Text("B") }`                        |
| CSS Grid                         | `LazyVGrid`                  | `LazyVGrid(columns: [...]) { ... }`                      |
| `className`                    | `.modifier()`                | `Text("Hi").font(.title).foregroundColor(.blue)`         |
| `onClick`                      | `.onTapGesture`/`Button`   | `Button("Click") { doSomething() }`                      |
| `npm install`                  | Swift Package Manager          | Xcode → File → Add Packages                              |
| `localStorage`                 | `UserDefaults`               | `UserDefaults.standard.set(value, forKey: "key")`        |
| 敏感数据存储                     | `Keychain`                   | 存储API Token                                              |

### 4.4 核心代码结构示例

**Model定义** (类似TypeScript interface):

```swift
// Models/Thought.swift
import Foundation

struct Thought: Codable, Identifiable {
    let id: String              // MongoDB ObjectId string
    var content: String
    var images: [ThoughtImage]
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
  
    // 扩展字段预留
    var visibility: Visibility?
    var location: Location?
    var mood: String?
    var weather: String?
}

struct ThoughtImage: Codable {
    let url: String
    var thumbnailUrl: String?
    let width: Int
    let height: Int
    var blurhash: String?
}

enum Visibility: String, Codable {
    case `public`, `private`, unlisted
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    var name: String?
}
```

**ViewModel** (类似React Hook):

```swift
// ViewModels/ThoughtListViewModel.swift
import Foundation

@Observable
class ThoughtListViewModel {
    var thoughts: [Thought] = []
    var isLoading = false
    var error: Error?
  
    private var page = 1
    private var hasMore = true
    private let service = ThoughtService()
  
    func loadThoughts() async {
        guard !isLoading else { return }
        isLoading = true
      
        do {
            let response = try await service.getThoughts(page: 1)
            thoughts = response.data
            hasMore = response.pagination.hasMore
            page = 1
        } catch {
            self.error = error
        }
      
        isLoading = false
    }
  
    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
      
        do {
            let response = try await service.getThoughts(page: page + 1)
            thoughts.append(contentsOf: response.data)
            hasMore = response.pagination.hasMore
            page += 1
        } catch {
            self.error = error
        }
      
        isLoading = false
    }
  
    func refresh() async {
        await loadThoughts()
    }
}
```

**View** (类似React Component):

```swift
// Views/ThoughtList/ThoughtListView.swift
import SwiftUI

struct ThoughtListView: View {
    @State private var viewModel = ThoughtListViewModel()
    @State private var showCompose = false
  
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.thoughts) { thought in
                    ThoughtCard(thought: thought)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
              
                // 加载更多
                if !viewModel.thoughts.isEmpty {
                    ProgressView()
                        .task {
                            await viewModel.loadMore()
                        }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Moments")
            .toolbar {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeView()
            }
        }
        .task {
            await viewModel.loadThoughts()
        }
    }
}
```

---

## 5. UX 交互细节

作为一个注重交互的开发者，这些细节会让App感觉更精致：

### 5.1 触觉反馈 (Haptic Feedback)

```swift
// 发布成功时
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// 删除确认时
UINotificationFeedbackGenerator().notificationOccurred(.warning)

// 标签选择时
UISelectionFeedbackGenerator().selectionChanged()
```

### 5.2 动画

* 列表项出现：淡入 + 轻微上移
* 发布成功：新内容从顶部滑入
* 删除：向左滑出 + 高度收缩
* 图片加载：BlurHash占位 → 渐显

### 5.3 手势

* 下拉刷新：原生橡皮筋效果
* 左滑删除：显示删除按钮
* 图片浏览：捏合缩放、双击放大、滑动切换
* 长按图片：弹出保存选项

### 5.4 键盘处理

* 输入框随键盘上移
* 点击空白区域收起键盘
* 外接键盘支持 Cmd+Enter 发布

### 5.5 加载状态

```
空状态 → 骨架屏/占位符
加载中 → 下拉刷新指示器 / 底部加载更多spinner
加载失败 → 重试按钮 + 错误描述
```

### 5.6 深色模式

* 自动跟随系统设置
* 图片在深色模式下降低亮度

---

## 6. 开发计划

### Phase 1: 项目搭建 + 列表展示 (Day 1)

* [ ] 创建Xcode项目
* [ ] 配置Swift Package (Kingfisher)
* [ ] 实现数据模型 (Thought, APIResponse)
* [ ] 实现APIClient基础网络层
* [ ] 实现ThoughtListView基础列表
* [ ] 实现ThoughtCard组件

 **学习重点** : SwiftUI基础语法、@State、List组件

### Phase 2: 发布功能 (Day 2)

* [ ] 实现ComposeView界面
* [ ] 实现图片选择 (PhotosPicker)
* [ ] 实现图片压缩
* [ ] 实现图片上传
* [ ] 实现发布逻辑

 **学习重点** : Sheet模态框、异步操作、UIKit桥接

### Phase 3: 标签 + 交互完善 (Day 3)

* [ ] 实现标签选择组件
* [ ] 实现标签筛选
* [ ] 实现删除功能
* [ ] 添加Haptic反馈
* [ ] 添加动画效果

 **学习重点** : 组件封装、手势处理、动画API

### Phase 4: 编辑 + 细节打磨 (Day 4)

* [ ] 实现编辑功能
* [ ] 图片全屏浏览
* [ ] 错误处理优化
* [ ] 深色模式适配
* [ ] 离线草稿（可选）

 **学习重点** : NavigationStack、数据传递、本地存储

---

## 7. 环境与工具

### 7.1 开发环境

* macOS 14+ (Sonnet)
* Xcode 15+ (免费，从App Store下载)
* iOS 17.0+ (部署目标)
* 真机调试需要Apple Developer账号（免费账号可以）

### 7.2 依赖管理

通过 Swift Package Manager (SPM) 添加：

* `Kingfisher`: 图片加载缓存
* (可选) `AlertToast`: Toast提示

### 7.3 调试工具

* Xcode Previews: 实时预览UI，类似Storybook
* Charles/Proxyman: 抓包调试API
* Instruments: 性能分析

---

## 8. 待确认

1. **App名称** : Moments / Memos / Thoughts / 其他？
2. **App图标** : 需要设计吗？可以先用 SF Symbols 占位

---

## 附录A: 学习资源

### 官方文档

* [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui) - Apple官方教程，强烈推荐
* [Swift Language Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/)

### 视频教程

* [CS193p (Stanford)](https://cs193p.sites.stanford.edu/) - 斯坦福iOS开发课，免费
* [Hacking with Swift](https://www.hackingwithswift.com/100/swiftui) - 100 Days of SwiftUI

### 前端转iOS

* SwiftUI的声明式语法和React非常像
* @State ≈ useState，@Binding ≈ props + onChange
* 最大的不同是类型系统更严格，需要适应Swift的Optional

### 推荐学习路径

1. 先跑通Apple官方的SwiftUI Tutorial
2. 对照本PRD的代码示例理解MVVM结构
3. 边做边学，遇到问题再查文档
