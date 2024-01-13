#! /usr/bin/env bash

build_${CPP_LIB}_cpp() {

    set -Eeuo pipefail;

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    local verbose="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            v|verbose                         |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";

    configure-${CPP_LIB}-cpp ${verbose:+-v} ${__rest__[@]};

    eval "$(                                              \
        rapids-get-num-archs-jobs-and-load ${__rest__[@]} \
      | xargs -r -d'\n' -I% echo -n local %\;             \
    )";

    # Build C++ lib
    time (
        cmake                               \
        --build "${CPP_SRC}/build/latest"   \
        ${verbose:+--verbose}               \
        -j${n_jobs}                         \
        --                                  \
        -l${n_load}                         ;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} build time:";
    ) 2>&1;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${CPP_LIB}_cpp "$@";
