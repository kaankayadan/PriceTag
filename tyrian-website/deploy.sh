#!/bin/bash
# ============================================
# Tyrian Global — VPS Deploy Script
# www.tyrian-global.com
# Kullanim: sudo bash deploy.sh
# ============================================

set -e

# ---------- Renkler ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${CYAN}"
echo "  ████████╗██╗   ██╗██████╗ ██╗ █████╗ ███╗  ██╗"
echo "     ██╔══╝╚██╗ ██╔╝██╔══██╗██║██╔══██╗████╗ ██║"
echo "     ██║    ╚████╔╝ ██████╔╝██║███████║██╔██╗██║"
echo "     ██║     ╚██╔╝  ██╔══██╗██║██╔══██║██║╚████║"
echo "     ██║      ██║   ██║  ██║██║██║  ██║██║ ╚███║"
echo "     ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚══╝"
echo -e "${NC}"
echo -e "  ${YELLOW}Global Trading — Deploy Script${NC}"
echo    "  =================================="
echo

# ---------- Root kontrolü ----------
if [ "$EUID" -ne 0 ]; then
  error "Bu script'i sudo ile çalıştırın: sudo bash deploy.sh"
fi

# ---------- Değişkenler ----------
DOMAIN="tyrian-global.com"
WWW_DOMAIN="www.tyrian-global.com"
WEB_ROOT="/var/www/tyrian-global"
NGINX_CONF="/etc/nginx/sites-available/tyrian-global"
REPO_URL="https://github.com/kaankayadan/PriceTag.git"
BRANCH="claude/tyrian-global-website-44GRN"
SITE_SRC="tyrian-website"

# ---------- Adım 1: Sistem güncellemesi ----------
info "Sistem güncelleniyor..."
apt-get update -qq
apt-get install -y -qq nginx git curl certbot python3-certbot-nginx > /dev/null 2>&1
success "Nginx, git, certbot kuruldu/güncellendi"

# ---------- Adım 2: Web klasörü ----------
info "Web root hazırlanıyor: $WEB_ROOT"
mkdir -p "$WEB_ROOT"

# ---------- Adım 3: Siteyi clone/güncelle ----------
TEMP_DIR=$(mktemp -d)
info "Repo klonlanıyor..."
git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null || {
  error "Repo klonlanamadı. İnternet bağlantısını ve repo erişimini kontrol edin."
}
rsync -a --delete "$TEMP_DIR/repo/$SITE_SRC/" "$WEB_ROOT/"
rm -rf "$TEMP_DIR"
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
success "Site dosyaları $WEB_ROOT dizinine kopyalandı"

# ---------- Adım 4: Nginx config ----------
info "Nginx konfigürasyonu yazılıyor..."
cat > "$NGINX_CONF" << 'NGINXCONF'
server {
    listen 80;
    listen [::]:80;
    server_name tyrian-global.com www.tyrian-global.com;

    root /var/www/tyrian-global;
    index index.html;

    # Gzip sıkıştırma
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript
               application/javascript application/xml application/json
               image/svg+xml;

    # Cache headers — statik dosyalar
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # HTML dosyaları — cache'leme
    location ~* \.html$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }

    # Güvenlik başlıkları
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # URL yönlendirme
    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    # Özel 404 sayfası (ileride eklenebilir)
    error_page 404 /index.html;

    # .htaccess ve gizli dosyalara erişim engeli
    location ~ /\. {
        deny all;
    }

    # Favicon ve robots.txt için log kapatma
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { log_not_found off; access_log off; allow all; }
}
NGINXCONF
success "Nginx config yazıldı: $NGINX_CONF"

# ---------- Adım 5: Nginx'i etkinleştir ----------
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/tyrian-global 2>/dev/null || true
# Varsa default siteyi devre dışı bırak (opsiyonel)
# rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx
success "Nginx reload edildi"

# ---------- Adım 6: SSL (Certbot) ----------
echo
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  SSL Sertifikası (Let's Encrypt)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
read -p "SSL sertifikası şimdi kurulsun mu? (Domainlerin bu sunucuya yönlendirilmiş olması gerekir) [y/N]: " SSL_CHOICE

if [[ "$SSL_CHOICE" =~ ^[Yy]$ ]]; then
  read -p "E-posta adresiniz (Let's Encrypt bildirimleri için): " EMAIL_ADDR
  if [ -n "$EMAIL_ADDR" ]; then
    certbot --nginx \
      -d "$DOMAIN" -d "$WWW_DOMAIN" \
      --non-interactive \
      --agree-tos \
      --email "$EMAIL_ADDR" \
      --redirect
    success "SSL sertifikası kuruldu! Site HTTPS üzerinden erişilebilir."

    # Certbot otomatik yenileme için cron kontrolü
    systemctl enable certbot.timer 2>/dev/null || \
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    success "SSL otomatik yenileme ayarlandı"
  else
    warn "E-posta boş bırakıldı, SSL kurulmadı. Sonradan: sudo certbot --nginx -d tyrian-global.com -d www.tyrian-global.com"
  fi
else
  warn "SSL kurulmadı. Domain yönlendirmesi tamamlanınca: sudo certbot --nginx -d $DOMAIN -d $WWW_DOMAIN"
fi

# ---------- Adım 7: robots.txt ----------
cat > "$WEB_ROOT/robots.txt" << 'ROBOTS'
User-agent: *
Allow: /

Sitemap: https://www.tyrian-global.com/sitemap.xml
ROBOTS
success "robots.txt oluşturuldu"

# ---------- Adım 8: Sitemap ----------
cat > "$WEB_ROOT/sitemap.xml" << 'SITEMAP'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://www.tyrian-global.com/</loc><priority>1.0</priority><changefreq>monthly</changefreq></url>
  <url><loc>https://www.tyrian-global.com/about.html</loc><priority>0.8</priority><changefreq>monthly</changefreq></url>
  <url><loc>https://www.tyrian-global.com/products.html</loc><priority>0.9</priority><changefreq>monthly</changefreq></url>
  <url><loc>https://www.tyrian-global.com/services.html</loc><priority>0.8</priority><changefreq>monthly</changefreq></url>
  <url><loc>https://www.tyrian-global.com/contact.html</loc><priority>0.7</priority><changefreq>yearly</changefreq></url>
</urlset>
SITEMAP
success "sitemap.xml oluşturuldu"

# ---------- Sonuç ----------
echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  DEPLOY TAMAMLANDI!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "  Site:       ${CYAN}http://$DOMAIN${NC}"
echo -e "  Web Root:   ${CYAN}$WEB_ROOT${NC}"
echo -e "  Nginx Conf: ${CYAN}$NGINX_CONF${NC}"
echo
echo -e "  ${YELLOW}Sonraki adımlar:${NC}"
echo    "  1. DNS: A kaydı → bu sunucunun IP adresi"
echo    "     tyrian-global.com    → VPS_IP"
echo    "     www.tyrian-global.com → VPS_IP"
echo    "  2. DNS yayıldıktan sonra SSL kurun (certbot)"
echo    "  3. info@tyrian-global.com e-posta adresi oluşturun"
echo
echo -e "  ${YELLOW}Güncelleme için:${NC} sudo bash $0"
echo
