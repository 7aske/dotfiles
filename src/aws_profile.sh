#!/usr/bin/env bash

typeset -g AWS_REGION_FILE="${AWS_REGION_FILE:-$HOME/.aws_region}"
typeset -g AWS_PROFILE_FILE="${AWS_PROFILE_FILE:-$HOME/.aws_profile}"
typeset -g AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

[ -z "$AWS_CONFIG_FILE" ] && echo "AWS_CONFIG_FILE is not set. Please set it to the path of your AWS config file." && exit 1
[ -z "$AWS_PROFILE_FILE" ] && echo "AWS_PROFILE_FILE is not set. Please set it to the path of your AWS profile file." && exit 1

[[ -r $AWS_PROFILE_FILE ]] && source "$AWS_PROFILE_FILE"
[[ -r $AWS_REGION_FILE  ]] && source "$AWS_REGION_FILE"


profile_prompt=("-p" "Select AWS profile")
login_prompt=("-p" "SSO login to")
logout_prompt=("-p" "Logout from AWS SSO")
menu="rofi -dmenu -i"
if [ -t 1 ]; then
    profile_prompt=("--header" "Select AWS profile")
    logout_prompt=("--header" "Logout from AWS SSO")
    menu="fzf"
fi

_aws_profile() {
    local profile user_id

    if [[ $1 == -u ]]; then
        profile="$AWS_PROFILE"
        if aws configure get sso_account_id --profile "$profile" &>/dev/null; then
            logged_in="$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)"
            if [ -n "$logged_in" ]; then
                logout_prompt[1]="${logout_prompt[1]} $profile?"
                printf "Yes\nNo" | $menu "${logout_prompt[@]}" | grep -q 'Yes' && aws sso logout --profile "$profile" && \
                if [ -t 1 ]; then
                    echo "Logged out from: $profile"
                else
                    notify-send -i dialog-error "AWS" "Logged out from: $profile"
                fi
            fi
        fi

        unset AWS_PROFILE
        rm -f "$AWS_PROFILE_FILE"
        aws_region -u
        return
    fi

    if [[ -n $1 ]]; then
        profile=$1
    else
        profile=$(
            sed -n 's/^\[profile \(.*\)\]/\1/p' "$AWS_CONFIG_FILE" |
            $menu "${profile_prompt[@]}"
        )
    fi

    [[ -z $profile ]] && return

    export AWS_PROFILE=$profile
    echo "export AWS_PROFILE=$profile" > "$AWS_PROFILE_FILE"

    aws_region

    if aws configure get sso_account_id --profile "$profile" &>/dev/null; then
        logged_in="$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)"
        if [ -z "$logged_in" ]; then
            login_prompt[1]="${login_prompt[1]} $profile?"
            printf "Yes\nNo" | $menu "${login_prompt[@]}" | grep -q 'Yes' && aws sso login --profile "$profile"
        fi
    fi

    user_id="$(aws sts get-caller-identity --query 'Arn' --output text | cut -d ':' -f 6)"
    if [ -z "$user_id" ]; then
        if [ -t 1 ]; then
            echo "Not logged in"
        else
            notify-send -i dialog-error "AWS" "Not logged in"
        fi
    else
        if [ -t 1 ]; then
            echo "Identity: $user_id"
        else
            notify-send -i dialog-ok "AWS" "Identity: $user_id"
        fi
    fi
}

_aws_profile "$@"
