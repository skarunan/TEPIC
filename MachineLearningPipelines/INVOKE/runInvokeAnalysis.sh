#!/bin/bash   
echo "Loading parameters from config file " $1
source invokeAnalysis.cfg $1


#This part runs the necessary scripts to perform a differential analysis using TEPIC affinity ratios
#DO NOT DO ANY CHANGES HERE!
if [ -n "$coverageFile" ] && [ -n "$coverageColumn" ] ;                                                                                                                                                                                            
then
     echo The parameters coverageFile and coverageColumn are mutualy exclusive
     exit 1;
fi


mkdir $outputDirectory
mkdir $outputDirectory"/Affinities"

if [ -z "$preComputedTEPIC" ];
then
echo "Running TEPIC for all files"
counter=0
for file in $open_regions
do
	prefix=$(basename -s .bed $file)
	echo $prefix
	if [ -z "$coverageFile" ] && [ -z $coverageColumn ] ;
	then
		if [ "$peakFeature" == "TRUE" ];
		then
		     echo bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -e $decay
	     	bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -e $decay
		else
		    echo bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -e $decay -u
	     	bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -e $decay -u
		fi
	fi	
	if [ -n "$coverageFile" ] ;
	then
		cfile=${coverageFile[${counter}]}
		if [ "$peakFeature" == "TRUE" ];
		then
		     echo bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -d $cFile -e $decay
		     bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -d $cFile -e $decay
		else
		     echo bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -d $cFile -e $decay -u
		     bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -d $cFile -e $decay -u
		fi
		((counter++))
	fi
	if [ -n "$coverageColumn" ] ;
	then
		cCol=${coverageColumn[${counter}]}
		if [ "$peakFeature" == "TRUE" ];
		then
		     echo bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -n $cCol -e $decay
		    	bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -n $cCol -e $decay
		else
		     echo bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -d $cFile -e $decay -u
		     bash ${path}/Code/TEPIC.sh -g $referenceGenome -b $file -o $outputDirectory/Affinities/$prefix -p $pwm -c $cores_TEPIC -a $geneAnnotation -w $window -d $cFile -e $decay -u
		fi
		((counter++))
	fi
done
else
echo "Using precomputed TEPIC results"
fi


echo "Combining TF affinities with gene expression data"
mkdir $outputDirectory"/IntegratedData/"
counter=0
if [ -z "$preComputedTEPIC" ];
then
for file in $open_regions
do
	prefix=$(basename -s .bed $file)
	echo $prefix 
	exp=${gene_Expression_Data[${counter}]}
	((counter++))
	if [ -z "$coverageFile" ] && [ -z $coverageColumn ] ;
	then
		if [ "$peakFeatures" == "TRUE"] ;
		then
			echo python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*Peak_Features_Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
			python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*Peak_Features_Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
		else
			echo python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
			python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
		fi
	else
 		if [ "$peakFeatures" == "TRUE"] ;
		then
			echo python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*Three_Peak_Based_Features_*Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
			python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*_Three_Peak_Based_Features_*Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
		else
			echo python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*Signal_Feature_*Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
			python ${scriptPath}/integrateData.py ${outputDirectory}/Affinities/${prefix}*_Signal_Feature_*Affinity_Gene_View_Filtered.txt ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
		fi
	fi
done
else
for file in $preComputedTEPIC
do
	prefix=$(basename -s .txt $file)
	exp=${gene_Expression_Data[${counter}]}
	((counter++))
	echo python ${scriptPath}/integrateData.py ${file} ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt
	python ${scriptPath}/integrateData.py ${file} ${exp} ${outputDirectory}/IntegratedData/${prefix}_Integrated.txt

done
fi

echo "Starting linear regression"
mkdir ${outputDirectory}"/Learning_Results"
echo Rscript ${scriptPath}/INVOKE.R --dataDir=${outputDirectory}/IntegratedData/ --outDir=${outputDirectory}/Learning_Results/ --response=Expression --cores=$cores_R --alphas=${alpha_Step_Size} --regularisation=${regularisation} --testsize=${testsize} --innerCV=${innerCV} --outerCV=${outerCV} --performance=${performance}
Rscript ${scriptPath}/INVOKE.R --dataDir=${outputDirectory}/IntegratedData/ --outDir=${outputDirectory}/Learning_Results/ --response=Expression --cores=$cores_R --alphas=${alpha_Step_Size} --regularisation=${regularisation} --testsize=${testsize} --innerCV=${innerCV} --outerCV=${outerCV} --performance=${performance}

if [ "$randomise" == "TRUE" ];
then
	mkdir ${outputDirectory}"/Learning_Results_Random"
	echo Rscript ${scriptPath}/INVOKE.R --dataDir=${outputDirectory}/IntegratedData/ --outDir=${outputDirectory}/Learning_Results_Random --response=Expression --cores=$cores_R --alphas=${alpha_Step_Size} --regularisation=${regularisation} --testsize=${testsize} --innerCV=${innerCV} --outerCV=${outerCV} --performance=${performance} --randomise=${randomise}
	Rscript ${scriptPath}/INVOKE.R --dataDir=${outputDirectory}/IntegratedData/ --outDir=${outputDirectory}/Learning_Results_Random --response=Expression --cores=$cores_R --alphas=${alpha_Step_Size} --regularisation=${regularisation} --testsize=${testsize} --innerCV=${innerCV} --outerCV=${outerCV} --performance=${performance} --randomise=${randomise}
fi

