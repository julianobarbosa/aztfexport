#!/bin/bash

MYDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLDIR="$MYDIR/generate-provider-resource-mapping"
MYNAME="$(basename "${BASH_SOURCE[0]}")"
ROOTDIR="$MYDIR/../.."

die() {
    echo "$@" >&2
    exit 1
}

usage() {
    cat << EOF
Usage: ./run.sh [options] 

Options:
    -h|--help           show this message

Arguments:
    provider_dir        The path to the AzureRM provider repo
EOF
}

main() {
    while :; do
        case $1 in
            -h|--help)
                usage
                exit 1
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    local expect_n_arg
    expect_n_arg=1
    [[ $# = "$expect_n_arg" ]] || die "wrong arguments (expected: $expect_n_arg, got: $#)"

    provider_dir=$1

    [[ -d $provider_dir ]] || die "no such directory: $provider_dir"

    pushd $provider_dir > /dev/null
    pkgs=(./internal/sdk ./internal/services/*)
    popd > /dev/null
    out=$(go run "$TOOLDIR" -dir "$provider_dir" "${pkgs[@]}") || die "failed to run the tool"
    cat << EOF > "$ROOTDIR/mapping/mapping_gen.go"
// Code generated by generate-provider-resource-mapping/run.sh; DO NOT EDIT.
package mapping

import (
	"encoding/json"
	"fmt"
	"os"
)

var ProviderResourceMapping = map[string]string{}

func init() {
    b := []byte(\`$out\`)
	if err := json.Unmarshal(b, &ProviderResourceMapping); err != nil {
		fmt.Fprintf(os.Stderr, "unmarshalling the provider resource mapping: %s", err)
		os.Exit(1)
	}
}
EOF
}

main "$@"