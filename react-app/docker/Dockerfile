FROM node:8.16.0 as npm
COPY . /app
WORKDIR /app
RUN npm install
RUN npm run build

FROM nginx:1.15.12
COPY --from=npm /app/build /usr/share/nginx/html
EXPOSE 80