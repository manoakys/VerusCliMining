cat << 'EOF' > termux-install.sh
#!/usr/bin/env sh

termux-wake-lock

export DEBIAN_FRONTEND=noninteractive
APT_OPTS="-y -o Dpkg::Options::=--force-confnew"

pkg update $APT_OPTS && pkg upgrade $APT_OPTS
pkg install $APT_OPTS curl libcurl libjansson git screen nano jq wget mc openssl termux-api

mkdir -p ~/ccminer
cd ~/ccminer

GITHUB_RELEASE_JSON=$(curl --silent "https://api.github.com/repos/Oink70/Android-Mining/releases?per_page=1" | jq -c '[.[] | del (.body)]' 2>/dev/null)
GITHUB_DOWNLOAD_URL=$(echo "$GITHUB_RELEASE_JSON" | jq -r ".[0].assets | .[] | .browser_download_url" 2>/dev/null)

if [ -z "$GITHUB_DOWNLOAD_URL" ] || [ "$GITHUB_DOWNLOAD_URL" = "null" ]; then
    echo "GitHub API request failed or rate-limited. Falling back to direct URL..."
    GITHUB_DOWNLOAD_URL="https://github.com/Oink70/Android-Mining/releases/latest/download/ccminer"
fi

echo "Downloading ccminer binary..."
wget "$GITHUB_DOWNLOAD_URL" -O ~/ccminer/ccminer
wget https://raw.githubusercontent.com/manoakys/VerusCliMining/main/config.json -O ~/ccminer/config.json
chmod +x ~/ccminer/ccminer

cat << 'STARTEOF' > ~/ccminer/start.sh
#!/usr/bin/env sh
termux-wake-lock
screen -S CCminer -X quit 1>/dev/null 2>&1
screen -wipe 1>/dev/null 2>&1
screen -dmS CCminer 1>/dev/null 2>&1
screen -S CCminer -X stuff "~/ccminer/ccminer -c ~/ccminer/config.json\n" 1>/dev/null 2>&1
printf '\nMining started.\n'
printf '===============\n'
printf '\nManual:\n'
printf 'start: ~/ccminer/start.sh\n'
printf 'stop: screen -X -S CCminer quit\n'
printf '\nmonitor mining: screen -x CCminer\n'
printf "exit monitor: 'CTRL-a' followed by 'd'\n\n"
STARTEOF

chmod +x ~/ccminer/start.sh

echo "Setup complete."
echo "Edit your config file with: mcedit ~/ccminer/config.json"
EOF

chmod +x termux-install.sh && ./termux-install.sh
