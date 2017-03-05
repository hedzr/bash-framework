# Bash Framework

`Bash Framwork` 是一个最小集合的Bash脚本编程框架，主要面向  `DevOps` 管理任务。
因此，默认的函数集合中包含了像 `package-install`, `is_package_installed`, `if_ubuntu`, `if_centos`, `is_root` 这类辅助函数。

## Installation

通过如下的脚本可以将 `Bash Framwork` 部署到目标机上：

```bash
curl -sSL https://hedzr.com/bash-framework/installer | sudo bash -s
```

默认的安装位置是 `/usr/local/bin/ops-fw/`，并包含一个引导性的脚本 `/usr/local/bin/bash-framework` / `ops`。

当安装完成后应该重新登录到目标机的shell环境中，以便 `Bash Framwork` 基础环境自动加载。

一旦安装成功，你可以通过 `bash-framework`/`ops` 来启动主控脚本，具体方法详见：

```bash
bash-framework -v
bash-framework --help
bash-framework help
bash-framework usage
```

## 在此基础上开发你的脚本集合

在目标机上已经有了 `Bash Framwork` 的基本源代码，你可以复制以下内容到你的工作目录中，然后进行自定义开发：

```bash
mkdir my-work && cd -
cp -R /usr/local/bin/ops-fw/* ./
cp /usr/local/bin/bash-framework ./my-ops
```

也可以直接 `git clone https://github.com/hedzr/bash-framework/` 后开始你的自定义工作。

## Installer 做了些什么？

1. 下载脚本包的全部文件到 `/usr/local/bin` 及其子目录 `ops-fw`
2. 使能主文件 bash-framework 可执行
3. 建立名为 `ops` 的符号链接，可以更便利地使用引导脚本 `bash-framework`
4. 在当前用户的 `$HOME/.bashrc` 中追加 `bash-framwork` 环境，包括：
   - PS1颜色
   - 登录时信息 `ii` (由 `at-login` 载入)
   - 基本环境配置，提供一组别名和函数以加速命令行操作 


## 使用 `Bash Framwork`

### 使用引导性命令 `ops`

整个工具集的所有功能性命令，均通过 home 命令 `ops` 来引导。

> **DONE：ops指令具有自动补全机制，从输入“ops<TAB><TAB>”开始渐进地获得帮助。**

```bash
ops
ops help
ops version [-r]
ops upgrade
ops install|config|tune [...]
ops nginx|... install|tune 

ops backup|restore foreman|dns|puppet|...
  # NOTE: restore功能并未实现
```

#### nginx 功能

```bash
ops install-nginx
ops tune-nginx
或者：
ops nginx install|tune
```

#### consul 功能

略

### `bash-completion` 不生效？

请确保安装了 `bash-completion` 软件包且为当前用户激活了该机制。

一般地，多数发行版都已经预装了 `bash-completion` 软件包，你可以确认它，也可以（通常）再度安装：

```bash
# centos / redhat
yum install -y --enablerepo=epel bash-completion
dnf install bash-completion
# ubuntu / debian
apt-get install bash-completion
apt install bash-completion            # Ubuntu 16
```

检查 `$HOME/.bashrc` 文件内容，确定以下内容是有效且未被注释的：

```bash
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
   . /etc/bash_completion
fi

```

不同系统可能略有出入，但一定会 `. /etc/bash_completion`。

`/etc/bash_completion` 将会装载 `/etc/bash_completion.d/*`，包括 `/etc/bash_completion.d/ops_ac`，这是 `Bash Framework` 的引导命令 `ops` 的自动完成供给者。



### 使用辅助性 helpers

**辅助性命令的特点是无需任何前置引导。**

**通常，可以在root身份下直接使用。**

例如：

```bash
$ hostnames
hostname: sw0ops00.ops.local
    fqdn: sw0ops00.ops.local
all-fqdn: sw0ops00.ops.local 
   short: sw0ops00
  domain: ops.local
   alias: sw0ops00
```

这些辅助性的helpers, 均可借助bash命令行自动完成机制简化你的输入，例如输入“if<TAB><TAB>”试试。

#### if_os, if_not_os, if_nix, if_mac, if_ubuntu, if_centos

if[not_]os [linux|darwin|cygwin|...]
if_nix [gnu|bsd|sun]

#### if_aliyun, if_aws_cn, if_aws

注意这三个测试目前只能在AWS CN中正确使用，尚未具体完成。

#### ii

快速的查看服务器关键性基本信息。

```bash
$ ii

       You are logged on : sw0vvv00.ops.local
 Additionnal information :  Linux sw0vvv00.ops.local 4.4.35-33.55.amzn1.x86_64 #1 SMP Tue Dec 6 20:30:04 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
            Current date :  2017年 02月 15日 星期三 01:12:12 UTC
           Machine stats :  01:12:12 up 16:02,  1 user,  load average: 0.00, 0.00, 0.00
        Local IP Address : *.*.16.10 / eth0
use: 'ip-wan' to query the public ip address of mine.
avaliable commands: disc-info, ports, ii, ip-wan, ip-lan, ip-gw, ip-mask, ip-subnet, ....
```

#### ports, disc-info, ip-wan, ip-lan, ip-gw, ip-mask, ip-subnet, hostnames, disc-info-all

基本服务器信息查询命令

#### more...

is_root
is_in_source
if_launched_from_symlink
is_bash
is_bash_t2
is_zsh
is_interactive_shell
is_not_interactive_shell
is_ps1
is_not_ps1
is_stdin
is_not_stdin
is_package_installed
is_packages_all_installed
is_packages_any_installed
is_package_lower
package-list    # 仅centos/yum可用
package-list-installed
install_packages / install-packages / package-install


## 适合于谁？

`Bash Framework` 适合于要开发大量shell脚本的编程人员，我们提供了一个基本的命令组织结构，以及安装和分发模型，你可以在此基础上展开自己的业务逻辑开发，并在任一服务器上快速分发你的脚本集合。

## 缘由

`Bash Framework` 基于作者历年来经验进行了提炼，希望能帮助到 ops/devops 工具作者或者其他人。

## LICENSE

MIT

## AUTHOR

Hedzr


