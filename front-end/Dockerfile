FROM node:current-alpine AS builder

WORKDIR /usr/src/app

RUN apk add --no-cache unzip

COPY app.zip /tmp/app.zip

RUN mkdir -p /usr/src/app/dist  \
    && unzip -q -o -d /usr/src/app/dist /tmp/app.zip \
    && rm -f /tmp/app.zip


#FROM node:current-alpine AS builder
#WORKDIR /usr/src/app
#COPY package.json package-lock.json ./
#RUN npm install
#COPY . .
#RUN npm run build --configuration demo


FROM nginx:stable-alpine

COPY --from=builder /usr/src/app/dist /usr/share/nginx/html

COPY nginx.conf  /etc/nginx/conf.d/default.conf

EXPOSE 80
