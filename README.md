# wsl2-ubuntu-work-env
搭建wsl2-ubunut的工作需要的环境

## windows端准备
- WSL 版本为 2（非 WSL1）；
- Windows 已安装新版 usbipd-win（≥4.0），WSL2 安装 USB/IP 工具链。
### 确认 WSL2 版本（非 WSL1）管理员 PowerShell 执行
```
# 查看 WSL 版本（确保 TargetVersion 为 2）
wsl -l -v

# 若为 WSL1，升级（替换为你的发行版名，如 Ubuntu）
wsl --set-version Ubuntu 2

# 更新 WSL 内核（必需，支持 USB/IP）
wsl --update
wsl --shutdown
```
### 安装 usbipd-win（USB 穿透核心工具）
- 下载地址：https://github.com/dorssel/usbipd-win/releases
- 安装最新 .msi 包（一路默认下一步）；
- 验证安装：usbipd --version（输出版本号即成功）。

## 挂载usb
### 方式1:wsl-ubuntu中调用win环境的powershell执行命令
```
#!/bin/bash
# WSL2 重启后自动恢复 USB 串口设备（强制指定 BUSID 参数）
# 使用方式（必须传参）：
# ./restore_usb.sh 7-1  或  ./restore_usb.sh 3-2

# ====================== 颜色输出 ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ====================== 强制参数校验 ======================
# 检查是否传入 BUSID 参数，未传入则报错退出
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ 错误：必须指定 BUSID 参数！${NC}"
    echo -e "${YELLOW}ℹ️  使用方式：${NC}"
    echo -e "   ./restore_usb.sh <BUSID>"
    echo -e "   示例：./restore_usb.sh 7-1  或  ./restore_usb.sh 3-2"
    echo -e "${YELLOW}ℹ️  查看可用 BUSID：在 Windows 管理员 PowerShell 执行 usbipd list${NC}"
    exit 1
fi

# 验证传入的 BUSID 格式（匹配 x-x 格式，如 7-1、3-2）
TARGET_BUSID="$1"
if ! [[ "$TARGET_BUSID" =~ ^[0-9]+-[0-9]+$ ]]; then
    echo -e "${RED}❌ 错误：BUSID 格式无效！${NC}"
    echo -e "${YELLOW}ℹ️  正确格式示例：7-1、3-2（数字-数字）${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 已指定 BUSID：${TARGET_BUSID}${NC}"

# ====================== 自动检测 PowerShell 路径 ======================
echo -e "\n🔧 检测 PowerShell 路径..."
POWERSHELL_PATH=""
# 优先检测默认路径
if [ -x "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" ]; then
    POWERSHELL_PATH="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
elif [ -x "/mnt/c/Program Files/PowerShell/7/pwsh.exe" ]; then
    # 兼容 PowerShell 7 版本
    POWERSHELL_PATH="/mnt/c/Program Files/PowerShell/7/pwsh.exe"
else
    echo -e "${RED}❌ 未找到 PowerShell 可执行文件！${NC}"
    echo -e "${YELLOW}ℹ️  排查建议：${NC}"
    echo -e "   1. 确认 Windows 已安装 PowerShell"
    echo -e "   2. 检查路径：/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe 是否存在"
    exit 1
fi
echo -e "${GREEN}✓ 找到 PowerShell 路径：${POWERSHELL_PATH}${NC}"

# ====================== 核心逻辑 ======================
# 步骤 1：加载 USB/IP 内核模块
echo -e "\n🔧 加载 USB/IP 内核模块..."
if ! sudo modprobe vhci-hcd; then
    echo -e "${RED}❌ 加载 vhci-hcd 模块失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 内核模块加载成功${NC}"

# 步骤 2：Windows 端绑定+挂载设备（通过 WSL 调用 PowerShell）
echo -e "\n🔧 Windows 端挂载 USB 设备（BUSID=${TARGET_BUSID}）..."
# 执行 PowerShell 命令并捕获错误

# 第一步：定义 usbipd 完整路径
USBIPD_EXE_PATH="C:\Program Files\usbipd-win\usbipd.exe"
# 第二步：构造 usbipd 执行命令
powershell_cmd="& '${USBIPD_EXE_PATH}' bind --busid ${TARGET_BUSID}; & '${USBIPD_EXE_PATH}' attach --busid ${TARGET_BUSID} --wsl"
# 第三步：提权执行（移除 -NoNewWindow 避免参数冲突）
powershell_full_cmd="Start-Process -FilePath 'powershell.exe' -ArgumentList '-Command', \"$powershell_cmd\" -Verb RunAs -Wait"
# 执行并捕获输出（处理中文乱码）
powershell_out=$($POWERSHELL_PATH -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $powershell_full_cmd" 2>&1)

if echo "$powershell_out" | grep -qiE "error|not found|access denied|拒绝访问|InvalidArgument|AmbiguousParameterSet"; then
    echo -e "${RED}❌ Windows 端挂载设备失败！${NC}"
    echo -e "${YELLOW}   错误详情：${NC}"
    echo "$powershell_out"
    echo -e "${YELLOW}   排查建议：${NC}"
    echo -e "   1. 确认 usbipd.exe 路径正确（当前：${USBIPD_EXE_PATH}）"
    echo -e "   2. 手动在 Windows 管理员 PowerShell 执行："
    echo -e "      usbipd bind --busid ${TARGET_BUSID}"
    echo -e "      usbipd attach --busid ${TARGET_BUSID} --wsl"
    echo -e "   3. 或以管理员身份启动 WSL2 后重新执行脚本"
    # 即使 PowerShell 报错，若串口已存在则继续执行（兼容已挂载场景）
    if [ -e "/dev/ttyUSB0" ] || [ -e "/dev/ttyACM0" ]; then
        echo -e "${YELLOW}⚠️  检测到串口设备已存在，跳过错误继续执行...${NC}"
    else
        exit 1
    fi
else
    # 处理「已共享/已挂载」的提示，转为警告而非错误
    if echo "$powershell_out" | grep -qiE "already shared|already attached"; then
        echo -e "${YELLOW}⚠️  USB 设备已共享/已挂载，无需重复操作${NC}"
    else
        echo -e "${GREEN}✓ Windows 端设备挂载指令执行完成${NC}"
    fi
fi

# 步骤 3：等待设备加载（避免串口未就绪）
echo -e "\n🔧 等待串口设备加载..."
sleep 2

# 步骤 4：验证并授权串口（兼容 ttyUSB0/ttyACM0）
echo -e "\n🔧 验证串口设备并授权..."
SERIAL_DEVICE=""
if [ -e "/dev/ttyUSB0" ]; then
    SERIAL_DEVICE="/dev/ttyUSB0"
elif [ -e "/dev/ttyACM0" ]; then
    SERIAL_DEVICE="/dev/ttyACM0"
else
    echo -e "${RED}❌ 未找到可用的串口设备（ttyUSB0/ttyACM0）！${NC}"
    echo -e "${YELLOW}ℹ️  当前挂载的 USB 设备列表：${NC}"
    lsusb
    exit 1
fi

# 授权串口
sudo chmod 666 "${SERIAL_DEVICE}"
echo -e "${GREEN}✅ USB 设备恢复成功！${NC}"
echo -e "${GREEN}   串口路径：${SERIAL_DEVICE}${NC}"
echo -e "${GREEN}   BUSID：${TARGET_BUSID}${NC}"
```
### 方式2：只处理wls ubuntu中的命令方式
这个版本完全不调用 Windows 命令，只做 WSL 内的必要操作，避免所有跨系统调用的坑：
```
#!/bin/bash
# WSL2 USB 设备配置脚本（仅处理 WSL 端，Windows 端需手动挂载）
# 使用方式：./bind_usb.sh 7-3
# 前置：先在 Windows 管理员 PowerShell 执行：usbipd attach --busid 7-3 --wsl

# ====================== 颜色输出 ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ====================== 强制参数校验 ======================
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ 错误：必须指定 BUSID 参数！${NC}"
    echo -e "${YELLOW}ℹ️  使用方式：${NC}"
    echo -e "   ./bind_usb.sh <BUSID>"
    echo -e "   示例：./bind_usb.sh 7-1  或  ./bind_usb.sh 7-3"
    echo -e "${YELLOW}ℹ️  前置操作（Windows 管理员 PowerShell）：${NC}"
    echo -e "   usbipd attach --busid <BUSID> --wsl"
    exit 1
fi

TARGET_BUSID="$1"
if ! [[ "$TARGET_BUSID" =~ ^[0-9]+-[0-9]+$ ]]; then
    echo -e "${RED}❌ 错误：BUSID 格式无效！${NC}"
    echo -e "${YELLOW}ℹ️  正确格式：7-1、3-2（数字-数字）${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 已指定 BUSID：${TARGET_BUSID}${NC}"

# ====================== 智能权限检测 =======================
echo -e "\n🔧 检测串口权限组（dialout）..."
if groups $USER | grep -q "\bdialout\b"; then
    echo -e "${GREEN}✓ 当前用户已在 dialout 组，无需重复授权${NC}"
else
    echo -e "${YELLOW}⚠️  当前用户未在 dialout 组，执行永久授权...${NC}"
    sudo usermod -aG dialout $USER
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 永久授权成功！${NC}"
        echo -e "${YELLOW}ℹ️  权限将在重启终端/WSL2 后生效${NC}"
    else
        echo -e "${RED}❌ 永久授权失败！请手动执行：sudo usermod -aG dialout $USER${NC}"
    fi
fi

# ====================== 加载内核模块 ======================
echo -e "\n🔧 加载 USB/IP 内核模块..."
if ! sudo modprobe vhci-hcd; then
    echo -e "${RED}❌ 加载 vhci-hcd 模块失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 内核模块加载成功${NC}"

# ====================== 等待并检测串口 ======================
echo -e "\n🔧 等待串口设备加载（3 秒）..."
sleep 3

echo -e "\n🔧 检测可用串口设备..."
# 遍历所有可能的串口路径
SERIAL_DEVICES=(/dev/ttyUSB* /dev/ttyACM*)
FOUND_DEVICE=""
for dev in "${SERIAL_DEVICES[@]}"; do
    if [ -e "$dev" ]; then
        FOUND_DEVICE="$dev"
        break
    fi
done

if [ -z "$FOUND_DEVICE" ]; then
    echo -e "${RED}❌ 未找到可用串口设备！${NC}"
    echo -e "${YELLOW}ℹ️  排查步骤：${NC}"
    echo -e "   1. 确认已在 Windows 管理员 PowerShell 执行：usbipd attach --busid ${TARGET_BUSID} --wsl"
    echo -e "   2. 执行 lsusb 查看已挂载的 USB 设备"
    lsusb
    exit 1
else
    # 临时授权串口
    sudo chmod 666 "$FOUND_DEVICE"
    echo -e "${GREEN}✅ USB 设备配置完成！${NC}"
    echo -e "${GREEN}   串口路径：${FOUND_DEVICE}${NC}"
    echo -e "${GREEN}   BUSID：${TARGET_BUSID}${NC}"
    echo -e "${YELLOW}ℹ️  串口已授权，可直接使用（如：screen ${FOUND_DEVICE} 115200）${NC}"
fi
```

## 卸载usb
```
#!/bin/bash
# WSL2 一键取消 USB 设备挂载（需指定 BUSID 参数）
# 使用方式：./unbind_usb.sh 7-1

# ====================== 颜色输出 ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ====================== 强制参数校验 ======================
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ 错误：必须指定 BUSID 参数！${NC}"
    echo -e "${YELLOW}ℹ️  使用方式：${NC}"
    echo -e "   ./unbind_usb.sh <BUSID>"
    echo -e "   示例：./unbind_usb.sh 7-1"
    exit 1
fi
TARGET_BUSID="$1"
if ! [[ "$TARGET_BUSID" =~ ^[0-9]+-[0-9]+$ ]]; then
    echo -e "${RED}❌ 错误：BUSID 格式无效！${NC}"
    echo -e "${YELLOW}ℹ️  正确格式：7-1、3-2（数字-数字）${NC}"
    exit 1
fi

# ====================== 自动检测 PowerShell 路径 =======================
echo -e "${YELLOW}🔧 检测 PowerShell 路径...${NC}"
POWERSHELL_PATH="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
if [ ! -x "$POWERSHELL_PATH" ]; then
    POWERSHELL_PATH="/mnt/c/Program Files/PowerShell/7/pwsh.exe"
fi
if [ ! -x "$POWERSHELL_PATH" ]; then
    echo -e "${RED}❌ 未找到 PowerShell 可执行文件！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 找到 PowerShell 路径：${POWERSHELL_PATH}${NC}"

# ====================== 核心取消逻辑 ======================
echo -e "\n🔧 Windows 端断开 USB 挂载（BUSID=${TARGET_BUSID}）..."
# 提权执行：先断开挂载，再解除共享
powershell_cmd="Start-Process -FilePath 'powershell.exe' -ArgumentList '-Command', \"& 'C:\Program Files\usbipd-win\usbipd.exe' detach --busid ${TARGET_BUSID}; & 'C:\Program Files\usbipd-win\usbipd.exe' unbind --busid ${TARGET_BUSID}\" -Verb RunAs -Wait"
powershell_out=$($POWERSHELL_PATH -Command "$powershell_cmd" 2>&1)

# 错误处理
if echo "$powershell_out" | grep -qiE "error|not found|拒绝访问"; then
    echo -e "${YELLOW}⚠️  Windows 端取消挂载提示：${NC}"
    echo "$powershell_out"
    echo -e "${YELLOW}ℹ️  可手动在 Windows 管理员 PowerShell 执行：${NC}"
    echo -e "   usbipd detach --busid ${TARGET_BUSID}"
    echo -e "   usbipd unbind --busid ${TARGET_BUSID}"
else
    echo -e "${GREEN}✓ Windows 端已断开 USB 设备挂载并解除共享${NC}"
fi

# WSL2 端清理内核模块（可选）
echo -e "\n🔧 WSL2 端清理 USB/IP 内核模块..."
if sudo rmmod vhci-hcd; then
    echo -e "${GREEN}✓ WSL2 内核模块已卸载${NC}"
else
    echo -e "${YELLOW}⚠️  内核模块未加载或无需卸载${NC}"
fi

# 验证取消结果
echo -e "\n🔧 验证取消结果..."
if ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null; then
    echo -e "${YELLOW}⚠️  WSL2 中仍残留串口设备（重启 WSL2 后消失）${NC}"
else
    echo -e "${GREEN}✅ USB 设备已成功从 WSL2 取消挂载！${NC}"
fi
```
