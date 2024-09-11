

## 使用教程

### reality和hysteria2 vmess ws三合一脚本

```bash
bash <(curl -fsSL https://github.com/nowhash6120/sing-box-reality-hysteria2/raw/main/beta.sh)
```

### reality hysteria2二合一脚本

```bash
bash <(curl -fsSL https://github.com/nowhash6120/sing-box-reality-hysteria2/raw/main/install.sh)
```

### 安装完成后终端输入 nowhash 可再次调用本脚本


|项目||
|:--|:--|
|程序|**/root/sbox/sing-box**|
|服务端配置|**/root/sbox/sbconfig_server.json**|
|重启|`systemctl restart sing-box`|
|状态|`systemctl status sing-box`|
|查看日志|`journalctl -u sing-box -o cat -e`|
|实时日志|`journalctl -u sing-box -o cat -f`|

warp解锁v4 v6等操作自行使用warp-go脚本
具体操作就不说了

```
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh && bash warp-go.sh
```

