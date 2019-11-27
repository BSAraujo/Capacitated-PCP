

instances='../instances/S1'/*
for folder in $instances
do
    for instance in $folder/*
    do
        echo $instance
        basename_instance=${instance##*/}
        echo "Executing: $basename_instance"
        qsub -v instance="$instance",flagils=0 script_pbs_2step.sh
        qsub -v instance="$instance",flagils=1 script_pbs_2step.sh
    done
done

