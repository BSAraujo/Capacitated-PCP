

instances='../instances/S1'/*
for folder in $instances
do
    for instance in $folder/*
    do
        echo "Executing: $instance"
        basename_instance=${instance##*/}
        julia ../src/Main.jl $instance > output-$basename_instance.txt
    done
done

