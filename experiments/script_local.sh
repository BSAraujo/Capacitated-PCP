

instances='../instances/S1'/*
for folder in $instances
do
    for instance in $folder/*
    do
        echo "Executing: $instance"
        julia ../src/Main.jl $instance > output-$instance.txt
    done
done

