#!/usr/bin/bash

#expac -S %v w3m | awk -F - '{print $1}'
#cower -i w3m-mouse --format "%v"

source info-database.sh

[[ -z $AURDIR ]] && export AURDIR="$(pwd)"

getCurrentVersion()
{
  cower -i --format '%v' "$1" 2>/dev/null |  awk -F - '{print $1}'
  [[ ${PIPESTATUS[0]} -eq 0 ]] ||  echo "??"
}

isOutOfDate()
{
  cower -i --format '%t' "$1" 2>/dev/null
  [[ ${PIPESTATUS[0]} -eq 0 ]] ||  echo "??"
}

checkExpac()
{
  db_var="EXPAC_VER_$1"
  curver="$(expac -S %v $1)"
  oldver="${!db_var}"
  if [[ $? -eq 0 ]]; then
    if [[ $oldver != $curver ]]; then
      echo "$oldver -> $curver"
    else
      echo "updated"
    fi
  else
    echo "[!]"
  fi
}

needsUpdate()
{
  case $1 in
    "w3m-mouse")
      checkExpac w3m
      ;;
    "makedumpfile")
      ;;
    "calculix")
      ;;
    "calculix-doc")
      ;;
    *)
      echo "??"
      ;;
  esac
}

for x in "$AURDIR"/*/; do
  pkgname="$(basename $x)"
  pkgver="$(getCurrentVersion $pkgname)"
  iood="$(isOutOfDate $pkgname)"
  needupd="$(needsUpdate $pkgname)"
  printf "%3s -- %-20s\t(%s)\t[%s]\n" "$iood" "$pkgname" "$pkgver" "$needupd"
done

