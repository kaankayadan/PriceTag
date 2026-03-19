FROM nginx:alpine

# Nginx config kopyala
COPY nginx.docker.conf /etc/nginx/conf.d/default.conf

# Site dosyalarini kopyala
COPY . /usr/share/nginx/html/

# Gereksiz dosyalari temizle (sadece web dosyalari kalsın)
RUN rm -f /usr/share/nginx/html/Dockerfile \
          /usr/share/nginx/html/docker-compose.yml \
          /usr/share/nginx/html/nginx.conf \
          /usr/share/nginx/html/nginx.docker.conf \
          /usr/share/nginx/html/deploy.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider http://localhost/ || exit 1
