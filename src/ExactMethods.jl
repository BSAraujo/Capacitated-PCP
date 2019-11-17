
function solveCPCP_D(params; verbose=true)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity
    time_limit = params.max_time

    F = 1:n # facilities
    C = 1:n # customers

    LB = minimum(D)
    UB = maximum(D)

    ### -----------------------------------------------------
    # Optimization model
    model = Model(solver=GurobiSolver(TimeLimit=time_limit, OutputFlag=verbose)) # version 0.18 of JuMP

    # Variables
    @variable(model, x[F,C], Bin)
    @variable(model, y[F], Bin)
    @variable(model, LB <= z <= UB)

    # Objective
    @objective(model, Min, z);

    # Constraints
    @constraint(model, con2[j in C], sum(x[i,j] for i in F) == 1)
    @constraint(model, con3, sum(y[i] for i in F) <= p)
    @constraint(model, con4[j in C], z >= sum(D[i,j] * x[i,j] for i in F))
    @constraint(model, con5[i in F], sum(demand[j] * x[i,j] for j in C) <= capacity[i] * y[i])

    # Solve
    println()
    start = time();
    # optimize!(model)
    status = solve(model) # version 0.18 of JuMP
    solvetime = getsolvetime(model)
    elapsed = time() - start;
    obj_lb = getobjectivebound(model);
    obj_ub = getobjectivevalue(model);

    if verbose
        println()
        println("Obj. LB = $obj_lb")
        println("Obj. UB = $obj_ub")
        println("Status: $status")
        println("Solve time: $solvetime")
        println("Number of nodes: ", getnodecount(model))
    end

    # Recover solution
    x = getvalue(x);
    x = x[:,:] # convert JuMPArray to ordinary Array
    y = getvalue(y);
    y = y[:] # convert JuMPArray to ordinary Array
    z = getvalue(z);

    return obj_lb, obj_ub, status, solvetime, z, x, y
end