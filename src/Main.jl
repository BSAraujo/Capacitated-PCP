using JuMP, AmplNLWriter, Gurobi
include("Params.jl")
include("Commandline.jl")
include("ExactMethods.jl")
include("Subproblem.jl")
include("SearchMethods.jl")
include("ILS.jl")

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
    method = "CPCP_D"
    obj_lb = nothing 
    obj_ub = nothing 
    status = nothing 
    solvetime = nothing 
    z = nothing 
    x = nothing 
    y = nothing 
    ils_solution_cost = nothing 
    f = open("../experiments/output.csv", "a+") 

    obj_lb, obj_ub, status, solvetime, z, x, y, ils_solution_cost = solveCPCP_D(params)
    write(f, join([c.instance_path,"solveCPCP_D",obj_lb,obj_ub,z,status,ils_solution_cost,solvetime],";"))
    write(f, "\n")

    obj_lb, obj_ub, status, solvetime, z, x, y, ils_solution_cost = SequentialSearch(params)
    write(f, join([c.instance_path,"SequentialSearch",obj_lb,obj_ub,z,status,ils_solution_cost,solvetime],";"))
    write(f, "\n")

    obj_lb, obj_ub, status, solvetime, z, x, y, ils_solution_cost = BinarySearch(params)
    write(f, join([c.instance_path,"BinarySearch",obj_lb,obj_ub,z,status,ils_solution_cost,solvetime],";"))
    write(f, "\n")
    
    L = 2
    obj_lb, obj_ub, status, solvetime, z, x, y, ils_solution_cost = LayeredSearch(params,L )
    write(f, join([c.instance_path,"LayeredSearch-$L",obj_lb,obj_ub,z,status,ils_solution_cost,solvetime],";"))    
    write(f, "\n")

    L = 3
    obj_lb, obj_ub, status, solvetime, z, x, y, ils_solution_cost = LayeredSearch(params,L )
    write(f, join([c.instance_path,"LayeredSearch-$L",obj_lb,obj_ub,z,status,ils_solution_cost,solvetime],";"))    
    write(f, "\n")

    L = 4
    obj_lb, obj_ub, status, solvetime, z, x, y, ils_solution_cost = LayeredSearch(params,L )
    write(f, join([c.instance_path,"LayeredSearch-$L",obj_lb,obj_ub,z,status,ils_solution_cost,solvetime],";"))    
    write(f, "\n")

    close(f)

    #Short print
    #header: instance; method; LB; UB; z; status; ils_solution_cost; solvetime" 




end

main()