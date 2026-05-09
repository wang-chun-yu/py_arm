# 项目说明



# 项目结构
.cursor: 智能体协作工具链(git@github.com:wang-chun-yu/cursor-rules.git)
| 
common_doc: 公共文档(git@github.com:wang-chun-yu/common-doc.git)
|
doc: 项目文档
|
src: 源码管理
    |
    reference: 参考代码仓库
    |
    project: 项目代码仓库
|
docker: 容器管理
|
scripts: 脚本


# 环境构建
note： 下面的脚本执行要求在py_arm的目录下
## 运行本地仓库
```
./docker/run_registry/run_registry.sh
./docker/run_registry/mirror_ros_humble_to_local.sh
```
## 构建amd64、arm64双环境镜像并推送到服务器
```
// 修改./docker/build_images/ros2-humble-py_arm.Dockerfile, 增加依赖
./docker/build_images/build_base_image_and_push.sh
```
## 运行amd64仿真容器
```
./docker/run_amd64_runtime_container/run_amd64_runtime_container.sh
```
## 运行amd64交叉编译容器
```
./docker/run_amd64_crosscompile_arm64_container/build_amd64_crosscompile_arm64_container.sh
./docker/run_amd64_crosscompile_arm64_container/run_amd64_crosscompile_arm64_container.sh
```
## 运行arm64容器
```
// 拷贝./dokcer/run_arm64_runtime_container
cd docker
./run_arm64_runtime_container.sh
// 运行程序（将交叉编译的程序拷贝到~/dataset/下）
```