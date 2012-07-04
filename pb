#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# pb
# Stephen Niedzielski
# Copyright 2012 Stephen Niedzielski. Licensed under GPLv3+.

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
  declare -r base=lucid-lynx-64 &&
  declare -r dist=lucid && # lsb_release --short --codename
  declare -r arch=amd64 && # dpkg --print-architecture
  declare -r base_tgz="$base.tgz" &&

  declare -r extra_packages="
    git-core gnupg flex bison gperf build-essential
    zip curl zlib1g-dev libc6-dev lib32ncurses5-dev
    x11proto-core-dev libx11-dev lib32readline5-dev lib32z-dev
    libgl1-mesa-dev g++-multilib tofrodos
    libxml2-utils xsltproc unzip
  " && # HACK: ia32-libs, mingw32, and python-markdown unneeded? Add unzip.

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
  apt-get install sun-java6-jdk
EOF
  sudo pbuilder --execute --basetgz "$base_tgz" "$init_script"
  rm -f "$init_script"
}
