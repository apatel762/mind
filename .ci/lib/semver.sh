#!/usr/bin/env bash
# Original script: https://raw.githubusercontent.com/bb010g/Semver.sh/refs/heads/master/Semver.sh

# This snippet helps us find out who our actual $SELF is.
# Also it ensures that the script is sourced and never run directly.
(return 0 2>/dev/null)
SOURCED=$?
if [ $SOURCED -ne 0 ]; then
    echo "This script is intended to be sourced, not executed directly."
    exit 1
elif [ -n "${BASH_SOURCE[*]}" ]; then
    SOURCE_RELATIVE="${BASH_SOURCE[1]}"
else
    SOURCE_RELATIVE=$(caller 0 | awk '{print $2}')
fi
SELF=$(cd "$(dirname "$SOURCE_RELATIVE")" && pwd)/$(basename "$SOURCE_RELATIVE")
export SELF

# DESC:
#   Validate a version.
#     $1 is invalid  -> print error message and return
#     Else           -> print version
# USAGE:
#   1)
#     Semver::is_valid "1.2.3" &>/dev/null
#   2)
#     declare -a v
#     eval "$(Semver::is_valid "1.2.11-alpha+001" v)"
#     echo "major=${v[0]}, minor=${v[1]}, patch=${v[2]}, pre-release=${v[3]}, build metadata=${v[4]}"
Semver::is_valid() {
  # shellcheck disable=SC2064
  trap "$(shopt -p extglob)" RETURN
  shopt -s extglob

  declare normal=${1%%[+-]*}
  declare extra=${1:${#normal}}

  declare major=${normal%%.*}
  if [[ $major != +([0-9]) ]]; then echo "Semver::is_valid: invalid major: $major" >&2; return 1; fi
  normal=${normal:${#major}+1}
  declare minor=${normal%%.*}
  if [[ $minor != +([0-9]) ]]; then echo "Semver::is_valid: invalid minor: $minor" >&2; return 1; fi
  declare patch=${normal:${#minor}+1}
  if [[ $patch != +([0-9]) ]]; then echo "Semver::is_valid: invalid patch: $patch" >&2; return 1; fi

  declare -r ident="+([0-9A-Za-z-])"
  declare pre=${extra%%+*}
  declare pre_len=${#pre}
  if [[ $pre_len -gt 0 ]]; then
    pre=${pre#-}
    if [[ $pre != $ident*(.$ident) ]]; then echo "Semver::is_valid: invalid pre-release: $pre" >&2; return 1; fi
  fi
  declare build=${extra:pre_len}
  if [[ ${#build} -gt 0 ]]; then
    build=${build#+}
    if [[ $build != $ident*(.$ident) ]]; then echo "Semver::is_valid: invalid build metadata: $build" >&2; return 1; fi
  fi

  if [[ -n ${2+x} ]]; then
    echo "$2=(${major@Q} ${minor@Q} ${patch@Q} ${pre@Q} ${build@Q})"
  else
    echo "$1"
  fi
}

# DESC:
#   Compare two semantic versions.
#     For $1
#       if more recent than $2  -> return 1
#       if same as $2           -> return 0
#       if older than $2        -> return -1
# USAGE:
#   Semver::compare $ver_a $ver_b 
Semver::compare() {
  declare -a x y
  eval "$(Semver::is_valid "$1" x)"
  eval "$(Semver::is_valid "$2" y)"

  declare x_i y_i i
  for i in 0 1 2; do
    x_i=${x[i]}; y_i=${y[i]}
    if [[ $x_i -eq $y_i ]]; then continue; fi
    if [[ $x_i -gt $y_i ]]; then echo 1; return; fi
    if [[ $x_i -lt $y_i ]]; then echo -1; return; fi
  done

  x_i=${x[3]}; y_i=${y[3]}
  if [[ -z $x_i && $y_i ]]; then echo 1; return; fi
  if [[ $x_i && -z $y_i ]]; then echo -1; return; fi

  declare -a x_pre; declare x_len
  declare -a y_pre; declare y_len
  IFS=. read -ra x_pre <<< "$x_i"; x_len=${#x_pre[@]}
  IFS=. read -ra y_pre <<< "$y_i"; y_len=${#y_pre[@]}

  if (( x_len > y_len )); then echo 1; return; fi
  if (( x_len < y_len )); then echo -1; return; fi

  for (( i=0; i < x_len; i++ )); do
    x_i=${x_pre[i]}; y_i=${y_pre[i]}
    if [[ $x_i = "$y_i" ]]; then continue; fi

    declare num_x num_y
    num_x=$([[ $x_i = +([0-9]) ]] && echo "$x_i")
    num_y=$([[ $y_i = +([0-9]) ]] && echo "$y_i")
    if [[ $num_x && $num_y ]]; then
      if [[ $x_i -gt $y_i ]]; then echo 1; return; fi
      if [[ $x_i -lt $y_i ]]; then echo -1; return; fi
    else
      if [[ $num_y ]]; then echo 1; return; fi
      if [[ $num_x ]]; then echo -1; return; fi
      if [[ $x_i > $y_i ]]; then echo 1; return; fi
      if [[ $x_i < $y_i ]]; then echo -1; return; fi
    fi
  done

  echo 0
}

# DESC:
#   Check if a given version represents a prerelease.
#     For $1
#       is prerelease version?  -> return "yes"
#       else                    -> return "no"
# USAGE:
#   Semver::is_prerelease "1.4.1-beta"
Semver::is_prerelease() {
  declare -a ver; eval "$(Semver::is_valid "$1" ver)"
  [[ ${ver[3]} ]] && echo yes || echo no
}

Semver::pretty() {
  declare out="$1.$2.$3"
  [[ $4 ]] && out+="-$4"
  [[ $5 ]] && out+="+$5"
  echo "$out"
}

# DESC:
#   Given a semantic version string, increment the major version.
#   Note that any prerelease info or build metadata is stripped!
#     For $1
#       "1.0.0"          -> "2.0.0"
#       "1.0.0-alpha"    -> "2.0.0"
#       "1.0.0-alpha+2"  -> "2.0.0"
# USAGE:
#   ver_a=$(Semver::increment_major "$ver_a")
Semver::increment_major() {
  declare -a ver; eval "$(Semver::is_valid "$1" ver)"
  echo "$((ver[0]+1)).0.0"
}

# DESC:
#   Given a semantic version string, increment the minor version.
#   Note that any prerelease info or build metadata is stripped!
#     For $1
#       "1.0.0"          -> "1.1.0"
#       "1.0.0-alpha"    -> "1.1.0"
#       "1.0.0-alpha+2"  -> "1.1.0"
# USAGE:
#   ver_a=$(Semver::increment_minor "$ver_a")
Semver::increment_minor() {
  declare -a ver; eval "$(Semver::is_valid "$1" ver)"
  echo "${ver[0]}.$((ver[1]+1)).0"
}

# DESC:
#   Given a semantic version string, increment the patch version.
#   Note that any prerelease info or build metadata is stripped!
#     For $1
#       "1.0.0"          -> "1.0.1"
#       "1.0.0-alpha"    -> "1.0.1"
#       "1.0.0-alpha+2"  -> "1.0.1"
# USAGE:
#   ver_a=$(Semver::increment_minor "$ver_a")
Semver::increment_patch() {
  declare -a ver; eval "$(Semver::is_valid "$1" ver)"
  echo "${ver[0]}.${ver[1]}.$((ver[2]+1))"
}

# DESC:
#   Update the prerelease information for a version string
#     For $1 with prerelease "alpha"
#       "1.0.0"             -> "1.0.0-alpha"
#       "1.0.0-poc"         -> "1.0.0-alpha"
#       "1.0.0-something+2" -> "1.0.0-alpha+2"
# USAGE:
#   ver_a=$(Semver::set_pre "$ver_a" 'alpha')
Semver::set_pre() {
  declare -r ident="+([0-9A-Za-z-])"
  if [[ $2 != ?($ident*(.$ident)) ]]; then echo "Semver::set_pre: invalid pre-release: $2" >&2; return 1; fi
  declare -a ver; eval "$(Semver::is_valid "$1" ver)"
  Semver::pretty "${ver[0]}" "${ver[1]}" "${ver[2]}" "$2" "${ver[4]}"
}

# DESC:
#   Update the prerelease information for a version string
#     For $1 with build "amd64"
#       "1.0.0"             -> "1.0.0+amd64"
#       "1.0.0-poc"         -> "1.0.0-poc+amd64"
#       "1.0.0-something+2" -> "1.0.0-something+amd64"
# USAGE:
#   ver_a=$(Semver::set_build "$ver_a" 'amd64')
Semver::set_build() {
  declare -r ident="+([0-9A-Za-z-])"
  if [[ $2 != ?($ident*(.$ident)) ]]; then echo "Semver::set_build: invalid build metadata: $2" >&2; return 1; fi
  declare -a ver; eval "$(Semver::is_valid "$1" ver)"
  Semver::pretty "${ver[0]}" "${ver[1]}" "${ver[2]}" "${ver[3]}" "$2"
}
