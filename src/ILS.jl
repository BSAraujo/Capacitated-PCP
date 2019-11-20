
function constructSolution(params)
    overline_C = collect(1:params.n)
    facility_density = zeros(Float32,params.n)
    #Facility i, customer j
    for i=1:params.n
        max_density = -Inf
        for j=1:params.n
            density_value = params.D[i,j]/params.capacity[i]
            if density_value > max_density
                max_density = density_value
            end
        end
        facility_density[i] = max_density
    end

    # Each row is "facility,customer,customer,customer..."
    opened_facilities = Any[]
    assigned_customers = falses(params.n)
    #println("Calculated;")
    #In the loop below, we "delete" elements by setting infinity (INF)
    while length(opened_facilities) < params.p
        opening_facility = argmin(facility_density)
        current_capacity = params.capacity[opening_facility]
        customers_facility = params.D[:,opening_facility]
        #println(customers_facility)
        closestCustomers = Int[]
        #Inserting facility
        push!(closestCustomers, opening_facility)
        closestCustomer = -1
        #println("Opening facility: ",opening_facility)

        #Iterates whenever capacity is available
        while current_capacity >= 0
            
            #Selects the kth-closestCustomer (e.g., if the closestCustomer has been already assigneed, then the 2-closest.. then k-closestCustomer)
            while true
                closestCustomer = findmin(customers_facility)
                
                if closestCustomer[1] == Inf || ~assigned_customers[closestCustomer[2]]
                    break
                else
                    customers_facility[closestCustomer[2]] = Inf
                end
                
            end
            #println("closestCustomer: ",closestCustomer)
            #There is no remaining customer 
            if closestCustomer[1] == Inf
                break
            end
            
            #println("current_capacity: ", current_capacity, ", customer demand: ", params.demand[closestCustomer[2]])
            #demands exceeds facility's capacity. Then we ignore the current customer and go to the next one
            if params.demand[closestCustomer[2]] > current_capacity
                customers_facility[closestCustomer[2]] = Inf
            else
                #println("customer inserted")
                #current customer fits in the facility capacity
                push!(closestCustomers,closestCustomer[2])
                current_capacity = current_capacity - params.demand[closestCustomer[2]]
                assigned_customers[closestCustomer[2]] = true
                customers_facility[closestCustomer[2]] = Inf
            end
        end
        # facility is opened 
        facility_density[opening_facility] = Inf
       # println(closestCustomers)
        push!(opened_facilities,closestCustomers)
    end
    
    if ~checkFeasible(params,opened_facilities)
        throw("initial solution is not feasible")
    end

    # #Checker START
    # counter = 0
    # for i = 1:size(opened_facilities)[1]
    #      counter = counter + size(opened_facilities[i])[1] - 1
    # end
    # nb_unassigned_customers = params.n - counter
    # a = findall(x -> ~x, assigned_customers)
    # if nb_unassigned_customers != size(a)[1]
    #     println("Customers non-assigned yet:", a)
    #     exit(0)
    # end
    # #Checker END

    # if nb_unassigned_customers > 0
    #     println("TODO assign unassigned customers to facilities")
    #     exit()
    # end
    solutionCost = calcSolutionCost(params,opened_facilities)
    return opened_facilities, solutionCost
end

function calcSolutionCost(params,solution)
    bestCost = -Inf
    for i = 1:size(solution)[1]
        facility = solution[i][1]
        
        for j = 2:size(solution[i])[1]
            customer = solution[i][j]
            if bestCost < params.D[facility,customer]
                bestCost = params.D[facility,customer]
            end
        end
    end
    return bestCost
end

#CUST-SWAP exchanges two customers assigned to different facilities
function custSwap(params,solution,solutionCost)
    bestCustSwapCost = solutionCost
    bestCustSwapSolution = deepcopy(solution)
    while true
        overline_D = computeOverlineD(params,solution)
        i,j, overline_dij, = getLargestOverlineDij(params,overline_D, solution)
        r = 0
        s = 0
        for k = 1:params.p
            if solution[k][1] == i
                for q = 2:size(solution[k])[1]
                    if solution[k][q] == j
                        s = q
                    end
                end
                r = k
                break
            end
        end
        # solution[r][s] is the costly customer
        improved = false
        for k = 1:params.p
            # we seek for a different facility
            if k != r
                # tempSolution[k][q] is the customer to swap. We do this for every customer for every facility, except for facility r
                for q = 2:size(solution[k])[1]
                    tempSolution = deepcopy(solution)
                    #swap
                    tempSolution[r][s], tempSolution[k][q] = tempSolution[k][q], tempSolution[r][s]
                    if checkFeasible(params,tempSolution)
                        tempCost = calcSolutionCost(params,tempSolution)
                        if tempCost < bestCustSwapCost
                            bestCustSwapCost = tempCost
                            bestCustSwapSolution = deepcopy(tempSolution)
                            improved = true
                        end
                    end
                end
            end
        end
        if ~improved
            break
        else
            solutionCost = bestCustSwapCost
            solution = deepcopy(bestCustSwapSolution)
        end
    end
    return bestCustSwapSolution, bestCustSwapCost
end

#RELOCATE attempts to move a customer from one facility to another
function relocate(params,solution,solutionCost)
    bestCustSwapCost = solutionCost
    bestCustSwapSolution = deepcopy(solution)
    while true
        overline_D = computeOverlineD(params,solution)
        i,j, overline_dij, = getLargestOverlineDij(params,overline_D, solution)
        r = 0
        s = 0
        for k = 1:params.p
            if solution[k][1] == i
                for q = 2:size(solution[k])[1]
                    if solution[k][q] == j
                        s = q
                    end
                end
                r = k
                break
            end
        end
        # solution[r][s] is the costly customer
        improved = false
        for k = 1:params.p
            # we seek for a different facility
            if k != r
                tempSolution = deepcopy(solution)
                customer = tempSolution[r][s]
                deleteat!(tempSolution[r],s)
                push!(tempSolution[k],customer)
                if checkFeasible(params,tempSolution)
                    tempCost = calcSolutionCost(params,tempSolution)
                    if tempCost < bestCustSwapCost
                        bestCustSwapCost = tempCost
                        bestCustSwapSolution = deepcopy(tempSolution)
                        improved = true
                    end
                end
            end
        end
        if ~improved
            break
        else
            solutionCost = bestCustSwapCost
            solution = deepcopy(bestCustSwapSolution)
        end
    end
    return bestCustSwapSolution, bestCustSwapCost
end

function checkFeasible(params,solution)
    for i = 1:params.p
        total_demand = 0
        facility = solution[i][1]
        for j = 2:size(solution[i])[1]
            customer = solution[i][j]
            total_demand = total_demand + params.demand[customer]
        end
        if total_demand > params.capacity[facility]
            return false
        end
    end

    customers_assigned = falses(params.n)
    for i = 1:params.p
        for j = 2:size(solution[i])[1]
            customer = solution[i][j]
            customers_assigned[customer] = true
        end
    end

    for i = 1:size(customers_assigned)[1]
        if ~customers_assigned[i]
            throw("There are non-assigned customers")   
            return false
        end
    end

    return true

end

#FAC-SWAP exchanges an open facility with a closed one.
function facSwap(params,solution,solutionCost)
    bestCustSwapCost = solutionCost
    bestCustSwapSolution = deepcopy(solution)
    while true
        overline_D = computeOverlineD(params,solution)
        i,j, overline_dij, = getLargestOverlineDij(params,overline_D, solution)
        r = 0
        s = 0
        for k = 1:params.p
            if solution[k][1] == i
                for q = 2:size(solution[k])[1]
                    if solution[k][q] == j
                        s = q
                    end
                end
                r = k
                break
            end
        end
        # solution[r][s] is the costly customer
        improved = false
        assigned_facilities = falses(params.n)

        for i = 1:params.p
            allocated_facility = solution[i][1]
            assigned_facilities[allocated_facility] = true
        end

        for i = 1:size(assigned_facilities)[1]
            if ~assigned_facilities[i] && solution[r][1] != i
                tempSolution = deepcopy(solution)
                tempSolution[r][1] = i
                if checkFeasible(params,tempSolution)
                    tempCost = calcSolutionCost(params,tempSolution)
                    if tempCost < bestCustSwapCost
                        bestCustSwapCost = tempCost
                        bestCustSwapSolution = deepcopy(tempSolution)
                        improved = true
                    end
                end
            end
        end
        if ~improved
            break
        else
            solutionCost = bestCustSwapCost
            solution = deepcopy(bestCustSwapSolution)
        end
    end
    return bestCustSwapSolution, bestCustSwapCost
end

function perturbation(params,solution,solutionCost)
    assigned_facilities = Any[]
    for i = 1:params.p
        push!(assigned_facilities,solution[i][1])
    end
    facility_out_index = rand(1:params.p)
    facility_out = assigned_facilities[facility_out_index]
    while true
        facility_in = rand(1:params.n)
        if findfirst(x-> x == facility_in,assigned_facilities) === nothing
            solution[facility_out_index][1] = facility_in
            #this will reach nonfeasible solution if capacities are heterogenous
            if checkFeasible(params,solution)
                break
            end
        end
    end
    return solution, solutionCost
end

function computeOverlineD(params,solution)
    overline_D = fill(-Inf,params.n,params.n)
    M = 0
    for i = 1:size(solution)[1]
        facility = solution[i][1]
        overline_Q = 0
        #Calculate overline_Q of facility i (excess in Q)
        for j = 2:size(solution[i])[1]
            customer = solution[i][j]
            overline_Q =  overline_Q + params.demand[customer]
        end
        if overline_Q > params.capacity[facility]
            overline_Q = overline_Q - params.capacity[facility]
        else
            overline_Q = 0
        end
        #Calculate overline_D
        for j = 2:size(solution[i])[1]
            customer = solution[i][j]
            overline_D[facility,customer] = params.D[facility,customer] + M * overline_Q
        end
    end
    return overline_D
end

function getLargestOverlineDij(params,overline_D, solution)
    best_i = 1
    best_j = 1
    best_value = -Inf
    for i = 1:params.p
        facility = solution[i][1]
        value, customer = findmax(overline_D[facility,:])
        if value > best_value
            best_i = facility
            best_j = customer
            best_value = value
        end
    end
    return best_i, best_j, best_value
end

function localSearch(params,solution,solutionCost)
    solution, solutionCost = custSwap(params,solution,solutionCost)
    solution, solutionCost = relocate(params,solution,solutionCost)
    solution, solutionCost = facSwap(params,solution,solutionCost)
    return solution, solutionCost
end

function ILS(params)
    
    bestSolution, bestCost = constructSolution(params)
    bestSolution, bestCost = localSearch(params,bestSolution,bestCost)

    for i = 1:300
        solution, solutionCost = perturbation(params,bestSolution,bestCost)
        solution, solutionCost = localSearch(params,solution,solutionCost)
        if solutionCost < bestCost
            bestCost = solutionCost
            bestSolution = deepcopy(solution)
        end
    end 
    
    return bestSolution, bestCost 
end