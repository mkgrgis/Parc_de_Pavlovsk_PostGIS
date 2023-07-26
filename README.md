# PostGIS_Parc_de_Pavlovsk
Скрипты PostGIS для оценки качества данных [OSM](https://osm.org), [WikiMap](https://commons.wikimedia.org/wiki/Category:Pavlovsk_park), [PastVu](https://pastvu.com/ps?f=r!365) по [Павловскому парку](https://www.openstreetmap.org/relation/1721131).

<img src="https://99px.ru/sstorage/53/2021/10/tmb_334172_300493.jpg" align="center" height="350" alt="Parc de Pavlovsk 1"/>[^1]

<img src="https://www.kudatotam.ru/upload/000/u0/9/1/e53d90bc.jpg" align="center" height="400" alt="Parc de Pavlovsk 2"/>[^2]

## Подготовка базы данных
1. Установите любую версию PostgreSQL 9+ и преобразователь данных [osmium](https://github.com/joto/osmium). Например, из пакетов deb используя прогармму `apt`. Типичные названия пкетов `postgresql-15` и `osmium-tool` соотвественно.
2. Создайте пользователя и базу данных для размещения геоданных
```bash
sudo -u postgres bash;
psql
```
Вы можете выбрать любые имена, например:
```sql
CREATE USER "Геоинформатик" LOGIN PASSWORD 'password';
CREATE DATABASE "Геоинформационная система" OWNER "Геоинформатик";
\q
```

3. Создайте расширение PostGIS
```bash
psql -d "Геоинформационная система"
```
SQL от администратора всех БД
```
CREATE EXTENSION postgis;
```

4. Проверьте доступность пространственных типов данных и функций
```sql
select postgis_version();
```
5. Выйдите из терминала БД и административного режима

## Подготовка объектов пространственной аналитики и работа с ними

6. Войдите терминале ОС в каталог данного репозитория
```bash
cd PostGIS_Parc_de_Pavlovsk
```
7. Создайте таблицы и представления пространственной аналитики, указав пользователя и название БД для геофинормационных работ
```bash
cat SQL/0\ Создание\ базовых\ структур.sql SQL/1\ Водотоки.sql SQL/2\ Другие.sql | psql -d "Геоинформационная система" -U "Геоинформатик";
```
8. Настройте своё название БД и имя пользователя в файле postgres.url. О правилах написания строки доступа к БД см в [официальной документации](https://postgrespro.ru/docs/postgresql/15/libpq-connect#LIBPQ-CONNSTRING).

9. Выбирете активный каталог для ведения архива первичных данных

10. Вызовите скрипты для первичного заполнения данных `OSM Павловск.sh` и `WikiMap Павловск.sh`. В активном каталоге будут откладываться архивы первичных файлов-документов OSM XML и Wikimedia JOSN.

11. Осматривайте представления и создавайте новые!

12. Обновляйте данные таким же вызовом скриптов как в п.10.

### Параметры вызова в скрипте `OSM Павловск.sh`

1. Граница скачивания bbox
2. Название схемы для оъектов Павловского парка, всегда `'Павловский парк'`

### Параметры вызова в скрипте `WikiMap Павловск.sh`

1. Название корневой категории WikimediaCommons для Павловского парка, `'Pavlovsk_park'`
2. Название схемы для оъектов Павловского парка, всегда `'Павловский парк'`

### Параметры вызова в скрипте `PastVu Павловск.sh`

1. Граница скачивания bbox
2. Название схемы для оъектов Павловского парка, всегда `'Павловский парк'`

[^1]:Моменты золотой осени, Санкт-Петербург, Павловский парк, Пушкин, октябрь 2021, фотограф Гордеев Эдуард
[^2]:Фото: Таня She (Aiya).
