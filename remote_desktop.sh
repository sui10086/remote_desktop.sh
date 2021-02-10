#!/usr/bin/env bash

# 启动准备
sudp apt update && sudo apt install wget

# 远程桌面安装脚本 

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"
NGROK_TOKEN="1nRjV2YVfJoRWV2qPKYV6sYvHov_2Aq95dvRJfJUjzJknCdn7"
LOG_FILE='/tmp/ngrok.log'
CONTINUE_FILE="/tmp/continue"


if [[ -n "$(uname | grep -i Linux)" ]]; then
    echo -e "${INFO} Install ngrok ..."
    curl -fsSL https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok.zip
    unzip ngrok.zip ngrok
    rm ngrok.zip
    chmod +x ngrok
    sudo mv ngrok /usr/local/bin
    ngrok -v
elif [[ -n "$(uname | grep -i Darwin)" ]]; then
    echo -e "${INFO} Install ngrok ..."
    curl -fsSL https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-darwin-amd64.zip -o ngrok.zip
    unzip ngrok.zip ngrok
    rm ngrok.zip
    chmod +x ngrok
    sudo mv ngrok /usr/local/bin
    ngrok -v
    # USER=root
    echo -e "${INFO} Set SSH service ..."
    echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config >/dev/null
    sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
else
    echo -e "${ERROR} This system is not supported!"
    exit 1
fi

if [[ -n "${SSH_PASSWORD}" ]]; then
    echo -e "${INFO} Set user(${USER}) password ..."
    echo -e "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd "${USER}"
fi

echo -e "${INFO} Start ngrok proxy for SSH port..."
screen -dmS ngrok \
    ngrok tcp 22 \
    --log "${LOG_FILE}" \
    --authtoken "${NGROK_TOKEN}" \
    --region "${NGROK_REGION:-us}"

while ((${SECONDS_LEFT:=10} > 0)); do
    echo -e "${INFO} Please wait ${SECONDS_LEFT}s ..."
    sleep 1
    SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
done

ERRORS_LOG=$(grep "command failed" ${LOG_FILE})

if [[ -e "${LOG_FILE}" && -z "${ERRORS_LOG}" ]]; then
    SSH_CMD="$(grep -oE "tcp://(.+)" ${LOG_FILE} | sed "s/tcp:\/\//ssh ${USER}@/" | sed "s/:/ -p /")"
    MSG="
*ngrok session info:*
⚡ *CLI:*
\`${SSH_CMD}\`
🔔 *TIPS:*
Run '\`touch ${CONTINUE_FILE}\`' to continue to the next step.
"
   
    while ((${PRT_COUNT:=1} <= ${PRT_TOTAL:=10})); do
        SECONDS_LEFT=${PRT_INTERVAL_SEC:=10}
        while ((${PRT_COUNT} > 1)) && ((${SECONDS_LEFT} > 0)); do
            echo -e "${INFO} (${PRT_COUNT}/${PRT_TOTAL}) Please wait ${SECONDS_LEFT}s ..."
            sleep 1
            SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
        done
        echo "------------------------------------------------------------------------"
        echo "To connect to this session copy and paste the following into a terminal:"
        echo -e "${Green_font_prefix}$SSH_CMD${Font_color_suffix}"
        echo -e "TIPS: Run 'touch ${CONTINUE_FILE}' to continue to the next step."
        echo "------------------------------------------------------------------------"
        PRT_COUNT=$((${PRT_COUNT} + 1))
    done
else
    echo "${ERRORS_LOG}"
    exit 4
fi

while [[ -n $(ps aux | grep ngrok) ]]; do
    sleep 1
    if [[ -e ${CONTINUE_FILE} ]]; then
        echo -e "${INFO} Continue to the next step."
        exit 0
    fi
done
