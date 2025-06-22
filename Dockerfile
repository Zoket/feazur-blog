# 阶段1: 构建应用
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制依赖管理文件
COPY package.json pnpm-lock.yaml ./

# 安装所有依赖
RUN pnpm install

# 复制项目文件
COPY . .

# 构建项目
RUN pnpm run build

# 阶段2: 运行环境
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制生产环境所需的依赖管理文件
COPY package.json pnpm-lock.yaml ./
# 只安装生产环境依赖
RUN pnpm install

# 从构建阶段复制打包好的文件
COPY --from=builder /app/dist/ ./dist/

# 暴露端口
EXPOSE 4321

# 设置环境变量
ENV HOST=0.0.0.0
ENV PORT=4321

# 启动命令
CMD ["pnpm", "run", "preview", "--host", "0.0.0.0"] 