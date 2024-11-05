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
    echo -e "${BLUE}Обновляем сервер...${NC}"
    sudo apt-get update -y && sudo apt upgrade -y && sudo apt install -y python3-pip nano

    echo -e "${BLUE}Загружаем и выполняем скрипт установки ноды Gaianet...${NC}"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash && echo 'export PATH=$PATH:/root/gaianet/bin' >> ~/.bashrc && source ~/.bashrc

    echo -e "${BLUE}Настраиваем конфигурацию Bash...${NC}"
    export PATH=$PATH:/root/gaianet/bin

    echo -e "${BLUE}Инициализируем GaiaNet с конфигурацией...${NC}"
    /root/gaianet/bin/gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json

    echo -e "${BLUE}Запускаем ноду в фоновом режиме...${NC}"
    nohup /root/gaianet/bin/gaianet start > gaianet_node.log 2>&1 &
    echo -e "${GREEN}Нода Gaianet успешно установлена и запущена в фоновом режиме.${NC}"

    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
    main_menu
}

function view_logs {
    echo -e "${YELLOW}Просмотр логов ноды (последние 50 строк, выход из режима просмотра: Ctrl+C)...${NC}"
    tail -n 50 gaianet_node.log
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function remove_node {
    echo -e "${BLUE}Удаляем ноду Gaianet...${NC}"
    pkill -f "/root/gaianet/bin/gaianet start"
    sudo rm -rf /root/gaianet
    echo -e "${GREEN}Нода Gaianet успешно удалена.${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду Gaianet...${NC}"
    pkill -f "/root/gaianet/bin/gaianet start"
    echo -e "${BLUE}Запускаем ноду в фоновом режиме...${NC}"
    nohup /root/gaianet/bin/gaianet start > gaianet_node.log 2>&1 &
    echo -e "${GREEN}Нода Gaianet успешно перезапущена.${NC}"
}

function view_node_info {
    echo -e "${YELLOW}Просмотр Node id и Device id...${NC}"
    /root/gaianet/bin/gaianet info
    echo -e "${BLUE}Возвращаемся в главное меню...${NC}"
}

function import_node_and_device_ids {
    echo -e "${YELLOW}Введите Node ID:${NC}"
    read node_id
    echo -e "${YELLOW}Введите Device ID:${NC}"
    read device_id
    echo -e "${BLUE}Импортируем Node ID и Device ID в конфигурацию...${NC}"
    jq ".node_id = \"${node_id}\" | .device_id = \"${device_id}\"" /root/gaianet/config.json > /root/gaianet/config_tmp.json && mv /root/gaianet/config_tmp.json /root/gaianet/config.json
    echo -e "${GREEN}Node ID и Device ID успешно импортированы.${NC}"
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

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Просмотр логов${NC}"
        echo -e "${CYAN}3. Удаление ноды${NC}"
        echo -e "${CYAN}4. Перезапуск ноды${NC}"
        echo -e "${CYAN}5. Просмотр Node id и Device id${NC}"
        echo -e "${CYAN}6. Импорт Node id и Device id${NC}"
        echo -e "${CYAN}7. Изменить порт${NC}"
        echo -e "${CYAN}8. Выход${NC}"
       
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) view_logs ;;
            3) remove_node ;;
            4) restart_node ;;
            5) view_node_info ;;
            6) import_node_and_device_ids ;;
            7) change_port ;;
            8) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
