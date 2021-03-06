git clone --no-hardlinks /mnt/sdb2/lsk.bak lsk
cd lsk
git remote remove origin
git remote add origin git://git.linaro.org/kernel/linux-linaro-stable.git
git br --set-upstream-to=origin/linux-linaro-lsk linux-linaro-lsk
git remote set-url --push origin ssh://git@git.linaro.org/kernel/linux-linaro-stable.git 

git remote add linus git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git 
git remote add arm64 git://git.kernel.org/pub/scm/linux/kernel/git/arm64/linux.git
git remote add linux-next git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
git remote add lts -t linux-3.10.y git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
git remote set-branches --add lts linux-3.14.y

git remote update

ln -s /home/alexs/lsk/scripts/make-android.sh
ln -s /home/alexs/boards/mt8173/patches-upstream/
ln -s /home/alexs/lsk/scripts/test-making.sh
ln -s /home/alexs/lsk/scripts/update-pb.sh
ln -s /home/alexs/boards/FVP/OE/arm64-OE-kernel.sh
ln -s /home/alexs/lsk/scripts/get-to-cc.sh
ln -s /home/alexs/lsk/scripts/insertcc2patch.sh

