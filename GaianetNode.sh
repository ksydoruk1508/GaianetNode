#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Проверка наличия jq и установка, если не установлен
if ! command -v jq &> /dev/null; then
    sudo apt update
    sudo apt install jq -y
fi

sleep 1

echo -e "${GREEN}"
cat << "EOF"
<баннер>
EOF
echo -e "${NC}"

function install_node {
    echo -e "${BLUE}Обновляем и устанавливаем необходимые пакеты...${NC}"
    sudo apt update -y
    sudo apt-get update

    echo -e "${BLUE}Загружаем и выполняем последнюю версию скрипта установки GaiaNet Node...${NC}"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash

    echo -e "${BLUE}Выбираем конфигурацию Bash...${NC}"
    source ~/.bashrc
    
    echo -e "${BLUE}Инициализируем GaiaNet с конфигурацией...${NC}"
    gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json

    echo -e "${BLUE}Запускаем ноду...${NC}"
    gaianet start

    echo -e "${BLUE}Останавливаем ноду...${NC}"
    gaianet stop

    echo -e "${BLUE}Создаем сервисный файл для автозапуска GaiaNet при падении...${NC}"
    cat <<EOF | sudo tee /etc/systemd/system/gaianet.service
[Unit]
Description=Gaianet Node Service
After=network.target
[Service]
Type=forking
RemainAfterExit=true
ExecStart=/root/gaianet/bin/gaianet start
ExecStop=/root/gaianet/bin/gaianet stop
ExecStopPost=/bin/sleep 20
Restart=always
RestartSec=5
User=root
[Install]
WantedBy=multi-user.target
EOF

    echo -e "${BLUE}Перезагружаем конфигурацию systemd и рестартуем сервис...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl restart gaianet.service

    echo -e "${BLUE}Проверяем статус сервиса...${NC}"
    sudo systemctl status gaianet.service

    echo -e "${GREEN}Установка ноды GaiaNet завершена успешно!${NC}"
}

function setup_ai_chat_automation {
    echo -e "${YELLOW}Введите ваш адрес. Например: 0xb37b848a654d75e6e6a816098bbdb74664e82eaa.gaia.domains${NC}"
    read wallet_address

    echo -e "${BLUE}Обновляем и устанавливаем необходимые пакеты...${NC}"
    sudo apt update -y
    sudo apt update

    echo -e "${BLUE}Устанавливаем Python, редактор nano и необходимые утилиты...${NC}"
    sudo apt install python3-pip -y
    sudo apt install nano -y

    echo -e "${BLUE}Устанавливаем нужные библиотеки...${NC}"
    pip install requests
    pip install faker

    echo -e "${BLUE}Создаем скрипт random_chat_with_faker.py...${NC}"
    cat <<EOF > ~/random_chat_with_faker.py
import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

node_url = "https://${wallet_address}/v1/chat/completions"

faker = Faker()

headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}

logging.basicConfig(filename='chat_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_message(node, message):
    logging.info(f"{node}: {message}")

def send_message(node_url, message):
    try:
        response = requests.post(node_url, json=message, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Failed to get response from API: {e}")
        return None

def extract_reply(response):
    if response and 'choices' in response:
        return response['choices'][0]['message']['content']
    return ""

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": random_question}
        ]
    }

    question_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    response = send_message(node_url, message)
    reply = extract_reply(response)

    reply_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    log_message("Node replied", f"Q ({question_time}): {random_question} A ({reply_time}): {reply}")

    print(f"Q ({question_time}): {random_question}\nA ({reply_time}): {reply}")

    delay = random.randint(60, 180)
    time.sleep(delay)
EOF

    echo -e "${BLUE}Запускаем скрипт random_chat_with_faker.py в фоновом режиме с помощью nohup...${NC}"
    nohup python3 ~/random_chat_with_faker.py > ~/random_chat_with_faker.log 2>&1 &

    echo -e "${GREEN}Скрипт для автоматизации общения с AI ботом успешно установлен и запущен в фоновом режиме.${NC}"
}

function check_node_status {
    echo -e "${BLUE}Проверяем статус ноды Gaianet...${NC}"
    sudo systemctl status gaianet.service
    echo -e "${BLUE}Проверка завершена.${NC}"
}

function view_logs {
    journalctl -u gaianet.service -f
}

function view_ai_chat_logs {
    echo -e "${YELLOW}Проверяем существование файла логов общения с AI ботом...${NC}"
    
    if [ -f ~/chat_log.txt ]; then
        echo -e "${YELLOW}Просмотр логов общения с AI ботом (последние 50 строк, выход из режима просмотра: Ctrl+C)...${NC}"
        tail -n 50 ~/chat_log.txt
    else
        echo -e "${RED}Файл логов общения с AI ботом (~/chat_log.txt) не найден.${NC}"
        echo -e "${YELLOW}Убедитесь, что скрипт автоматизации общения с AI ботом запущен и создаёт логи.${NC}"
        echo -e "${YELLOW}Попробуйте запустить скрипт вручную: nohup python3 ~/random_chat_with_faker.py > ~/random_chat_with_faker.log 2>&1 &${NC}"
    fi
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function view_node_info {
    echo -e "${YELLOW}Просмотр Node id и Device id...${NC}"
    /root/gaianet/bin/gaianet info
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду Gaianet...${NC}"
    gainet stop
    sudo systemctl daemon-reload
    sudo systemctl restart gaianet.service
    echo -e "${GREEN}Нода Gaianet успешно перезапущена.${NC}"
}

function update_node {
    echo -e "${BLUE}Обновляем ноду...${NC}"
    gaianet stop
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
    source $HOME/.bashrc
    gaianet start
    echo -e "${GREEN}Нода Gaianet успешно обновлена.${NC}"
}

function remove_node {
    echo -e "${BLUE}Останавливаем и удаляем сервис Gaianet...${NC}"
    gaianet stop
    sudo systemctl stop gaianet.service
    sudo systemctl disable gaianet.service
    sudo rm -f /etc/systemd/system/gaianet.service
    sudo systemctl daemon-reload
    echo -e "${GREEN}Сервис Gaianet успешно остановлен и удален.${NC}"

    echo -e "${BLUE}Удаляем ноду Gaianet...${NC}"
    sudo rm -rf /root/gaianet
    echo -e "${GREEN}Нода Gaianet успешно удалена.${NC}"

    echo -e "${BLUE}Удаляем WasmEdge...${NC}"
    sudo rm -rf /usr/local/include/wasmedge
    sudo rm -f /usr/local/lib/libwasmedge*
    sudo rm -f /usr/local/bin/wasmedge*
    echo -e "${GREEN}WasmEdge успешно удален.${NC}"

    echo -e "${BLUE}Удаляем скрипт для автоматизации общения с AI ботом...${NC}"
    pkill -f "python3 ~/random_chat_with_faker.py"
    rm -f ~/random_chat_with_faker.py ~/chat_log.txt ~/random_chat_with_faker.log
    echo -e "${GREEN}Скрипт для автоматизации общения с AI ботом и его логи успешно удалены.${NC}"
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Установить скрипт для автоматизации общения с AI ботом${NC}"
        echo -e "${CYAN}3. Проверить статус ноды${NC}"
        echo -e "${CYAN}4. Просмотр логов${NC}"
        echo -e "${CYAN}5. Просмотр логов общения с AI ботом${NC}"
        echo -e "${CYAN}6. Просмотр Node id и Device id${NC}"
        echo -e "${CYAN}7. Перезапуск ноды${NC}"
        echo -e "${CYAN}8. Обновить ноду${NC}"
        echo -e "${CYAN}9. Удаление ноды${NC}"
        echo -e "${CYAN}10. Выход${NC}"
        
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) setup_ai_chat_automation ;;
            3) check_node_status ;;
            4) view_logs ;;
            5) view_ai_chat_logs ;;
            6) view_node_info ;;
            7) restart_node ;;
            8) update_node ;;
            9) remove_node ;;
            10) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
