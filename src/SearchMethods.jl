
function SequentialSearch(params; verbose=true)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # Start counting solve time
    start = time();

    # Distinct values from the distance matrix, in increasing order
    distance_values = sort(unique(D))
    ils_solution_cost = -1
    # Get initial solution from ILS
    if params.enable_ils
        solution, ils_solution_cost = ILS(params)
        distance_values = distance_values[distance_values .<= ils_solution_cost]
    end

    # Solve subproblems in increasing order of z and
    # stop as soon as a feasible solution is found.
    isFeasible = false
    obj_lb = distance_values[1]
    obj_ub = distance_values[end]
    xi = nothing
    yi = nothing
    zi = nothing
    status = nothing
    i = 1
    while (~isFeasible)
        # Check if there is any remaining time from time budget
        remaining_time = params.max_time - (time() - start)
        if remaining_time < 0
            status = :UserLimit
            break
        end

        # Get next distance value
        zi = distance_values[i]
        if verbose
            println(string("SS: i=$i; zi=$zi; LB=$obj_lb; UB=$obj_ub; Time=",
                           round(time() - start, digits=2),"s"))
        end

        # Run Subproblem
        isFeasible, status, xi, yi = solveCSCP_r(params, zi,
                                                 time_limit=remaining_time,
                                                 verbose=false)

        # Check if Subproblem returned UserLimit status
        if status == :UserLimit
            zi = distance_values[i-1]
            break
        end

        obj_lb = zi
        i += 1
    end

    # Update Upper Bound (if a feasible solution was found)
    if status != :UserLimit
        obj_ub = zi
    end
    solvetime = time() - start;
    return obj_lb, obj_ub, status, solvetime, zi, xi, yi, ils_solution_cost
end




function BinarySearch(params; verbose=true)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # Start counting solve time
    start = time();
    status = nothing
    zi = nothing
    xi = nothing
    yi = nothing
    # Distinct values from the distance matrix, in increasing order
    distance_values = sort(unique(D))
    ils_solution_cost = -1
    # Get initial solution from ILS
    if params.enable_ils
        solution, ils_solution_cost = ILS(params)
        distance_values = distance_values[distance_values .<= ils_solution_cost]
    end

    ilow = 1
    iup = length(distance_values)

    obj_lb, obj_ub = distance_values[ilow], distance_values[iup]
    while true
        # Base case
        if iup == ilow + 1
            zi = distance_values[iup]
            obj_lb = obj_ub = zi
            status = :Optimal
            break
        end

        # Check if there is any remaining time from time budget
        remaining_time = params.max_time - (time() - start)
        if remaining_time < 0
            zi = distance_values[iup]
            status = :UserLimit
            break
        end

        if verbose
            println("ilow=$ilow; iup=$iup; LB=$obj_lb; UB=$obj_ub")
        end

        imid = Int(floor((ilow + iup)/2))
        zi = distance_values[imid]

        # Run Subproblem
        remaining_time = params.max_time - (time() - start)
        isFeasible, status, xi, yi = solveCSCP_r(params, zi, time_limit=remaining_time, verbose=false)

        # Check if Subproblem returned UserLimit status
        if status == :UserLimit
            break
        end

        # Update LB and UB
        if isFeasible
            iup = imid
            obj_ub = zi
        else
            ilow = imid
            obj_lb = zi
        end
    end

    solvetime = time() - start;
    return obj_lb, obj_ub, status, solvetime, zi, xi, yi, ils_solution_cost
end



"""
(LAYERED SEARCH(L, ilow, iup))
1.  if iup = ilow + 1 then return ziup end if
2.  δ ← ceil((iup - ilow - 1)^((L-1)/L))
3.  i ← ilow
4.  isFeasible ← False
5.  while isFeasible = False and i + δ < iup do
6.      i ← i + δ
7.      isFeasible ← SOLVECSCP-r(zi)
8.  end
9.  if isFeasible = True then
10.     LAYERED SEARCH(L - 1, i - δ, i)
11. else
12.     LAYERED SEARCH(L - 1, i, iup)
13. end
"""
function LayeredSearchRecursive(params, distance_values, L, ilow, iup, start_time;
                                solution=(nothing, nothing), verbose=true)
    obj_lb, obj_ub = distance_values[ilow], distance_values[iup]
    xi, yi = solution

    if verbose
        println("L=$L; ilow=$ilow; iup=$iup")
    end

    # Check if there is any remaining time from time budget
    remaining_time = params.max_time - (time() - start_time)
    if remaining_time < 0
        ziup = distance_values[iup]
        status = :UserLimit
        return obj_lb, obj_ub, status, ziup, xi, yi
    end

    # Base case
    if iup == ilow + 1
        ziup = distance_values[iup]
        obj_lb = obj_ub = ziup
        status = :Optimal
        return obj_lb, obj_ub, status, ziup, xi, yi
    end
    # Calculate increment size
    δ = Int(ceil((iup - ilow - 1)^((L-1)/L)))
    if verbose
        println("δ=$δ")
    end
    i = ilow
    isFeasible = false
    while (~isFeasible) && (i + δ < iup)
        i = i + δ
        zi = distance_values[i]

        if verbose
            print("Solving CSCP-r for r=$zi; i=$i; Time: ")
            print(round(time() - start_time, digits=2))
            print("s")
        end

        # Run Subproblem
        remaining_time = params.max_time - (time() - start_time)
        isFeasible, status, xi, yi = solveCSCP_r(params, zi, time_limit=remaining_time, verbose=false)

        # Check if Subproblem returned UserLimit status
        if status == :UserLimit
            return obj_lb, obj_ub, status, zi, xi, yi
        end

        if verbose
            println("Feasible: $isFeasible")
        end
        # Update LB and UB
        if isFeasible
            obj_ub = zi
        else
            obj_lb = zi
        end
    end
    if isFeasible
        return LayeredSearchRecursive(params, distance_values, L - 1, i - δ, i, start_time, solution=(xi, yi), verbose=verbose)
    else
        return LayeredSearchRecursive(params, distance_values, L - 1, i, iup, start_time, verbose=verbose)
    end
end

function LayeredSearch(params, L; verbose=true)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # Start counting solve time
    start = time();

    # Distinct values from the distance matrix, in increasing order
    distance_values = sort(unique(D))
    ils_solution_cost = -1
    # Get initial solution from ILS
    if params.enable_ils
        solution, ils_solution_cost = ILS(params)
        distance_values = distance_values[distance_values .<= ils_solution_cost]
    end

    ilow = 1
    iup = length(distance_values)
    obj_lb, obj_ub, status, zi, xi, yi  = LayeredSearchRecursive(params, distance_values, L, ilow, iup, start, verbose=verbose)

    solvetime = time() - start;
    return obj_lb, obj_ub, status, solvetime, zi, xi, yi, ils_solution_cost
end
