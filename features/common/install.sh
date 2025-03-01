#! /usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# export bash utility functions
source "$src/utilities.sh";

# install /etc/skel
cp -r "$src/etc/skel" /etc/;
# install /etc/bash.bash_env
cp "$src/etc/bash.bash_env" /etc/;
chown root:root /etc/bash.bash_env;
chmod u+rwx,g+rwx,o+rx /etc/bash.bash_env;

unset src;

# Store and reset BASH_ENV in /etc/profile so lmod doesn't steal it from us.
# Our `/etc/bash.bash_env` will source lmod's $BASH_ENV at the end.
append_to_etc_profile "$(cat <<EOF
export BASH_ENV_ETC_PROFILE="\$BASH_ENV";
export BASH_ENV=/etc/bash.bash_env;
EOF
)";

if ! grep -qE '^BASH_ENV=/etc/bash.bash_env$' /etc/environment; then
    echo "BASH_ENV=/etc/bash.bash_env" >> /etc/environment;
fi

# Remove unnecessary "$HOME/.local/bin" at the end of the path
if grep -qxF 'if [[ "${PATH}" != *"$HOME/.local/bin"* ]]; then export PATH="${PATH}:$HOME/.local/bin"; fi' /etc/bash.bashrc; then
   cat /etc/bash.bashrc \
 | grep -vxF 'if [[ "${PATH}" != *"$HOME/.local/bin"* ]]; then export PATH="${PATH}:$HOME/.local/bin"; fi' \
 > /etc/bash.bashrc.new \
&& mv /etc/bash.bashrc{.new,};
fi

cp /etc/skel/.profile /root/.profile;
echo 'mesg n 2> /dev/null || true' >> /root/.profile;
