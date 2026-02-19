@echo off
REM Dump bazy gabshop z kontenera Docker do pliku db/db_dump.sql

docker exec -t gabshop-db pg_dump -U postgres gabshop > database\db_dump.sql

IF %ERRORLEVEL% EQU 0 (
    echo Dump zaktualizowany!
) ELSE (
    echo Wystapil blad podczas dumpa!
)

pause

