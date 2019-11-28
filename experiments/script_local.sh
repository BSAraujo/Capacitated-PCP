

instances='../instances/S1'/*
for folder in $instances
do
    for instance in $folder/*
    do
        echo $instance
        basename_instance=${instance##*/}
        echo "Executing: $basename_instance"
        # julia ../src/Main.jl $instance
    done
done

