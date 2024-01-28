 #!/bin/bash
echo "Is there a doctor in the house?"

cd /var/www/lingoda/

INDEX_PHP=/var/www/lingoda/public/index.php

if [ ! -f "$INDEX_PHP" ]
then
    echo "copy index.php from volumes"
    cp -R /var/www/lingoda/volumes/public/index.php /var/www/lingoda/public/index.php
fi

VAR_FOLDER=/var/www/lingoda/var/

if [ ! -d "$VAR_FOLDER" ]
then
    echo "copy var/ from volumes "
    cp -R /var/www/lingoda/volumes/var/ /var/www/lingoda/
fi    

SQL_INSTALLED=$(printf 'SELECT data FROM settings_store where id="sql_install" and scope="lingoda"')
IS_INSTALLED=$(mysql -h $DB_HOST -u$DB_USERNAME -p$DB_PASSWORD -e "$SQL_INSTALLED" $DB_DATABASE --skip-column-names)

if [[ ! $IS_INSTALLED == '1' ]]
then
    echo "import initial database"
    pv /var/www/lingoda/volumes/lingoda_dump.sql | mysql -h $DB_HOST -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE
    
    SQL_INSTALL=$(printf "insert into settings_store set id='sql_install', scope='lingoda', data=1, type='bool'")
    $(mysql -h $DB_HOST -u$DB_USERNAME -p$DB_PASSWORD -e "$SQL_INSTALL" $DB_DATABASE)

    WAS_INSTALLED=$(mysql -h $DB_HOST -u$DB_USERNAME -p$DB_PASSWORD -e "$SQL_INSTALLED" $DB_DATABASE --skip-column-names)

    if [[ ! $WAS_INSTALLED == '1' ]]
    then
        echo "We couldn't insert the install flag into the db"
        exit 2
    fi

    echo "hard delete the cache folder"
    rm -rf var-cache/prod/

    echo "cache:clear"
    php bin/console cache:clear
    
else

    # in case the db is down
    DB_UP=$(printf 'SELECT count(1) as nr FROM users')
    for i in 1 2 3
    do
        mysql -h$DB_HOST -u$DB_USERNAME -p$DB_PASSWORD -e "$DB_UP" $DB_DATABASE --skip-column-names
        IS_DB_UP=$?

        if [ $IS_DB_UP -eq 0 ]
        then
            break
        else
            sleep 15
        fi
        echo "no db was found";
        exit 2
    done

    echo "maintenance-mode --enable"
    rm -f var/config/maintenance.php
    echo '<?php return ["sessionId" => "command-line-dummy-session-id"];' >> var/config/maintenance.php
    sleep 5

    echo "hard delete the cache folder"
    rm -rf var-cache/prod/

    echo "cache:clear"
    php bin/console cache:clear --no-interaction 

    echo "doctrine:migrations:migrate"
    php bin/console doctrine:migrations:migrate --no-interaction 

    echo "maintenance-mode --disable"
    php bin/console maintenance-mode --disable -
fi

echo "That's all folkes!!"