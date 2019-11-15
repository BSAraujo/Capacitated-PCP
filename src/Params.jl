struct Params
    # GENERAL PARAMETERS
    instance_path::String            # Path to the instance
    output_path::String              # Path to the output solution
    # PARAMETERS OF THE ALGORITHM
    seed::Int 
    max_time::Int 
    # DATASET INFORMATION
    dataset_name::String
    n::Int64
    p::Int64
    D::Array{Int64}
    demand::Array{Int64}
    capacity::Array{Int64}
    solution_cost::Any
    solution::Any
end


function Params(instance_path::String, output_path::String, seed::Int, max_time::Int)
    """
    Constructor of struct Params  
    """
    dataset_name = split(instance_path, '/')[end]
    n, p, D, demand, capacity = loadInstance(instance_path)

    solution_name = split(dataset_name,'.')[1]*".sln"
    solution_path = joinpath(join(split(instance_path,'/')[1:end-2],'/'),"solutions",solution_name)

    if isfile(solution_path)
        sz_sol, cost, sol = loadSolution(solution_path)
        if sz != sz_sol
            throw("Size in instance file and solution file should be the same!")
        end
    else
        cost = NaN
        sol = NaN
    end
    params = Params(instance_path, output_path, seed, max_time, dataset_name, 
                    n, p, D, demand, capacity, sol, cost)
    return params
end

function loadInstance(instance_path::String)
    """
    Loads instance file
    """

    lines = readlines(instance_path)

    lines = map(x->strip(x), lines)

    n,p = map(x->parse(Int64, x), split(lines[1], r"\s+"))

    D = join(lines[2:end-2], " ")
    D = map(x->parse(Int64, x), split(D, r"\s+"))
    D = reshape(D,n,n)

    demand = map(x->parse(Int64, x), split(lines[end-1], r"\s+"))

    capacity = map(x->parse(Int64, x), split(lines[end], r"\s+"))

    return n, p, D, demand, capacity
end

function loadSolution(solution_path::String)
    """
    Loads solution file
    """

    throw("not implemented")
end