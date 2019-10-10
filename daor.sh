#!/bin/bash
#
# \description  Execution on multiple networks
#
# \author Artem V L <artem@exascale.info>  https://exascale.info

APP=daor
FREEMEM="5%"  # >= "8G" for youtube; 5%
DIMS=128
#GRAPHS="blogcatalog dblp homo wiki youtube"
GRAPHS="blogcatalog dblp homo wiki"
GAMMAS="r=1"  # "=1 r=1 r:=1 r:"
BOUND=""
CSPOLICY='Ss'  # Cluster/embeddings selection policy. The meaningful range for the number of dimensions: -bspu r .. -bpu Sah%bg/g_les, recommended: -bspu Ssd%be/g_pgs
#CSPOLICY='Sah%bg/g_les'  # Cluster/embeddings selection policy. The meaningful range for the number of dimensions: -bspu r .. -bpu Sah%bg/g_les, recommended: -bspu Ssd%be/g_pgs
INSTS=0  # The number of network instances
#SYSENVUPD=1  # Adjust the system environment if required
RESTRACER=./exectime  # time
LOGDIR=embeds_${APP}/logs
NETDIR=networks  # nets_${APP}
mkdir -p $LOGDIR

USAGE="$0 -h | [-d <dimensions>=${DIMS}] [--gammas \"<gammaOpt> \"+] [--bound <bound>=\"s=${DIMS}\"] [--cspolicy <cls_policy>=\"${CSPOLICY}\"] [-g \"{`echo $GRAPHS | tr ' ' ','`} \"+] [--instances <number>] [-f <min_available_RAM>]
  -d,--dims  - required number of dimensions in the embedding model (root/top level),
 the actual number of dimensions in the model might be lower in the root/top level and higher on all levels
  --gammas  - gamma values. Default: \"$GAMMAS\"
  -b,--bound  - input graphs (networks) specified by the adjacency matrix in the .mat format. Default: \"s=<dims>\"
  -c,--cspolicy  - clusters (embedding dimensions) selection policy. Default: $CSPOLICY
  -g,--graphs  - input graphs (networks) specified by the adjacency matrix in the .mat format. Default: \"$GRAPHS\"
  --instances  - the number of network instances (samples)
  -f,--free-mem  -  limit the minimal amount of the available RAM to start subsequent job. Default: $FREEMEM
  -h,--help  - help, show this usage description

  Examples:
  \$ $0 -d 128
  \$ $0 --gammas \"=1 r=1 r:\" --bound sp=256 -c 'Sah%bg/g_les'
"
#  --retain-sysenv  - do not change the system environment settings

if [ $# -lt 1 ]; then
	echo -e "Usage: $USAGE"  # -e to interpret correctly '\n'
	exit 1
fi

while [ "$1" != '' ]; do
	case $1 in
	-h|--help)
		# Use defaults for the remained parameters
		echo -e $USAGE # -e to interpret '\n'
		exit 0
		;;
	-d|--dims)
		if [ "${2::1}" = "-" ] || [ $2 -lt 0 ] || [ $? -ne 0 ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		DIMS=$2
		echo "Set $1: $2"
		shift 2
		;;
	--gammas)
		if [ "${2::1}" = "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		GAMMAS=$2
		echo "Set $1: $2"
		shift 2
		;;
	-b|--bound)
		if [ "${2::1}" = "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		BOUND=$2
		echo "Set $1: $2"
		shift 2
		;;
	-c,--cspolicy)
		if [ "\'${2::1}\'" = "\'-\'" ]; then
			echo "ERROR, invalid argument value of $1: \'$2\'"
			exit 1
		fi
		CSPOLICY=$2
		echo "Set $1: $2"
		shift 2
		;;
	-g|--graphs)
		if [ "${2::1}" = "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		GRAPHS=$2
		echo "Set $1: $2"
		shift 2
		;;
	--instances)
		if [ "${2::1}" = "-" ] || [ $2 -lt 0 ] || [ $? -ne 0 ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		INSTS=$2
		echo "Set $1: $2"
		shift 2
		;;
	-f|--free-mem)
		if [ "${2::1}" = "-" ]; then
			echo "ERROR, invalid argument value of $1: $2"
			exit 1
		fi
		FREEMEM=$2
		echo "Set $1: $2"
		shift 2
		;;
#	--retain-sysenv)
#		SYSENVUPD=0
#		shift
#		;;
	*)
		printf "Error: Invalid option specified: $1 $2 ...\n\n$USAGE"
		exit 1
		;;
	esac
done

MAX_SWAP=5  # Max swappiness
if [ `cat /proc/sys/vm/swappiness` -gt $MAX_SWAP ] # && [ $SYSENVUPD -ne 0 ]
then
	echo "Setting vm.swappiness to $MAX_SWAP (Ctrl + C to omit)..."
	sudo sysctl -w vm.swappiness=$MAX_SWAP
	# [ $? ] && exit $?
fi

if [ "$LC_ALL" = '' ]  # Note: "" = '' -> True
then
	export LC_ALL="en_US.UTF-8"
	export LC_CTYPE="en_US.UTF-8"
	export LANGUAGE="en_US.UTF-8"
fi

if [ "$BOUND" = "" ]; then
	BOUND="s=$DIMS"
fi

# Quote CSPOLICY
#printf "%q" "$CSPOLICY"
#CSPOLICY=`printf "%q" "$CSPOLICY" | sed 's:/:\/:g'`
CSPOLICYSTR=`printf "%q" "$CSPOLICY" | sed 's:[%/]:-:g'`
#CSPOLICYSTR=`echo "$CSPOLICY" | sed 's:[%/]:-:g'`

# Check exictence of the requirements
UTILS="free sed bc parallel"  # awk
for UT in $UTILS; do
	$UT --version
	ERR=$?
	if [ $ERR -ne 0 ]; then
		echo "ERROR, $UT utility is required to be installed, errcode: $ERR"
		exit $ERR
	fi
done

if [ "${FREEMEM:(-1)}" = "%" ]; then
	# Remove the percent sign and evaluate the absolute value from the available RAM
	#FREEMEM=${FREEMEM/%%/}
	#FREEMEM=${FREEMEM::-1}
	#FREEMEM=`free | awk '/^Mem:/{print $2"*1/100"}' | bc` # - total amount of memory (1%); 10G
	FREEMEM=`free | sed -rn "s;^Mem:\s+([0-9]+).*;\1*${FREEMEM::-1}/100;p" | bc`
fi
echo "FREEMEM: $FREEMEM"

echo -e "\n\nStarting the training on `echo $GRAPHS | wc -w` networks using `echo $GAMMAS | wc -w` gammas giving the FREEMEM=${FREEMEM}..."
if [ "$INSTS" -ge 1 ]; then
	parallel --header : --results "$LOGDIR" --joblog "$LOGDIR/parallel.res" --bar --plus --tagstring {1}{3}_g{2}_c${CSPOLICYSTR} --verbose --noswap --memfree ${FREEMEM} --load 96% $RESTRACER ./${APP} -t -g{2} -b$BOUND -c${CSPOLICY}=embeds_${APP}/{1}{3}_g{2}-${CSPOLICYSTR}_${DIMS}.cnl -v=embeds/embs${DIMS}/embs_${APP}-g{2}-c${CSPOLICYSTR}_{1}{3}.nvc ${NETDIR}/{1}{3}.nse "2> ${LOGDIR}/{1}{3}_g{2}-${CSPOLICYSTR}_${DIMS}.err" ::: nets $GRAPHS ::: gammas $GAMMAS ::: instances $(seq $INSTS)
else
	parallel --header : --results "$LOGDIR" --joblog "$LOGDIR/parallel.res" --bar --plus --tagstring {1}_g{2}_c${CSPOLICYSTR} --verbose --noswap --memfree ${FREEMEM} --load 96% $RESTRACER ./${APP} -t -g{2} -b$BOUND -c${CSPOLICY}=embeds_${APP}/{1}_g{2}-${CSPOLICYSTR}_${DIMS}.cnl -v=embeds/embs${DIMS}/embs_${APP}-g{2}-c${CSPOLICYSTR}_{1}.nvc ${NETDIR}/{1}.nse "2> ${LOGDIR}/{1}_g{2}-${CSPOLICYSTR}_${DIMS}.err" ::: nets $GRAPHS ::: gammas $GAMMAS
fi

# ./exectime ./${APP} -t -gr: -bsp=32 -cSsd%bg/g_1067s=embeds_${APP}/youtube_grv_bsp32_Ssd-bg-g_1067.cnl -v=embeds_${APP}/youtube_grv_bsp32_Ssd-bg-g_1067.nvc networks/youtube.nse 2> embeds_${APP}/logs/youtube_grv_bsp32_Ssd-bg-g_1067.err 1> embeds_${APP}/logs/youtube_grv_bsp32_Ssd-bg-g_1067.log
#
#for GRAPH in $GRAPHS; do
#for GAM in $GAMMAS; do
#	if [ "$INSTS" -ge "1" ]; then
#		for N in $(seq $INSTS); do
#			echo "Starting on ${GRAPH}${N}_${GAM}_$DIMS"
#			$RESTRACER ./${APP} -t -g$GAM -bs=$DIMS -cSs=embeds_${APP}/${GRAPH}${N}_${GAM}-Ss_${DIMS}.cnl -v=embeds/embs${DIMS}/embs_${APP}${GAM}_${GRAPH}${N}.nvc ${NETDIR}/${GRAPH}${N}.nse 2> ${LOGDIR}/${GRAPH}${N}_${GAM}-Ss_${DIMS}.err 1> ${LOGDIR}/${GRAPH}${N}_${GAM}-Ss_${DIMS}.log &
#		done
#	else
#		echo "Starting on ${GRAPH}_${GAM}_$DIMS"
#		$RESTRACER ./${APP} -t -g$GAM -bs=$DIMS -cSs=embeds_${APP}/${GRAPH}_${GAM}-Ss_${DIMS}.cnl -v=embeds/embs${DIMS}/embs_${APP}${GAM}_${GRAPH}.nvc ${NETDIR}/${GRAPH}.nse 2> ${LOGDIR}/${GRAPH}_${GAM}-Ss_${DIMS}.err 1> ${LOGDIR}/${GRAPH}_${GAM}-Ss_${DIMS}.log &
#	fi
#done
#done
