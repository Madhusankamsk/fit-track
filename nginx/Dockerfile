FROM nginx:alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY cors-headers.conf /etc/nginx/cors-headers.conf
COPY cors-preflight.conf /etc/nginx/cors-preflight.conf
