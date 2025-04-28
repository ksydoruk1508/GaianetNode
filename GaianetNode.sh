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
 ██████   █████  ██  █████  ███    ██ ███████ ████████ 
██       ██   ██ ██ ██   ██ ████   ██ ██         ██    
██   ███ ███████ ██ ███████ ██ ██  ██ █████      ██    
██    ██ ██   ██ ██ ██   ██ ██  ██ ██ ██         ██    
 ██████  ██   ██ ██ ██   ██ ██   ████ ███████    ██  

________________________________________________________________________________________________________________________________________


███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                       
                                                                                                                                      
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                             
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                          
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                             
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
echo -e "${NC}"

function install_node {
    echo -e "${BLUE}Обновляем и устанавливаем необходимые пакеты...${NC}"
    sudo apt update -y

    echo -e "${BLUE}Загружаем и выполняем последнюю версию скрипта установки GaiaNet Node...${NC}"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' -o install.sh
    if [ $? -eq 0 ]; then
        bash install.sh
    else
        echo -e "${RED}Ошибка при загрузке скрипта установки!${NC}"
        exit 1
    fi

    echo -e "${BLUE}Обновляем переменные окружения...${NC}"
    export PATH=$PATH:/root/gaianet/bin
    echo "Текущий PATH: $PATH"

    # Добавляем путь /root/gaianet/bin в ~/.bashrc, если он ещё не добавлен
    if ! grep -q '/root/gaianet/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:/root/gaianet/bin' >> ~/.bashrc
        echo -e "${GREEN}Путь /root/gaianet/bin добавлен в ~/.bashrc${NC}"
    fi

    # Добавляем source /root/.wasmedge/env в ~/.bashrc, если он существует и ещё не добавлен
    if [ -f /root/.wasmedge/env ] && ! grep -q 'source /root/.wasmedge/env' ~/.bashrc; then
        echo 'source /root/.wasmedge/env' >> ~/.bashrc
        echo -e "${GREEN}source /root/.wasmedge/env добавлен в ~/.bashrc${NC}"
    fi

    # Применяем изменения в текущей сессии
    source ~/.bashrc

    echo -e "${BLUE}Инициализируем GaiaNet с конфигурацией...${NC}"
    gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при инициализации GaiaNet!${NC}"
        exit 1
    fi

    echo -e "${BLUE}Запускаем ноду...${NC}"
    gaianet start
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при запуске ноды! Проверьте логи: /root/gaianet/log/start-llamaedge.log${NC}"
        exit 1
    fi

    echo -e "${GREEN}Установка ноды GaiaNet завершена успешно!${NC}"
}

function setup_ai_chat_automation {
    echo -e "${YELLOW}Введите ваш адрес. Например: 0xb37b848a654d75e6e6a816098bbdb74664e82eaa.gaia.domains${NC}"
    read wallet_address

    # Проверка формата адреса
    if [[ ! $wallet_address =~ ^0x[a-fA-F0-9]{40}\.gaia\.domains$ ]]; then
        echo -e "${RED}Неверный формат адреса!${NC}"
        return
    fi

    echo -e "${BLUE}Обновляем и устанавливаем необходимые пакеты...${NC}"
    sudo apt update -y

    echo -e "${BLUE}Устанавливаем Python, редактор nano и необходимые утилиты...${NC}"
    sudo apt install python3-pip nano -y

    echo -e "${BLUE}Устанавливаем нужные библиотеки...${NC}"
    pip3 install requests faker

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
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Скрипт успешно запущен в фоновом режиме.${NC}"
    else
        echo -e "${RED}Ошибка при запуске скрипта!${NC}"
    fi

    echo -e "${GREEN}Скрипт для автоматизации общения с AI ботом успешно установлен и запущен в фоновом режиме.${NC}"
}

function restart_ai_chat_script {
    echo -e "${BLUE}Перезапускаем скрипт для общения с AI ботом...${NC}"

    # Останавливаем текущий процесс, если он запущен
    echo -e "${BLUE}Останавливаем текущий процесс random_chat_with_faker.py...${NC}"
    pkill -f "python3 ~/random_chat_with_faker.py"
    sleep 2  # Даём время на завершение процесса

    # Проверяем, существует ли скрипт
    if [ -f ~/random_chat_with_faker.py ]; then
        echo -e "${BLUE}Запускаем скрипт random_chat_with_faker.py в фоновом режиме...${NC}"
        nohup python3 ~/random_chat_with_faker.py > ~/random_chat_with_faker.log 2>&1 &
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Скрипт для общения с AI ботом успешно перезапущен!${NC}"
        else
            echo -e "${RED}Ошибка при запуске скрипта!${NC}"
        fi
    else
        echo -e "${RED}Файл ~/random_chat_with_faker.py не найден!${NC}"
        echo -e "${YELLOW}Сначала установите скрипт для автоматизации общения с AI ботом (пункт 2).${NC}"
    fi
}

function check_node_status {
    echo -e "${BLUE}Проверяем статус ноды Gaianet...${NC}"
    if pgrep -f "wasmedge.*llama-api-server.wasm" > /dev/null; then
        echo -e "${GREEN}Нода Gaianet активна.${NC}"
    else
        echo -e "${RED}Нода Gaianet не запущена.${NC}"
    fi
    echo -e "${BLUE}Проверка завершена.${NC}"
}

function view_logs {
    echo -e "${BLUE}Показываем логи ноды Gaianet...${NC}"
    if [ -f /root/gaianet/log/start-llamaedge.log ]; then
        tail -n 100 /root/gaianet/log/start-llamaedge.log
    else
        echo -e "${RED}Файл логов /root/gaianet/log/start-llamaedge.log не найден!${NC}"
    fi
    echo -e "${BLUE}Просмотр логов завершен. Возвращаемся в главное меню...${NC}"
    main_menu
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
    echo -e "${YELLOW}Просмотр Node ID и Device ID...${NC}"
    if [ -f /root/gaianet/bin/gaianet ]; then
        /root/gaianet/bin/gaianet info
    else
        echo -e "${RED}Команда gaianet не найдена! Убедитесь, что нода установлена.${NC}"
    fi
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду Gaianet...${NC}"
    /root/gaianet/bin/gaianet stop
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при остановке ноды!${NC}"
    fi
    /root/gaianet/bin/gaianet start
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при запуске ноды! Проверьте логи: /root/gaianet/log/start-llamaedge.log${NC}"
    else
        echo -e "${GREEN}Нода Gaianet успешно перезапущена.${NC}"
    fi
}

function update_node {
    echo -e "${BLUE}Обновляем ноду...${NC}"
    /root/gaianet/bin/gaianet stop
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' -o install.sh
    if [ $? -eq 0 ]; then
        bash install.sh
    else
        echo -e "${RED}Ошибка при загрузке скрипта установки!${NC}"
        exit 1
    fi
    export PATH=$PATH:/root/gaianet/bin
    /root/gaianet/bin/gaianet start
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при запуске ноды! Проверьте логи: /root/gaianet/log/start-llamaedge.log${NC}"
    else
        echo -e "${GREEN}Нода Gaianet успешно обновлена.${NC}"
    fi
}

function remove_node {
    echo -e "${BLUE}Останавливаем ноду Gaianet...${NC}"
    /root/gaianet/bin/gaianet stop
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при остановке ноды!${NC}"
    fi

    echo -e "${BLUE}Удаляем ноду Gaianet...${NC}"
    sudo rm -rf /root/gaianet
    echo -e "${GREEN}Нода Gaianet успешно удалена.${NC}"

    echo -e "${BLUE}Удаляем WasmEdge...${NC}"
    sudo rm -rf /root/.wasmedge
    echo -e "${GREEN}WasmEdge успешно удален.${NC}"

    echo -e "${BLUE}Удаляем скрипт для автоматизации общения с AI ботом...${NC}"
    pkill -f "python3 ~/random_chat_with_faker.py"
    rm -f ~/random_chat_with_faker.py ~/chat_log.txt ~/random_chat_with_faker.log
    echo -e "${GREEN}Скрипт для автоматизации общения с AI ботом и его логи успешно удалены.${NC}"

    # Удаляем строки из ~/.bashrc
    if grep -q '/root/gaianet/bin' ~/.bashrc; then
        sed -i '/export PATH=$PATH:\/root\/gaianet\/bin/d' ~/.bashrc
        echo -e "${GREEN}Путь /root/gaianet/bin удален из ~/.bashrc${NC}"
    fi
    if grep -q 'source /root/.wasmedge/env' ~/.bashrc; then
        sed -i '/source \/root\/.wasmedge\/env/d' ~/.bashrc
        echo -e "${GREEN}source /root/.wasmedge/env удален из ~/.bashrc${NC}"
    fi
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Установить скрипт для автоматизации общения с AI ботом${NC}"
        echo -e "${CYAN}3. Перезапуск скрипта на общение с ИИ${NC}"
        echo -e "${CYAN}4. Проверить статус ноды${NC}"
        echo -e "${CYAN}5. Просмотр логов${NC}"
        echo -e "${CYAN}6. Просмотр логов общения с AI ботом${NC}"
        echo -e "${CYAN}7. Просмотр Node ID и Device ID${NC}"
        echo -e "${CYAN}8. Перезапуск ноды${NC}"
        echo -e "${CYAN}9. Обновить ноду${NC}"
        echo -e "${CYAN}10. Удаление ноды${NC}"
        echo -e "${CYAN}11. Выход${NC}"
        
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) setup_ai_chat_automation ;;
            3) restart_ai_chat_script ;;
            4) check_node_status ;;
            5) view_logs ;;
            6) view_ai_chat_logs ;;
            7) view_node_info ;;
            8) restart_node ;;
            9) update_node ;;
            10) remove_node ;;
            11) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu