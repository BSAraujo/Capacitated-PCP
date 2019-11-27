
echo $PBS_O_WORKDIR
echo $flagils 
echo $instance
/usr/local/bin/julia $PBS_O_WORKDIR/../src/Main.jl --enable_ils $flagils $PBS_O_WORKDIR/$instance