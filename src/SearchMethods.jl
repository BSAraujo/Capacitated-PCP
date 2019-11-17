include("Subproblem.jl")
include("Params.jl")


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
    return obj_lb, obj_ub, status, solvetime, zi, xi, yi
end


function BinarySearch(params; verbose=true)
    # TODO
    throw("not implemented")   
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
function LayeredSearch(params, distance_values, L, ilow, iup)
    if iup == ilow + 1
        ziup = distance_values[iup]
        return ziup
    end
    δ = ceil((iup - ilow - 1)^((L-1)/L))
    i = ilow
    isFeasible = false
    while (~isFeasible) && (i + δ < iup)
        i = i + δ
        zi = distance_values[i]
        isFeasible, xi, yi = solveCSCP_r(params, zi)
    end
    if isFeasible
        LayeredSearch(params, distance_values, L - 1, i - δ, i)
    else
        LayeredSearch(params, distance_values, L - 1, i, iup)
    end
end

function runLayeredSearch(params, L; verbose=true)
    n = params.n
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # Distinct values from the distance matrix, in increasing order
    distance_values = sort(unique(D))

    ilow = distance_values[1]
    iup = distance_values[end]
    zi = LayeredSearch(params, distance_values, L, ilow, iup)
    return zi
end
