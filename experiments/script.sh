

# instances='../instances/S1'/*
# for folder in $instances
# do
#     for instance in $folder/*
#     do
#         basename_instance=${instance##*/}
#         echo "Executing: $basename_instance"
#         julia ../src/Main.jl  --enable_ils 1 $instance > results/sol-$basename_instance
#     done
# done


# # This code below only regads p550 (testing purposes)
# instances='../instances/S1/p550'/*
# for instance in $instances
# do
#     basename_instance=${instance##*/}
#     echo "Executing: $basename_instance"
#     julia ../src/Main.jl  --enable_ils 1 $instance > results/sol-$basename_instance
#     break
# done