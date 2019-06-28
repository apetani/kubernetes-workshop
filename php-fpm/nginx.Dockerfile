FROM nginx:1.15.12
ARG ENV

EXPOSE 80
ADD /code /code

