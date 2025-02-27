#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Установка UTF-8 для корректной работы с русскими символами
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    echo -e "${BLUE}Устанавливаем curl...${NC}"
    sudo apt update
    sudo apt install curl -y
fi

# Проверка наличия jq и установка, если не установлен
if ! command -v jq &> /dev/null; then
    echo -e "${BLUE}Устанавливаем jq...${NC}"
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
    echo -e "${BLUE}Обновляем сервер...${NC}"
    sudo apt-get update -y && sudo apt upgrade -y && sudo apt install -y python3-pip nano

    echo -e "${BLUE}Загружаем и выполняем скрипт установки ноды Gaianet...${NC}"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash && \
    echo 'export PATH=$PATH:/root/gaianet/bin' >> ~/.bashrc && source ~/.bashrc

    echo -e "${BLUE}Настраиваем конфигурацию Bash...${NC}"
    export PATH=$PATH:/root/gaianet/bin

    echo -e "${BLUE}Инициализируем GaiaNet с конфигурацией...${NC}"
    /root/gaianet/bin/gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json

    echo -e "${BLUE}Создаем сервисный файл для автоматического перезапуска ноды...${NC}"
    cat </dev/null${NC}"
        echo -e "${YELLOW}Если нода не запущена, попробуйте перезапустить её: /root/gaianet/bin/gaianet start${NC}"
    fi
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function view_ai_chat_logs {
    echo -e "${YELLOW}Проверяем существование файла логов общения с AI ботом...${NC}"
    
    # Проверяем файл chat_log.txt в домашней директории
    if [ -f ~/chat_log.txt ]; then
        echo -e "${YELLOW}Просмотр логов общения с AI ботом (последние 50 строк, выход из режима просмотра: Ctrl+C)...${NC}"
        tail -n 50 ~/chat_log.txt
    else
        echo -e "${RED}Файл логов общения с AI ботом (~ /chat_log.txt) не найден.${NC}"
        echo -e "${YELLOW}Убедитесь, что скрипт автоматизации общения с AI ботом запущен и создаёт логи.${NC}"
        echo -e "${YELLOW}Попробуйте запустить скрипт вручную: nohup python3 ~/random_chat_with_faker.py > ~/random_chat_with_faker.log 2>&1 &${NC}"
    fi
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function remove_node {
    echo -e "${BLUE}Удаляем ноду Gaianet...${NC}"
    pkill -f "/root/gaianet/bin/gaianet start"
    sudo rm -rf /root/gaianet
    echo -e "${GREEN}Нода Gaianet успешно удалена.${NC}"

    echo -e "${BLUE}Удаляем WasmEdge...${NC}"
    sudo rm -rf /usr/local/include/wasmedge
    sudo rm -f /usr/local/lib/libwasmedge*
    sudo rm -f /usr/local/bin/wasmedge*
    echo -e "${GREEN}WasmEdge успешно удален.${NC}"

    echo -e "${BLUE}Удаляем скрипт для автоматизации общения с AI ботом...${NC}"
    pkill -f "python3 ~/random_chat_with_faker.py"
    rm -f ~/random_chat_with_faker.py ~/chat_log.txt
    echo -e "${GREEN}Скрипт для автоматизации общения с AI ботом успешно удален.${NC}"

    echo -e "${BLUE}Удаляем сервис для перезапуска ноды...${NC}"
    sudo systemctl stop gaianet.service
    sudo systemctl disable gaianet.service
    sudo rm -f /etc/systemd/system/gaianet.service
    sudo systemctl daemon-reload
    echo -e "${GREEN}Сервис для перезапуска ноды успешно удален.${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду Gaianet...${NC}"
    pkill -f "/root/gaianet/bin/gaianet start"
    sleep 5
    fuser -k 8084/tcp  # Освобождение порта, если он занят
    echo -e "${BLUE}Запускаем ноду в фоновом режиме...${NC}"
    nohup /root/gaianet/bin/gaianet start > /root/gaianet/gaianet_node.log 2>&1 &  # Указываем путь для логов
    echo -e "${GREEN}Нода Gaianet успешно перезапущена.${NC}"
}

function view_node_info {
    echo -e "${YELLOW}Просмотр Node id и Device id...${NC}"
    /root/gaianet/bin/gaianet info
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function change_port {
    current_port=$(jq -r '.llamaedge_port' /root/gaianet/config.json)
    echo -e "${YELLOW}Текущий порт: ${current_port}${NC}"
    echo -e "${YELLOW}Введите новый порт:${NC}"
    read new_port
    jq ".llamaedge_port = \"${new_port}\"" /root/gaianet/config.json > /root/gaianet/config_tmp.json && mv /root/gaianet/config_tmp.json /root/gaianet/config.json
    echo -e "${BLUE}Перезапускаем ноду с новым портом...${NC}"
    restart_node
}

function setup_ai_chat_automation {
    echo -e "${YELLOW}Введите ваш Subdomain (например: 0xb37b848a654d75e6e6a816098bbdb74664e82eaa.us.gaianet.network):${NC}"
    read subdomain
    echo -e "${BLUE}Устанавливаем скрипт для автоматизации общения с AI ботом...${NC}"
    pip install requests
    pip install faker
    echo -e "${BLUE}Создаем скрипт random_chat_with_faker.py...${NC}"
    cat < ~/random_chat_with_faker.py
import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

node_url = "https://${subdomain}/v1/chat/completions"

faker = Faker()

headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}

logging.basicConfig(filename='~/chat_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_message(node, message):
    logging.info(f"{node}: {message}")

def send_message(node_url, message):
    try:
        response = requests.post(node_url, json=message, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Ошибка при получении ответа от API: {e}")
        return None

def extract_reply(response):
    if response and 'choices' in response:
        return response['choices'][0]['message']['content']
    return ""

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        "messages": [
            {"role": "system", "content": "Вы — полезный ассистент."},
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

function update_node {
    echo -e "${BLUE}Обновляем ноду...${NC}"
    gaianet stop
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
    source $HOME/.bashrc
    gaianet start
    echo -e "${GREEN}Нода Gaianet успешно обновлена.${NC}"
}

# Новая функция для перезапуска скрипта автоматизации общения с AI ботом
function restart_ai_chat_script {
    echo -e "${BLUE}Проверяем, запущен ли скрипт random_chat_with_faker.py...${NC}"
    # Проверяем, есть ли процесс с именем random_chat_with_faker.py
    if pgrep -f "python3 ~/random_chat_with_faker.py" > /dev/null; then
        echo -e "${YELLOW}Останавливаем текущий процесс скрипта...${NC}"
        pkill -f "python3 ~/random_chat_with_faker.py"
        sleep 2  # Даем время процессу завершиться
    else
        echo -e "${YELLOW}Скрипт random_chat_with_faker.py не найден в запущенных процессах.${NC}"
    fi

    echo -e "${BLUE}Запускаем скрипт random_chat_with_faker.py заново в фоновом режиме...${NC}"
    nohup python3 ~/random_chat_with_faker.py > ~/random_chat_with_faker.log 2>&1 &
    echo -e "${GREEN}Скрипт для автоматизации общения с AI ботом успешно перезапущен в фоновом режиме.${NC}"
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Просмотр логов${NC}"
        echo -e "${CYAN}3. Удаление ноды${NC}"
        echo -e "${CYAN}4. Перезапуск ноды${NC}"
        echo -e "${CYAN}5. Просмотр Node id и Device id${NC}"
        echo -e "${CYAN}6. Изменить порт (в данный момент работает только на установленном по умолчанию: 8080)${NC}"
        echo -e "${CYAN}7. Установить скрипт для автоматизации общения с AI ботом${NC}"
        echo -e "${CYAN}8. Просмотр логов общения с AI ботом${NC}"
        echo -e "${CYAN}9. Обновить ноду${NC}"
        echo -e "${CYAN}11. Перезапустить скрипт автоматизации общения с AI ботом${NC}"
        echo -e "${CYAN}10. Выход${NC}"
       
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) view_logs ;;
            3) remove_node ;;
            4) restart_node ;;
            5) view_node_info ;;
            6) change_port ;;
            7) setup_ai_chat_automation ;;
            8) view_ai_chat_logs ;;
            9) update_node ;;
            11) restart_ai_chat_script ;;
            10) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu