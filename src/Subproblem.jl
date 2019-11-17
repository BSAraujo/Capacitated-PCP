using JuMP, AmplNLWriter, Gurobi

function getCoverageArea(params, r)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # Set of customers lying in the coverage area of facility i induced by radius r
    coverageC = Array{Array{Int64}}(undef, n) 
    for i=1:n
        coverageC[i] = [j for j=1:n if (D[i,j] <= r && demand[j] <= capacity[i])]
    end 

    # Set of facilities that can cover customer j within distance r
    coverageF = Array{Array{Int64}}(undef, n) 
    for j=1:n
        coverageF[j] = [i for i=1:n if (D[i,j] <= r && demand[j] <= capacity[i])]
    end 

    return coverageC, coverageF
end


function solveCSCP_r(params, r; time_limit=400, verbose=true)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # coverage area
    coverageC, coverageF = getCoverageArea(params, r)

    F = 1:n # facilities
    C = 1:n # customers

    ### -----------------------------------------------------
    # Optimization model
    model = Model(solver=GurobiSolver(TimeLimit=time_limit, OutputFlag=verbose)) # version 0.18 of JuMP

    # Variables
    @variable(model, x[i in F, j in coverageC[i]], Bin)
    @variable(model, y[F], Bin)

    # Objective
    @objective(model, Min, sum(y[i] for i in F));

    # Constraints
    @constraint(model, con12[j in C], sum(x[i,j] for i in coverageF[j]) == 1); 
    @constraint(model, con13[i in F], sum(demand[j] * x[i,j] for j in coverageC[i]) <= capacity[i] * y[i]); 

    # Solve
    println()
    start = time();
    # optimize!(model)
    status = solve(model) # version 0.18 of JuMP
    solvetime = getsolvetime(model)
    elapsed = time() - start;
    obj_value = getobjectivevalue(model);

    if verbose
        println()
        println("Status: $status")
        println("Objective: $obj_value");
        println("Solve time: $solvetime")
        println("Number of nodes: ", getnodecount(model))
    end

    isFeasible = obj_value <= p

    # Recover solution
    y = getvalue(y)
    yi = y[:] # convert JuMPArray to ordinary Array

    openF = findall(yi .== 1)

    x = getvalue(x)
    xi = zeros(Int64, n, n)
    for (i,j) in keys(x)
        xi[i,j] = x[i,j]
    end
    sol = zeros(Int64, n)
    for j in C
        # Check if any customer is assigned to more than one facility
        fac = findall(xi[:,j] .== 1)
        @assert length(fac) == 1
        @assert fac[1] in openF
        sol[j] = fac[1]
    end
    xi = sol
    
    return isFeasible, status, xi, yi
end
