---
title: 新电脑的Shell相关配置&踩坑
description: 记录一下在新电脑上通过满足自己强迫症来配置开发环境的过程
tags:
  - shell
  - Mac
  - enviroment-config
pubDate: 2023-09-08
draft: false
---
## 差生文具多系列
这篇博文记录一下在新电脑上对shell的配置。
### 终端模拟器：Alacritty
最新的MacOS终端自带了zsh（我记得当年默认shell程序还是bash），省的自己装了😃。但是默认的提示符和终端还是很丑。看了一些大佬的shell模拟器选择之后选择了**Alacritty**，由纯Rust编写的GPU加速的shell模拟器。不得不说Alacritty真的很极客，没有iterm2那么多的Perferences，菜单栏之后大大的Alacritty，所有的配置要自己`~/.config/alacritty/alacritty.yml`实现。Alacritty官网有些简陋，并没有很醒目的对配置文件的描述，但是github仓库的README.md的[Configuration](https://github.com/alacritty/alacritty#configuration)倒是指出了发布页面随安装包附带的配置文件示例，以及使用`man 5 alacritty`或者在[这里](https://github.com/alacritty/alacritty/blob/master/extra/man/alacritty.5.scd)查看配置项的说明。
配置文件说明太长了，从网上嫖来前端大佬pseudoyu的[Alacritty配置](https://github.com/pseudoyu/dotfiles/blob/master/alacritty/alacritty.yml)，并仿照大佬的习惯安装了Meslo LG字体。
### 字体：Meslo LG Nerd Font Mono
说到字体，大佬的Alacritty配置文件的字体是这样配置的：`font:normal:family: "MesloLGSDZ Nerd Font Mono"`。去搜了一下字体名字，大概了解到，Nerd Font是一种为程序员制作的字体包，将普通字体和大量字符打包到一起，可以让终端显示很多奇形怪状的符号。所以终端字体使用Nerd Font是肯定没错的。至于使用哪种Nerd Font，就见仁见智了。在homebrew中可以查看并安装所有的Nerd Font：先执行`brew tap homebrew/cask-fonts`，关联homebrew官方的字体仓库，其次在[Nerd Font](https://github.com/ryanoasis/nerd-fonts)的README可以看到所有的Nerd Font列表，找到想要的字体后`brew install font-xxx-nerd-font`安装就可以啦。
### 终端提示符：Starship
终端提示符没有选择安装zsh主题，而是选择了同样使用Rust写的Starship，一键安装，支持多种shell程序及系统集成，内置了足够多的样式可以配置，可以说是powerlevel10k的超集了。在MacOS中使用`brew install starship`安装，然后在`~/.zshrc`中新增一行`eval "$(starship init zsh)"`就可以看到终端提示符已经变成Starship最基础的样子了。
在.zshrc中新增Starship的同时，我新增了两个alias：`alias ll="ls -l"`和`alias lt="ls -lt"`，用来简化命令操作。**日后alias设置多了会单独列出来作为一个session。**
在一篇zsh和Starship整合的[文章](https://zhuanlan.zhihu.com/p/144669410)中学习到了设置zsh大小写敏感的方法：
```
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
```
### Shell程序：zsh
按照文章推荐，安装了zsh最常用的插件：
- zsh-autosuggestions（补全提示）
- zsh-syntax-highlighting（高亮）
使用homebrew安装插件：
```
brew install zsh-autosuggestions zsh-syntax-highlighting
```
然后在`~/.zshrc`中添加：
```
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```
同样按照文章推荐，添加了测速命令。在`~/.zshrc`中添加：
```
zmodload zsh/zprof
alias tt="\time zsh -i -c exit"
```
在命令行输入`tt`即可。

### 终端分屏：Tmux
还是使用homebrew来安装Tmux：
```
brew install tmux
```
安装完后在命令行执行``tmux -V``可以检验是否安装成功。
tmux有几个基础概念：session，window，pane。一个session可以包含很多个window，一个window可以包含很多个pane。同时tmux有一个被称为“前缀键”的概念（默认为C-b），有的快捷键需要先按下前缀键，在按下对应的按键，才会被tmux识别为快捷键。
``~/.tmux.conf``文件是tmux的配置文件，主要用来对快捷键做remap以及安装插件。这里列举几项配置：
```
unbind %
bind | split-window -h -c "#{pane_current_path}"

unbind '"'
bind - split-window -v -c "#{pane_current_path}"
```
unbind即为解绑，tmux默认左右分屏快捷键是%，但是不够直观，这里修改为竖杠“|”。后面``-c "#{pane_current_path}"``的意思是分屏之后默认进入当前目录。同理下面是将上下分屏的快捷键"重新映射为横杠。
```
unbind r
bind r source-file ~/.tmux.conf
```
在tmux中修改完配置后使用C-b r来使配置生效。
```
bind -r j resize-pane -D 5
bind -r k resize-pane -U 5
bind -r l resize-pane -R 5
bind -r h resize-pane -L 5
bind -r m resize-pane -Z
```
使用vim的方向键改变pane大小，即C-b j向下改变，C-b l向右改变等。C-b m最大化当前pane，再按一次回到原来大小。
```
set -g @plugin 'tmux-plugins/tpm'
run '~/.tmux/plugins/tpm/tpm' 
```
第一行是安装tpm（tmux plugin manager）插件。第二行是启用tpm。
⚠️注意！第一次在配置文件中写入tpm并加载后，如果出现``~/.tmux/plugins/tpm/tpm' returned 127``的异常，需要手动将tpm下载到本地，执行``git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm``即可。
⚠️注意！在.tmux.conf中使用tpm配置插件后，需要在tmux中C-b shift-i安装插件，否则插件不生效。
- 进入tmux的copy mode：``C-b [``；退出copy mode：``C-c``或``Shift-a``；
- 修改window的名字：``C-b ,``；切换多个windows：``C-b w``；
- 退出session：``C-b d``（detach）；
关于tmux的插件，我安装了4个：
```
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'jimeh/tmux-themepack'
set -g @plugin 'tmux-plugins/tmux-resurrect' # persist tmux sessions after computer restart
set -g @plugin 'tmux-plugins/tmux-continuum' # automatically saves sessions for you every 15 minutes

set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
```
第一行的插件可以改变切换tmux pane快捷键，使用``Ctrl+h/j/k/l``就可以切换一个window里的pane。在vim里也安装这个插件的话，在pane里打开vim的话光标也可以自由在tmux的pane和vim内部之间移动；
第二行是颜色主题插件，暂时还没有做使用；
第三行可以保存当前tmux的session信息，在电脑重启后直接打开；
第四行的插件可以没15分钟保存一次session信息；

⚠️如果遇到快捷键无反应的情况，可以手动执行脚本。tpm的脚本在``~/.tmux/plugins/tpm/bin/``目录下。
### 终端IDE：neovim
neovim作为vim的增强版，继承了vim的大多数快捷键，并提供了使用lua脚本安装插件的能力。我这里直接使用了LazyVim，即neovim的预设配置，使用lazy.nvim作为插件和配置管理，并内置了常用的插件，基本可以做到开箱即用。
首先用Homebrew安装neovim：
```
brew install neovim
```
安装好之后我们开始安装LazyVim。
LazyVim官网有一些Requirements：
- Neovim >= 0.8.0，此项必装；
- Git >= 2.19.0，此项必装；
- Nerd Font，已经在上面字体一节安装好；
- lazygit，go语言写的终端git ui，LazyVim可以通过快捷键一键打开lazygit，但是用终端命令也是一样的，我装了，但是感觉用处不大；
- C编译器，用于nvim-treesitter，mac安装xcode的话自带了gcc；
- telescope.nvim依赖的插件，可选，但是装了的话大概好像可以加快检索速度：
  - live grep：ripgrep，快速检索文件内容；
  - find files：fd，快速查找文件；

做好以上准备后，就可以安装LazyVIm了。
因为LazyVim本质上只是Neovim的配置文件，所以其所谓的“安装”其实是下载了一坨Neovim的配置。官网的安装流程如下：
- 备份原来的Neovim配置文件（如果是新安装的Neovim就不用备份了，比如我:)）：
  ```
  # required
  mv ~/.config/nvim ~/.config/nvim.bak

  # optional but recommended
  mv ~/.local/share/nvim ~/.local/share/nvim.bak
  mv ~/.local/state/nvim ~/.local/state/nvim.bak
  mv ~/.cache/nvim ~/.cache/nvim.bak
  ```
- 将LazyVim配置用git clone到本地的指定路径：
  ```
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  ```
- 移除刚才克隆的``.git``文件夹，以便可以自己管理配置：
  ```
  rm -rf ~/.config/nvim/.git
  ```
LazyVim安装完毕！
使用``nvim``命令打开LazyVim，会开始自动安装预置好的插件。