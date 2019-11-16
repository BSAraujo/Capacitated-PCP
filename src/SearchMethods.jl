include("Subproblem.jl")
include("Params.jl")


function SequentialSearch(params; verbose=true)
    n = params.n
    D = params.D
    p = params.p
    D = params.D
    demand = params.demand
    capacity = params.capacity

    # Distinct values from the distance matrix, in increasing order
    distance_values = sort(unique(D))

    # Solve subproblems in increasing order of z and 
    # stop as soon as a feasible solution is found.
    isFeasible = false
    i = 1
    xi = nothing
    yi = nothing
    zi = nothing
    while (~isFeasible)
        zi = distance_values[i]
        if verbose
            println("SS: i=$i; zi=$zi")
        end
        isFeasible, xi, yi = solveCSCP_r(params, zi, verbose=false)
        i += 1
    end
    return xi, yi, zi
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
    D = params.D
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
