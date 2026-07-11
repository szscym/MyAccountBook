# 我的账本 MyAccountBook

Material Design 3 个人记账 Android App（KivyMD + SQLite）

---

## 获取 APK 安装包（3 分钟）

### 第 1 步：创建 GitHub 仓库

1. 打开 https://github.com/new
2. 仓库名填 **MyAccountBook**，选 Public
3. 不要勾任何初始化选项，直接点 **Create repository**

### 第 2 步：上传代码

```bash
cd D:\MyAccountBook
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/你的用户名/MyAccountBook.git
git push -u origin main
```

### 第 3 步：等待自动打包

1. 打开仓库的 **Actions** 标签页
2. 会看到一个 **Build APK** 工作流正在运行
3. 等待 30-60 分钟（首次需要下载 Android SDK）
4. 跑完后点击这个 workflow，在 Artifacts 里下载 **myaccountbook-apk**

### 第 4 步：安装到手机

- 扫码下方二维码打开仓库
- 从 Actions 页面下载 APK
- 手机打开 **允许安装未知来源应用**
- 安装后即可使用

![扫码下载 APK](qr-download.png)

---

## 扫码下载二维码

扫一扫 -> 打开 GitHub 仓库 -> Actions -> 下载 APK

---

## 开发者指南
### 本地运行
```bash
pip install kivy==2.3.1 kivymd==1.2.0
cd D:\MyAccountBook
python main.py
```

### 本地打包 APK（需 WSL）
```bash
在 WSL Ubuntu 中执行：
cd ~
cp -r /mnt/d/MyAccountBook .
cd MyAccountBook
buildozer android debug
```

---

## 项目结构
```
MyAccountBook/
├── main.py             ← 主程序（KivyMD）
├── database.py         ← 数据库层（SQLite）
├── accountbook.kv      ← 字体配置
├── buildozer.spec      ← APK 打包配置
├── icon.png            ← 应用图标
├── qr-download.png     ← 下载二维码
└── .github/workflows/  ← CI 自动打包
```
