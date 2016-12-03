# Bash Framework

`Bash Framwork` 是一个最小集合的Bash脚本编程框架，主要面向  `DevOps` 管理任务。
因此，默认的函数集合中包含了像 `package-install`, `is_package_installed`, `if_ubuntu`, `if_centos`, `is_root` 这类辅助函数。

## Installation

通过如下的脚本可以将 `Bash Framwork` 部署到目标机上：

```bash
curl -sSL https://hedzr.com/bash-framwork/installer | sudo bash -s
```

默认的安装位置是 `/usr/local/bin/ops-fw/`，并包含一个引导性的脚本 `/usr/local/bin/bash-framework`。

当安装完成后应该重新登录到目标机的shell环境中，以便 `Bash Framwork` 基础环境自动加载。

一旦安装成功，你可以通过 `bash-framework` 来启动主控脚本，具体方法详见：

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
cp  `/usr/local/bin/bash-framework ./my-ops
```

也可以直接 `git clone https://ggithub.com/hedzr/bash-framework/` 后开始你的自定义工作。


