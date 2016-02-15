#! /bin/bash


# Script pour régénérer automatiquement tous les outils de FROGS à partir d'un dépôt github
# par build des images.

FROM_BIOSHADOCK=false
PREFIX=frogs 
BIOSHADOCK=docker-registry.genouest.org/frogs/
CWD=`pwd`
FAIL=fail

# Check argument
if [ "$#" -ne 1 ]; then echo MISSING path argument ; exit 1 ; fi

# Check directory
if [ ! -d $DIR ]; then echo ERROR  path not exist $DIR; exit 1 ; fi

if [ "${1:0:1}" == "/" ]; then DIR=$1 ; else DIR=${CWD}/$1 ; fi

CRANE=$(find $DIR -type f -name "crane.yml")

if [ "X$CRANE" == "X" ]; then FAIL crane.yml no found ; exit 1;  fi

CRANE_DIR=$(dirname $CRANE)




# Arrêter les containers docker en cours
docker stop $(docker ps -q) 2> /dev/null

# // sous-script de nettoyage
docker rm $(docker ps -aq) 2> /dev/null

# Supprimer tous les containers précédents, préfixés avec frogs
# // sous-script de suppression images docker en fonction regex ?
for c in $(docker images | grep "frogs/" | tr -s ' ' | cut -d ' ' -f 3)
do
	docker rmi $c
done 

# Save last crane.yml file
d=`date +%Y%m%d_%H%M%S` 
new_crane=${CRANE_DIR}/${d}_crane.yml

# Create a updated crane file
cp -p $CRANE $new_crane

# rename out data directory
mv $CRANE_DIR/data/out $CRANE_DIR/data/${d}_out
mkdir $CRANE_DIR/data/out

# Go to directory
cd $DIR
init_dir=$(pwd -P)
echo Init dir $init_dir


#### Pour chaque outil (correspondant à un dossier)
# for d in $(find . -type f -name "Dockerfile" -exec dirname {} \;)
for d in $(ls -d *) 
do
	# Check a dockerfile in directory
	n=$(find $d -type f -name "Dockerfile" | wc -l)
	if [ "$n" -eq 0 ]; then echo No Dockerfile in directory $d, skipping ; echo ; continue ; fi
	
	# echo "------- in directory : $d"
	
	if [ "$FROM_BIOSHADOCK" == "true" ]
	then
		#  Push from BioShadock
		docker pull ${BIOSHADOCK}${d}:latest
		
		if [ $? -ne 0 ]; then STATUS=$FAIL ; echo FAIL push docker $d; exit 1; fi	
	else
		# Build docker image
		cd $d
	
		# Find build directory
		s=$(ls */Dockerfile | sort | tail -n 1)
		if [ -z "$s" ]; then STATUS=$FAIL ; echo FAIL not found Dockerfile in directory $d; exit 1; fi
		
		builddir=$(dirname $s)
		if [ ! -d $builddir ]; then STATUS=$FAIL ; echo FAIL directory does not exit $builddir ; exit 1; fi

		# echo $builddir is current build directory

		# se déplacer dans le dossier
		cd $builddir
		echo Find 	
		# récuperer le nom et la version de l'outil
		name=${builddir:0:-6}
		version=${builddir:$((${#builddir}-5))}

		# lancer le build
		docker build -t ${PREFIX}/${name}:${version} .
		
		if [ $? -ne 0 ]; then STATUS=$FAIL ; echo FAIL build docker $name $version; exit 1; fi	

		# Update crane file with tool name and version
		sed -i "s/\(image: $n\).*$/\1$v/" $CRANE	
	fi
	echo 

	cd $init_dir 

done

###### Lancement de crane.yml
if [ "$STATUS" == "$FAIL" ]
then 
	echo =========== FAIL create docker images
	cd $CWD
	exit 1
else
	echo =========== SUCCES create docker images
	echo --------    run crane
	$CRANE_DIR/run_crane.sh $DIR 
	cd $CWD
fi

