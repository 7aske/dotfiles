#!/usr/bin/env bash
typeset -g AWS_REGION_FILE="${AWS_REGION_FILE:-$HOME/.aws_region}"
typeset -g AWS_PROFILE_FILE="${AWS_PROFILE_FILE:-$HOME/.aws_profile}"
typeset -g AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

[ -z "$AWS_CONFIG_FILE" ] && echo "AWS_CONFIG_FILE is not set. Please set it to the path of your AWS config file." && exit 1
[ -z "$AWS_REGION_FILE" ] && echo "AWS_REGION_FILE is not set. Please set it to the path of your AWS region file." && exit 1

[[ -r $AWS_PROFILE_FILE ]] && source "$AWS_PROFILE_FILE"
[[ -r $AWS_REGION_FILE  ]] && source "$AWS_REGION_FILE"

menu="rofi -dmenu -i"
region_prompt=("-p" "Select AWS region")
if [ -t 1 ]; then
    region_prompt=("--header" "Select AWS region")
    menu="fzf"
fi

function _aws_region() {
    local region
    local section

    if [[ $1 == -u ]]; then
        unset AWS_DEFAULT_REGION AWS_REGION
        rm -f "$AWS_REGION_FILE"
        return
    fi

    if [[ -n $1 ]]; then
        region=$1
    else
        section="profile $AWS_PROFILE"
        region=$(
             awk -F' *= *' -v section="[$section]" '
        $0 == section { in_section=1; next }
        /^\[.*\]/ { in_section=0 }
        in_section && $1 == "regions" {
            gsub(/[[:space:]]*,[[:space:]]*/, "\n", $2)
            gsub(/[[:space:]]+/, "\n", $2)
            print $2
            exit
        }
    ' "$AWS_CONFIG_FILE" 2>/dev/null |
            sort -u |
            $menu "${region_prompt[@]}"
        )
    fi

    [[ -z $region ]] && return

    export AWS_DEFAULT_REGION=$region
    export AWS_REGION=$region
    echo "export AWS_DEFAULT_REGION=$region" > "$AWS_REGION_FILE"
}

_aws_region "$@"
