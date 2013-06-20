#!/bin/sh
#/************************************************************************
# * Copyright (c) 2011 doujinshuai (doujinshuai@gmail.com)
# * Last Modified: 03-30-2011
# * 
# * Describe: 
# * 
# * Example: mongo_backup.sh -f bak.cfg -a dump
# *          mongo_backup.sh -f bak.cfg -a restore 
# ************************************************************************/


################################################
######       Function Define start        ######
################################################
#/*
# * 文件或目录检查函数
# * @arg1是shell的文件状态检查的参数,具体使用参考shell编程test用法
# * @arg2是待检查的文件或目录
#*/ 
function func_check_file()
{
	type=$1
	filepath=$2
	if [ ! -$type "$filepath" ]; then
		echo "Error: $filepath dont existed; Please check this file or directory."
		exit 99
	fi
}

#/*
# * 检查dump数据操作所需要的参数
#*/
function check_dump_args()
{
	func_check_file d $DUMP_PATH
	func_check_file n $DUMP_HOST
	func_check_file n $DUMP_PORT
	func_check_file f $CMD_TAR
	func_check_file f $CMD_MONGODUMP
	[ -n "$DUMP_HOST" ] && DUMP_OPTIONS=" --host $DUMP_HOST"
	[ -n "$DUMP_PORT" ] && DUMP_OPTIONS=$DUMP_OPTIONS" --port $DUMP_PORT"
	[ -n "$DUMP_DB" ] && DUMP_OPTIONS=$DUMP_OPTIONS" --db $DUMP_DB"
	[ -n "$MONGO_USER" -a -f "$MONGO_PASS" ] && DUMP_OPTIONS=$DUMP_OPTIONS" -u $MONGO_USER -p $MONGO_PASS"

}

#/*
# * function dump
#*/
function func_dump()
{
	#/*
	# * exec dump
	#*/
	cd $DUMP_PATH;
	[ -f "working_$DUMP_PORT.flag" ] && { echo "Dump is working"; exit 1; }

	DUMP_DATA_PATH=$(/bin/date '+%Y%m%d_%H%M%S')"_$DUMP_PORT"
	echo -e "\n\n********* Start dump $DUMP_PORT $DUMP_DB at $(/bin/date '+%F %T') ******************"
	/bin/touch working_$DUMP_PORT.flag
	echo "$CMD_MONGODUMP $DUMP_OPTIONS -o $DUMP_DATA_PATH > $DUMP_DATA_PATH.log"
	$CMD_MONGODUMP $DUMP_OPTIONS -o $DUMP_DATA_PATH > $DUMP_DATA_PATH.log 2>&1
	if [ $? -eq 0 ];then
		/bin/rm working_$DUMP_PORT.flag
		echo -e "*********End dump $DUMP_PORT $DUMP_DB at $(/bin/date '+%F %T') ******************\n"
	fi

	#/*
	# * archiving and compress
	#*/
	$CMD_TAR -zcf ${DUMP_DATA_PATH}.tar.gz $DUMP_DATA_PATH $DUMP_DATA_PATH.log && /bin/rm -fr $DUMP_DATA_PATH $DUMP_DATA_PATH.log || echo "tar operate failed."

	#/*
	# * send remote storge server
	#*/
	if [ 1 = "$RSYNC_OPTS" ]; then
		func_check_file f $CMD_RSYNC
		func_check_file n $RSYNC_HOST
		func_check_file n $RSYNC_PATH
		[ -n "$RSYNC_USER" -a -f "$RSYNC_PWD_FILE" ] && RSYNC_AUTH="--password-file=$RSYNC_PWD_FILE ${RSYNC_USER}@"
		[ -n "$RSYNC_LIMIT" ] && RSYNC_OPTIONS=" --bwlimit=${RSYNC_LIMIT}"

		sleep $SLEEP_SET
		echo -e "\n*********Start rsync ${DUMP_DATA_PATH}.tar.gz at $(/bin/date '+%F %T') ******************"

		echo "$CMD_RSYNC -Pvrtopgl $RSYNC_OPTIONS ${DUMP_DATA_PATH}.tar.gz ${RSYNC_AUTH}${RSYNC_HOST}::${RSYNC_PATH}/"
		$CMD_RSYNC -Pvrtopgl  $RSYNC_OPTIONS ${DUMP_DATA_PATH}.tar.gz ${RSYNC_AUTH}${RSYNC_HOST}::${RSYNC_PATH}/
		if [ $? -eq 0 ];then
			/bin/rm ${DUMP_DATA_PATH}.tar.gz || echo "clean monog bakup file failed."
			echo -e "*********End rsync ${DUMP_DATA_PATH}.tar.gz at $(/bin/date '+%F %T') ******************\n\n"
		fi
	fi
	exit 0
}

#/*
# * check args
#*/
function check_restore_args()
{
	func_check_file f $CMD_MONGORESTORE
	func_check_file n $RESTORE_HOST
	func_check_file n $RESTORE_PORT
	[ -n "$RESTORE_HOST" ] && RESTORE_OPTIONS=" --host $RESTORE_HOST"
	[ -n "$RESTORE_PORT" ] && RESTORE_OPTIONS=$RESTORE_OPTIONS" --port $RESTORE_PORT"
	[ -n "$RESTORE_DB" ] && RESTORE_OPTIONS=$RESTORE_OPTIONS" --db $RESTORE_DB"
	[ -n "$MONGO_USER" -a -f "$MONGO_PASS" ] && RESTORE_OPTIONS=$RESTORE_OPTIONS" -u $MONGO_USER -p $MONGO_PASS"
}

#/*
# * function restore data
#*/
function func_restore()
{
	WorkDir=$(basename $0)
	cd $WorkDir
	if [ -d "$RESTORE_PATH" ];then
		echo -e "\n\n********* Start restore $RESTORE_PORT $RESTORE_DB on $(/bin/date '+%F %T') ******************"
		/bin/touch working_$RESTORE_PORT.flag
		echo "$CMD_MONGORESTORE $RESTORE_OPTIONS $RESTORE_PATH"
		$CMD_MONGORESTORE $RESTORE_OPTIONS $RESTORE_PATH
		if [ $? -eq 0 ];then
			/bin/rm working_$RESTORE_PORT.flag
			echo -e "********* End restore $RESTORE_PORT $RESTORE_DB on $(/bin/date '+%F %T') ******************\n\n"
		fi
		exit 0
	fi
	sleep $SLEEP_SET
}

#/*
# * 帮助
#*/
function usage ()
{
	echo "Usage: $0 [OPTIONS]"
	echo "  -c : 配置文件名,dump.cfg"
	echo "  -a : 操作,[dump|restore]"
	echo "  -h : 帮助" 
	echo ""
}


################################################
######    Main program start execute      ######
################################################
#/*
# * 获取命令行参数
#*/
while getopts "c:a:h:" OPT
do
	case $OPT in
		c)  CONF_FILE=$OPTARG ;;
		a)  ACTION=$OPTARG ;;
		h)  usage
			exit 0 ;;
		\?)
			usage
			exit 0 ;;
	esac
done

if [ $OPTIND -le 1 ];then
	usage
	exit 0
fi

#/*
# * 初始化环境变量
#*/
#source $HOME/.bash_profile
source /etc/profile

#/*
# * 检查备份参数配置文件，并初始化
#*/
func_check_file f $CONF_FILE && source $CONF_FILE

#/*
# * 检查初始化参数
#*/
[ -z "$CMD_TAR" ] && CMD_TAR=$(which tar)
[ -z "$CMD_RSYNC" ] && CMD_RSYNC=$(which rsync)
[ -z "$CMD_MONGODUMP" ] && CMD_MONGODUMP=$(which mongodump)
[ -z "$CMD_MONGORESTORE" ] && CMD_MONGODUMP=$(which mongorestore)
[ -z "$SLEEP_SET" ] && SLEEP_SET=30

#/*
# * 主程序 
#*/
if [ -n "$ACTION" ]; then
	case $ACTION in
		dump)
			check_dump_args
			func_dump
			;;
		restore)
			check_restore_args
			func_restore
			;;
		*)
			echo "UNKONW 操作"
			usage
			exit -1
			;;
	esac
fi
 
echo "done"
exit 0
