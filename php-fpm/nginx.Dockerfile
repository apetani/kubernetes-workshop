FROM nginx:1.15.12
ARG ENV

EXPOSE 80
ADD /code /code
ADD /.${ENV}.site.conf /etc/nginx/conf.d/default.conf
