curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

docker run -d \
--name mtproxy \
--restart=always \
-e domain="cloudflare.com" \
-e secret="548593a9c0688f4f7d9d55899897d964" \
-e ip_white_list="OFF" \
-p 8888:80 \
-p 8443:443 \
ellermister/mtproxy



docker logs -f mtproxy
