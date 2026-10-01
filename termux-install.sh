#!/usr/bin/env sh

# Acquire wake lock to prevent Android from sleeping during operation
termux-wake-lock

# Update repositories and upgrade packages
pkg update -y && pkg upgrade -y

# Install required dependencies natively for Termux
pkg install -y curl libcurl libjansson git screen nano jq wget mc openssl-1.1 termux-api

# Setup miner directory
mkdir -p ~/ccminer
cd ~/ccminer

# Fetch latest release assets from GitHub
GITHUB_RELEASE_JSON=$(curl --silent "https://api.github.com/repos/Oink70/Android-Mining/releases?per_page=1" | jq -c '[.[] | del (.body)]')
GITHUB_DOWNLOAD_URL=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets | .[] | .browser_download_url")
GITHUB_DOWNLOAD_NAME=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets | .[] | .name")

echo "Downloading latest release: $GITHUB_DOWNLOAD_NAME"

wget ${GITHUB_DOWNLOAD_URL} -O ~/ccminer/ccminer
wget https://raw.githubusercontent.com/manoakys/VerusCliMining/main/config.json -O ~/ccminer/config.json
chmod +x ~/ccminer/ccminer

# Create the start script adapted for Termux
cat << 'EOF' > ~/ccminer/start.sh
#!/usr/bin/env sh
termux-wake-lock
# exit existing screens with the name CCminer
screen -S CCminer -X quit 1>/dev/null 2>&1
# wipe any existing (dead) screens
screen -wipe 1>/dev/null 2>&1
# create new disconnected session CCminer
screen -dmS CCminer 1>/dev/null 2>&1
# run the miner
screen -S CCminer -X stuff "~/ccminer/ccminer -c ~/ccminer/config.json\n" 1>/dev/null 2>&1
printf '\nMining started.\n'
printf '===============\n'
printf '\nManual:\n'
printf 'start: ~/ccminer/start.sh\n'
printf 'stop: screen -X -S CCminer quit\n'
printf '\nmonitor mining: screen -x CCminer\n'
printf "exit monitor: 'CTRL-a' followed by 'd'\n\n"
EOF

chmod +x ~/ccminer/start.sh

echo "Setup nearly complete."
echo "Edit the config with \"mcedit ~/ccminer/config.json\""
echo "Go to line 15 and change your worker name."
echo "Use \"<CTRL>-x\" to exit, respond with \"y\" to save, and press \"Enter\"."