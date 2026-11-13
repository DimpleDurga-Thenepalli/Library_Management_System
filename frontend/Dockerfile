
# Stage 1: Build React frontend
FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

# Stage 2: Serve frontend using Nginx
FROM nginx:alpine AS runtime

# Fix HIGH vulnerabilities detected by Trivy
RUN apk upgrade --no-cache libxslt

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
