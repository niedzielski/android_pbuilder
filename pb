#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# pb
# Stephen Niedzielski
# Copyright 2012 Stephen Niedzielski. Licensed under GPLv3+.

# ------------------------------------------------------------------------------
#set -e
#pipefail?
#...

declare base=lucid_lynx_64
declare dist=lucid # lsb_release --short --codename
declare arch=amd64 # dpkg --print-architecture
declare base_tgz="$base.tgz"

# ------------------------------------------------------------------------------
pb_create_base()
{
  # GB
  # From http://web.archive.org/web/20110707142234/http://source.android.com/source/initializing.html
  # (oldest version of http://s.android.com/source/initializing.html).
  #android_pkgs="git-core gnupg flex bison gperf build-essential \
  #  zip curl zlib1g-dev libc6-dev lib32ncurses5-dev \
  #  x11proto-core-dev libx11-dev lib32readline5-dev lib32z-dev \
  #  libgl1-mesa-dev g++-multilib tofrodos unzip" # TODO: is python-lxml necessary?

  # JB requirements from http://s.android.com/source/initializing.html.
  declare -r extra_packages="
    git-core gnupg flex bison gperf build-essential
    zip curl zlib1g-dev libc6-dev lib32ncurses5-dev
    x11proto-core-dev libx11-dev lib32readline5-dev lib32z-dev
    libgl1-mesa-dev g++-multilib tofrodos
    libxml2-utils xsltproc unzip file python-lxml
  " && # HACK: ia32-libs, mingw32, and python-markdown unneeded? Add unzip and
       # file for build. Add python-lxml for repo.

  sudo pbuilder --create \
    --distribution "$dist" \
    --architecture "$arch" \
    --extrapackages "$extra_packages" \
    --basetgz "$base_tgz" &&

  declare -r init_script="$(mktemp)" &&
  cat <<EOF >| "$init_script" &&
  # HACK: recommended but target nonexistent.
  # ln -s /usr/lib32/mesa/libGL.so.1 /usr/lib32/mesa/libGL.so &&

  curl https://dl-ssl.google.com/dl/googlesource/git-repo/repo > /usr/bin/repo &&
  chmod +x /usr/bin/repo &&

  # HACK: the Sun JDK is no longer in Ubuntu's main package repository.
  echo 'deb http://ppa.launchpad.net/sun-java-community-team/sun-java6/ubuntu lucid main' >> /etc/apt/sources.list &&
  apt-get update &&
  echo "sun-java6-jdk shared/accepted-sun-dlj-v1-1 boolean true" | debconf-set-selections &&
  apt-get install sun-java6-jdk &&
EOF
  echo "echo \"pb-$base\" > /etc/debian_chroot" >> "$init_script"

  sudo pbuilder --execute --save-after-exec --basetgz "$base_tgz" "$init_script"
  rm -f "$init_script"

  # git init
  # aosp_init_pbuilder
  # sudo chown stephen:stephen "$base.tgz"
  # git add "$base.tgz"
  # git commit
}

pb_login()
{
  # HACK: assumed all live under /etc/.
  local input_files=(
    /etc/group
    /etc/hosts
    /etc/passwd
    /etc/resolv.conf
    /etc/shadow
    /etc/sudoers
  )

  local bind_mounts=(
    /home
  )

  sudo pbuilder --login \
    $(printf -- "--inputfile %s " "${input_files[@]}") \
    --bindmounts "${bind_mounts[*]}" \
    --basetgz "$base.tgz"

  # TODO: we need a login hook to copy /tmp/buildd/* to /etc/, change the
  # working directory to the Android workspace root, change user to
  # "$(stat -c %U "$PWD")", source build/envsetup.sh, initialize ccache size,
  # and perform any other setup needed.
}

# TODO: time make -j -l"$load_avg"|& tee log/build_$(timestamp).log
# TODO: pb_exec.
# TODO: pb_clean.
# TODO: pb_clobber / pb_superclobber. repo forall -c 'git reset --hard HEAD && git clean -dfqx' && rm -rf "$OUT_DIR_COMMON_BASE". Also consider simulating a clone or listing all files and deleting the cruft.
# TODO: usage.

# ------------------------------------------------------------------------------
declare load_avg="$(grep -c ^processor /proc/cpuinfo)"
declare ccache_size=50G

# ------------------------------------------------------------------------------
main()
{
  # TODO: process options to determine if mode is create base, login, etc.
  # sudo pbuilder --login --save-after-login --basetgz "$base.tgz"
  # sudo pbuilder --login --bindmounts /home --basetgz "$base.tgz"
  :
}

# ------------------------------------------------------------------------------
if [[ "$BASH_SOURCE" == "$0" ]]
then
  time main "$@"
fi
