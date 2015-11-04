#!/bin/bash

PARAMS_FILE=$(readlink -f "./params.conf")
MYSQL_CNF_DIR=$(readlink -f "./.my.d")

# Lê os parâmetros de configuração do backup

if [ -f $PARAMS_FILE ]; then
    source $PARAMS_FILE
else
	echo "Arquivo de parâmetros não encontrado." 1>&2
	exit 1
fi

if [ ! -d $MYSQL_CNF_DIR ]; then
	echo "Diretório de configuração do MySQL não encontrado." 1>&2
	exit 1
fi

# Inicializa o log

if [ ! -d $LOG_DIR ]; then
	mkdir -p $LOG_DIR

	if [ $? -ne 0 ]; then
		echo "Não foi possível criar o diretório de log." 1>&2
		exit 1
	fi
elif [ ! -w $LOG_DIR ]; then
	echo "O diretório de log não possui permissão de escrita." 1>&2
	exit 1
fi

LOG_FILE="$LOG_DIR/dump-databases_$(date +'%Y-%m').log"

# Direciona a saída padrão e a saída de erros para o arquivo de log
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "\n=== Dump de banco de dados iniciado em: $(date +%c) ==="
echo "Diretório de dump: $DUMP_DIR"

for MYSQL_CNF_FILE in $(ls $MYSQL_CNF_DIR/*.cnf); do

	DBNAME=$(basename $MYSQL_CNF_FILE | cut -f1 -d.)
	echo "Gerando o dump do banco '$DBNAME'..."

	# Prepara o comando de dump
	MYSQL_DUMP="mysqldump --defaults-extra-file=$MYSQL_CNF_FILE --databases $DBNAME"

	# Diretório para o dump daquele banco de dados
	DUMP_DIR_DB="$DUMP_DIR/$DBNAME"
	if [ ! -d $DUMP_DIR_DB ]; then
		mkdir -p $DUMP_DIR_DB
	fi

	DATE=$(date +%F)
	IFS="-" read YEAR MONTH DAY <<< $DATE

	# Dump diário de hoje
	DUMP_DAILY="$DUMP_DIR_DB/dump-daily_${DBNAME}_$DATE.sql"
	$MYSQL_DUMP > $DUMP_DAILY

	if [ $? -ne 0 ]; then
		echo "Erro ao gerar o dump."
		continue
	fi

	echo "Dump gerado: $DUMP_DAILY"

	# Apaga os dumps diários com mais de 7 dias
	find $DUMP_DIR_DB -name "dump-daily_${DBNAME}_*.sql" -mtime +7 -exec echo "Excluindo dump diário antigo: {}" \; -exec rm {} \;

	# Se for domingo, salva o dump semanal
	if [ $(date +%u) = "7" ]; then
		DUMP_WEEKLY="$DUMP_DIR_DB/dump-weekly_${DBNAME}_$DATE.sql"
		echo "Salvando dump semanal: $DUMP_WEEKLY"
		cp $DUMP_DAILY $DUMP_WEEKLY
	fi

	# Apaga os dumps semanais com mais de 1 mês
	find $DUMP_DIR_DB -name "dump-weekly_${DBNAME}_*.sql" -mtime +31 -exec echo "Excluindo dump semanal antigo: {}" \; -exec rm '{}' \;

	# Se for o último dia do mês, salva o dump mensal
	LAST_DAY=$(cal | awk 'FNR>2{d+=NF}END{print d}')
	if [ $DAY = $LAST_DAY ]; then
		DUMP_MONTHLY="$DUMP_DIR_DB/dump-monthly_${DBNAME}_$YEAR-$MONTH.sql"
		echo "Salvando dump mensal: $DUMP_MONTHLY"
		cp $DUMP_DAILY $DUMP_MONTHLY
	fi

	# Apaga os dumps mensais com mais de 1 ano
	find $DUMP_DIR_DB -name "dump-monthly_${DBNAME}_*.sql" -mtime +365 -exec echo "Excluindo dump mensal antigo: {}" \; -exec rm '{}' \;

	# Se for o último dia do ano, salva o dump anual
	if [ $MONTH = "12" ] && [ $DAY = "31" ]; then
		DUMP_YEARLY="$DUMP_DIR_DB/dump-yearly_${DBNAME}_$YEAR.sql"
		echo "Salvando dump anual: $DUMP_MONTHLY"
		cp $DUMP_DAILY $DUMP_YEARLY
	fi

done
