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
sleep 1

echo -e "${GREEN}"
cat << "EOF"
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
    echo -e "${BLUE}Обновляем сервер...${NC}"
    sudo apt-get update -y && sudo apt upgrade -y && sudo apt install -y python3-pip nano

    echo -e "${BLUE}Загружаем и выполняем скрипт установки ноды Gaianet...${NC}"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash && export PATH=$PATH:/root/gaianet/bin

    echo -e "${BLUE}Настраиваем конфигурацию Bash...${NC}"
    source ~/.bashrc

    echo -e "${BLUE}Инициализируем GaiaNet с конфигурацией...${NC}"
    gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json

    echo -e "${BLUE}Запускаем ноду в фоновом режиме...${NC}"
    nohup gaianet start > gaianet_node.log 2>&1 &
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
    pkill -f "gaianet start"
    sudo rm -rf /root/gaianet
    echo -e "${GREEN}Нода Gaianet успешно удалена.${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду Gaianet...${NC}"
    pkill -f "gaianet start"
    echo -e "${BLUE}Запускаем ноду в фоновом режиме...${NC}"
    nohup gaianet start > gaianet_node.log 2>&1 &
    echo -e "${GREEN}Нода Gaianet успешно перезапущена.${NC}"
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Просмотр логов${NC}"
        echo -e "${CYAN}3. Удаление ноды${NC}"
        echo -e "${CYAN}4. Перезапуск ноды${NC}"
        echo -e "${CYAN}5. Выход${NC}"
       
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) view_logs ;;
            3) remove_node ;;
            4) restart_node ;;
            5) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
