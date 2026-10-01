cat << 'EOF' > termux-install.sh
#!/usr/bin/env sh

termux-wake-lock

export DEBIAN_FRONTEND=noninteractive
APT_OPTS="-y -o Dpkg::Options::=--force-confnew"

echo "1. Updating packages and installing repositories..."
pkg update $APT_OPTS && pkg upgrade $APT_OPTS
pkg install $APT_OPTS tur-repo glibc-repo
pkg install $APT_OPTS curl libcurl libjansson git screen nano jq wget mc binutils tar glibc

echo "2. Setting up ccminer folder..."
mkdir -p ~/ccminer
cd ~/ccminer

echo "3. Downloading ccminer binary and config..."
GITHUB_RELEASE_JSON=$(curl --silent "https://api.github.com/repos/Oink70/Android-Mining/releases?per_page=1" | jq -c '[.[] | del (.body)]' 2>/dev/null)
GITHUB_DOWNLOAD_URL=$(echo "$GITHUB_RELEASE_JSON" | jq -r ".[0].assets | .[] | .browser_download_url" 2>/dev/null)

if [ -z "$GITHUB_DOWNLOAD_URL" ] || [ "$GITHUB_DOWNLOAD_URL" = "null" ]; then
    echo "GitHub API request failed. Falling back to direct URL..."
    GITHUB_DOWNLOAD_URL="https://github.com/Oink70/Android-Mining/releases/latest/download/ccminer"
fi

wget "$GITHUB_DOWNLOAD_URL" -O ~/ccminer/ccminer
wget https://raw.githubusercontent.com/manoakys/VerusCliMining/main/config.json -O ~/ccminer/config.json
chmod +x ~/ccminer/ccminer

echo "4. Patching missing glibc libraries (OpenSSL 1.1 & OpenMP)..."
mkdir -p $TMPDIR/ccminer_deps
cd $TMPDIR/ccminer_deps

# Extract and patch OpenSSL 1.1
wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_arm64.deb -O libssl1.1.deb
ar x libssl1.1.deb
tar -xf data.tar.xz
cp -L usr/lib/aarch64-linux-gnu/libcrypto.so.1.1 $PREFIX/glibc/lib/
cp -L usr/lib/aarch64-linux-gnu/libssl.so.1.1 $PREFIX/glibc/lib/
chmod 755 $PREFIX/glibc/lib/libcrypto.so.1.1 $PREFIX/glibc/lib/libssl.so.1.1
rm -rf libssl1.1.deb data.tar.xz control.tar.gz debian-binary usr

# Extract and patch OpenMP 5
wget http://snapshot.debian.org/archive/debian/20230501T030325Z/pool/main/l/llvm-toolchain-14/libomp5-14_14.0.6-12_arm64.deb -O libomp.deb
ar x libomp.deb
tar -xf data.tar.xz
rm -f $PREFIX/glibc/lib/libomp.so.5
cp -L usr/lib/aarch64-linux-gnu/libomp.so.5 $PREFIX/glibc/lib/libomp.so.5
chmod 755 $PREFIX/glibc/lib/libomp.so.5

# Cleanup temp files
cd ~/ccminer
rm -rf $TMPDIR/ccminer_deps

echo "5. Creating start.sh script..."
cat << 'STARTEOF' > ~/ccminer/start.sh
#!/usr/bin/env sh
termux-wake-lock
screen -S CCminer -X quit 1>/dev/null 2>&1
screen -wipe 1>/dev/null 2>&1
screen -dmS CCminer 1>/dev/null 2>&1
screen -S CCminer -X stuff "grun ~/ccminer/ccminer -c ~/ccminer/config.json\n" 1>/dev/null 2>&1
printf '\nMining started.\n'
printf '===============\n'
printf '\nManual:\n'
printf 'start: ~/ccminer/start.sh\n'
printf 'stop: screen -X -S CCminer quit\n'
printf '\nmonitor mining: screen -x CCminer\n'
printf "exit monitor: 'CTRL-a' followed by 'd'\n\n"
STARTEOF

chmod +x ~/ccminer/start.sh

echo "========================================="
echo "Setup complete! All dependencies patched."
echo "Edit your config file with: mcedit ~/ccminer/config.json"
echo "To start mining, run: ~/ccminer/start.sh"
echo "========================================="
EOF
