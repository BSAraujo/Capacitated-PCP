include("Params.jl")
include("Commandline.jl")

# instance_path = "../instances/S1/p550/p550-1.txt"

function main()

    c = Commandline()

    println("Input File: \"",c.instance_path,"\"")
    println("Running code with seed=", c.seed)
    # Initialization of the problem data from the commandline
    params = Params(c.instance_path, c.output_path, c.seed, c.cpu_time)

    println(string("Number of nodes: n=", params.n))
    println(string("Maximum number of facilities to be opened: p=", params.p))
end

main()