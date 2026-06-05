#!/usr/bin/env bash

# ============================================================
# ПРОСТОЙ ПРИМЕР: читаем CSV файл и отправляем данные в базу
# ============================================================


# -- НАСТРОЙКИ ПОДКЛЮЧЕНИЯ К БАЗЕ ДАННЫХ ---------------------

DB_HOST="localhost"        # адрес сервера ClickHouse
DB_PORT="8123"             # порт (8123 = HTTP интерфейс)
DB_USER="root"             # имя пользователя
DB_PASS="123"              # пароль
DB_NAME="database"         # название базы данных
DB_TABLE="simple_users"    # название таблицы


# -- ПУТЬ К ФАЙЛУ С ДАННЫМИ ----------------------------------

FILE="$(dirname "$0")/data/users.csv"   # берём файл users.csv из папки data/
                                         # dirname "$0" = папка где лежит этот скрипт


# -- ШАГ 1: СОЗДАЁМ ТАБЛИЦУ ЕСЛИ ЕЁ НЕТ ---------------------

echo "Шаг 1: создаём таблицу в базе..."

# Отправляем SQL запрос в ClickHouse через curl
# IF NOT EXISTS = не ругаться если таблица уже есть
curl -s "http://$DB_HOST:$DB_PORT/" \
  -u "$DB_USER:$DB_PASS" \
  --data-binary "
    CREATE TABLE IF NOT EXISTS $DB_NAME.$DB_TABLE (
        username    String,
        date        Date,
        percentage  Float64,
        age         UInt8,
        hash        String
    ) ENGINE = MergeTree()
    ORDER BY username
  "

echo "Таблица готова."


# -- ШАГ 2: ЧИТАЕМ ФАЙЛ ПОСТРОЧНО ----------------------------

echo ""
echo "Шаг 2: читаем файл $FILE ..."

# read -r        = читаем одну строку
# IFS=','        = разбиваем строку по запятой
# -r username    = первый кусок кладём в переменную username
# -r date        = второй кусок кладём в переменную date
# и так далее...
# < "$FILE"      = берём данные из файла

first_line=true   # флаг чтобы пропустить первую строку (заголовок)

while IFS=',' read -r username date percentage age hash; do

    # Пропускаем первую строку — это заголовок "username,date,..."
    if $first_line; then
        first_line=false
        continue
    fi

    # Показываем что прочитали
    echo "  Прочитали: $username | $date | $percentage% | возраст $age"

    # -- ШАГ 3: ОТПРАВЛЯЕМ КАЖДУЮ СТРОКУ В БАЗУ --------------

    # Формируем SQL запрос с нашими данными
    # VALUES ('alice', '2024-01-15', 23.50, 25, 'abc123')
    QUERY="INSERT INTO $DB_NAME.$DB_TABLE VALUES ('$username', '$date', $percentage, $age, '$hash')"

    # Отправляем запрос в ClickHouse
    curl -s "http://$DB_HOST:$DB_PORT/" \
      -u "$DB_USER:$DB_PASS" \
      --data-binary "$QUERY"

    echo "  -> Отправлено в базу!"

done < "$FILE"


# -- ГОТОВО --------------------------------------------------

echo ""
echo "Готово! Все данные в базе."
echo ""
echo "Посмотреть что в таблице:"
echo "  curl -s 'http://$DB_HOST:$DB_PORT/' -u '$DB_USER:$DB_PASS' \\"
echo "    --data-binary 'SELECT * FROM $DB_NAME.$DB_TABLE FORMAT Pretty'"
