

# instances='../instances/S1'/*
# for folder in $instances
# do
#     for instance in $folder/*
#     do
#         echo "Executing: $instance"
#         basename_instance=${instance##*/}
#         julia ../src/Main.jl $instance > output-$basename_instance.txt
#     done
# done
instances=('../instances/p66200/p66200-37.txt' '../instances/p66200/p66200-38.txt' '../instances/p66200/p66200-39.txt' '../instances/p66200/p66200-40.txt')
for instance in "${instances[@]}"
do
        echo "Executing: $instance"
        basename_instance=${instance##*/}
        # echo $instance
        # echo $basename_instance
        julia ../src/Main.jl $instance > output-$basename_instance.txt
done


for instance in "../instances/S1/p80200"/*
do
        echo "Executing: $instance"
        basename_instance=${instance##*/}
        # echo $instance
        # echo $basename_instance
        julia ../src/Main.jl $instance > output-$basename_instance.txt
done