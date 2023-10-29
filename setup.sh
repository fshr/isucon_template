#!/usr/bin/bash
set -e

# config
users=() # e.g. ('XXXX' 'YYYY' 'ZZZZ')
target_dir='XXX' # e.g. isucon12-final
target_dir='XXX' # e.g. isucon12-final
home_dir='/home/isucon/'
ssh_key="github"
git_origin_url="XXX"

# varidation
if [[ ${#users[@]} -eq 0 || "${target_dir}" = 'XXX' || ${git_origin_url} = 'XXX' ]]
then
    echo "unset parameters found"
    exit 1
fi
echo "parameter validation passed"

if [[ ! -f "${home_dir}.ssh/${ssh_key}" ]]
then
    echo "ssh key not found"
    exit 1
fi

# setup ssh key config
if ! [[ -f "${home_dir}.ssh/config" ]]
then
    touch "${home_dir}.ssh/config"
    echo "create ssh config file"
fi

if ! [[ `grep -E 'github.com' "${home_dir}.ssh/config"` ]]
then
    echo "
Host github.com
  User git
  Hostname github.com
  IdentityFile ${home_dir}.ssh/github
" >> "${home_dir}.ssh/config"
    echo "add github settings"
fi

# setup git config
cd "${home_dir}${target_dir}"
if [[ ! -d .git ]]
then
    git init
    git config user.name "isucon"
    git config user.email "you@example.com"
    git remote add origin "${git_origin_url}"
    git commit --allow-empty -m "Empty-Commit"
    echo "git setup completed"
fi

# setup user directory
for user in ${users[@]}; do
    if [[ ! -d "${home_dir}${target_dir}-${user}" ]]
    then
        cp -r "${home_dir}${target_dir}" "${home_dir}${target_dir}-${user}"
        sleep 5
        cd "${home_dir}${target_dir}-${user}"
        git branch "${user}"
        git checkout "${user}"
    fi
done

