using JuMP, AmplNLWriter, Gurobi
using Statistics
using DataFrames
using DelimitedFiles
using CSV
include("../src/Params.jl")
include("../src/Subproblem.jl")
include("../src/SearchMethods.jl")
include("../src/ExactMethods.jl")

path = "../instances/S1"

method = "CPCP_D"

output_path = string("results/experiment-S1-", method, ".txt")

# Get a list of all files to be run
all_files = Array{String}([])

for folder in readdir(path)
    input_files = readdir(string(path, "/", folder))
    for file in input_files
        filepath = string(path, "/", folder, "/", file)
        push!(all_files, filepath)
    end
end

n_files = length(all_files)
println("Running for $n_files file instances")


df = DataFrame(instance_path = String[],
               dataset_name = String[],
               method = String[],
               LB = Float64[],
               UB = Float64[],
               status = String[],
               solvetime = Float64[],
               enable_ils = Bool[])

# Write column names of DataFrame to output file
df_columns = string(join(string.(names(df)), "\t"),"\n")
open(output_path, "a+") do io
    write(io, df_columns)
end


row = nothing
for file in all_files
    instance_path = file
    println("Instance path: $instance_path")

    seed = 0
    cpu_time = 600
    params = Params(instance_path, output_path, seed, cpu_time, false)
    println("Dataset: $(params.dataset_name)")

    obj_lb, obj_ub, status, solvetime, z, x, y = solveCPCP_D(params, verbose=false)

    row = (params.instance_path, params.dataset_name, method, obj_lb, obj_ub, string(status), solvetime, params.enable_ils)

    push!(df, row)

    # Write new line to output file
    CSV.write(output_path, df[end:end,:], delim="\t", append=true)
end
