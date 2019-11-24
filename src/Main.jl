using JuMP, AmplNLWriter, Gurobi
include("Params.jl")
include("Commandline.jl")
include("ExactMethods.jl")
include("Subproblem.jl")
include("SearchMethods.jl")
include("ILS.jl")
# instance_path = "../instances/S1/p550/p550-1.txt"


function main()

    c = Commandline()

    println("Input File: \"",c.instance_path,"\"")
    println("Running code with seed=", c.seed)

    if c.enable_ils
        println("ILS ON")
    else 
        println("ILS OFF")
    end

    # Initialization of the problem data from the commandline
    params = Params(c.instance_path, c.output_path, c.seed, c.cpu_time, c.enable_ils)

    println(string("Number of nodes: n=", params.n))
    println(string("Maximum number of facilities to be opened: p=", params.p))

    obj_lb, obj_ub, status, solvetime, z, x, y = solveCPCP_D(params)
    #Short print
    println("status: ",status,"; solvetime: ",solvetime,"; z: ",z)
    #Full print
    #println("obj_lb: ", obj_lb, "; obj_ub: ",obj_ub," ; status: ",status,"; solvetime: ",solvetime,"; z: ",z,";\nx: ",x,";\n y: ",y,";")
end

main()