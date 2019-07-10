FROM nginx:1.15.12

EXPOSE 80
COPY /code /code
# COPY /site.conf /etc/nginx/conf.d/default.conf
