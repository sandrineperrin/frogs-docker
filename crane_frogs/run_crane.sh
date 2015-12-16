#! /bin/bash


# Script pour régénérer automatiquement tous les outils de FROGS à partir d'un dépôt github
# par build des images.

CWD=`pwd`

# Set variables
export nb_cpu=1
export java_mem=1024

# Check argument
if [ "$#" -ne 1 ]; then echo MISSING path argument ; exit 1 ; fi

# Check directory
if [ "${1:0:1}" == "/" ]; then DIR=$1 ; else DIR=${CWD}/$1 ; fi

if [ ! -d $DIR ]; then echo ERROR  path not exist $DIR; exit 1 ; fi

CRANE=$(find $DIR -maxdepth 2 -type f -name "crane.yml")

if [ "X$CRANE" == "X" ]; then echo FAIL crane.yml no found ; exit 1;  fi

CRANE_DIR=$(dirname $CRANE)
CRANE_DATA=${CRANE_DIR}/data

if [ ! -d $CRANE_DIR ]; then echo ERROR  crane dir not exist at  $CRANE_DIR ; exit 1 ; fi
if [ ! -d $CRANE_DATA ]; then echo ERROR  crane data not exist at  $CRANE_DATA ; exit 1 ; fi

echo CRANE dir : $CRANE_DIR
echo CRANE yml : $CRANE

# Arrêter les processus docker en cours
# // sous-script de nettoyage
docker rm $(docker ps -aq) 2> /dev/null

# Save last crane.yml file
d=`date +%Y%m%d_%H%M%S` 
mv $CRANE_DIR/data/out $CRANE_DIR/data/${d}_out

# Save previous version in output directory
cp $CRANE $CRANE_DIR/data/${d}_out/${d}_crane.yml

# rename out data directory
mkdir $CRANE_DIR/data/out

# Go to directory
cd $CRANE_DIR


# Update crane file
cp -p $CRANE $CRANE.tmp

# Update data path in crane file
sed -i "s#\(volume: \\[\).*\(:/tmp\)#\1$CRANE_DATA\2#" $CRANE

# Parse docker images output to find image name and version
for images in $(docker images | grep frogs | awk '{ print $1":"$2 }')
do
	l=$( echo $images | grep -o "/.*:")
        name=${l:1:-1}

	# Update crane file with tool name and version
	sed -i "s#\(image:\) .*${name}.*#\1 $images#" $CRANE.tmp
	
	if [ $? -ne 0 ]
	then 
		echo FAIL update crane file for images $images
		# rm $CRANE.tmp
		exit 1
	fi 
done

rm $CRANE
mv $CRANE.tmp $CRANE

# less $CRANE | grep image

echo WORKDIR is $(pwd)
crane run norm

crane run wkf


# Back
cd $CWD
