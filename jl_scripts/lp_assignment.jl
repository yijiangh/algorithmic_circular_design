using JuMP
# using GLPK
# using Cbc
using Gurobi
using LinearAlgebra

function solve_lp_assignment_problem(costMat::AbstractMatrix; optimizer=Gurobi.Optimizer, verbose=false, binary_var=false)
    rowNum, colNum = size(costMat)
    # currently, the function `hungarian` automatically transposes `cost matrix` when there are more workers than jobs.
    costMatrix = rowNum ≤ colNum ? costMat : copy(transpose(costMat))

	# Preparing an optimization model
	m = Model(optimizer)
	# set_optimizer_attribute(m, "OutputFlag", verbose)
	if !verbose
		set_silent(m)
	end

	# https://nbviewer.jupyter.org/github/jump-dev/JuMPTutorials.jl/blob/master/notebook/modelling/network_flows.ipynb
	# Declaring variables
	if !binary_var
		@variable(m, 0 <= x[1:rowNum, 1:colNum] <= 1)
	else
		@variable(m, x[1:rowNum, 1:colNum], Bin)
	end

	# Setting the objective
	@objective(m, Min, dot(costMatrix, x))

	# Adding constraints
	@constraint(m, [i = 1:rowNum], sum(x[i, :]) == 1)
	if rowNum == colNum
		@constraint(m, [j = 1:colNum], sum(x[:, j]) == 1)
	else
		@constraint(m, [j = 1:colNum], sum(x[:, j]) <= 1)
	end

	#  the optimization problem
	optimize!(m)
	if termination_status(m) == MOI.OPTIMAL
	    x_opt = value.(x)
	    cost = objective_value(m)
	elseif termination_status(m) == MOI.TIME_LIMIT && has_values(m)
	    x_opt = value.(x)
	    cost = objective_value(m)
		println("The model terminates due to time limits.")
	else
	    error("The model was not solved correctly.")
	end

    assignment = zeros(Int, rowNum)
    for i = 1:rowNum
		for j =1:colNum
        	if x_opt[i, j] ≈ 1.0
        	    if rowNum ≤ colNum
        	        assignment[i] = j
        	    else
        	        assignment[j] = i
        	    end
				break
        	end
		end
    end
    return assignment, cost
end

function solve_upcycling_assignment(design_lengths::AbstractVector, inventory_lengths::AbstractVector,
		match_costs::AbstractMatrix, cutoff_costs::AbstractVector;
		optimizer=Gurobi.Optimizer, 
		binary_var=true, allow_cutoff=false, minimize_cutoff=true, verbose=false)
	@assert length(design_lengths) <= length(inventory_lengths) "We must have more inventory elements ($(length(inventory_lengths))) than design elements ($(length(design_lengths)))."
    rowNum, colNum = length(design_lengths), length(inventory_lengths)
	@assert (rowNum, colNum) == size(match_costs) && colNum == length(cutoff_costs)

	# Preparing an optimization model
	m = Model(optimizer)
	if !verbose
		set_silent(m)
	end

	# Declaring variables
	if !binary_var
		@variable(m, 0 <= x[1:rowNum, 1:colNum] <= 1)
		if allow_cutoff
			@variable(m, 0 <= y[1:colNum] <= 1)
		end
	else
		@variable(m, x[1:rowNum, 1:colNum], Bin)
		if allow_cutoff
			@variable(m, y[1:colNum], Bin)
		end
	end

	# Setting the objective, minimize wasted materials
	# @objective(m, Min, sum(x * inventory_lengths - design_lengths) + dot(cutoff_costs, y)) # + dot(match_costs, x)
	if allow_cutoff
		if minimize_cutoff
			@objective(m, Min, sum(y .* inventory_lengths - x' * design_lengths) + dot(cutoff_costs, y))
        else
			@objective(m, Min, dot(match_costs, x) + dot(cutoff_costs, y))
		end
	else
		# minimize cut-off waste
		@objective(m, Min, dot(match_costs, x))
		# equivalent to
		# @objective(m, Min, sum(x * inventory_lengths - design_lengths))
	end

	# * Adding constraints
	# For each member i , only one stock element j is reused
	@constraint(m, [i = 1:rowNum], sum(x[i, :]) == 1)
	if allow_cutoff
		# The use of stock element j \in R for one or more members is constrained by the available length
		@constraint(m, [j = 1:colNum], dot(x[:, j], design_lengths) <= y[j]*inventory_lengths[j])
	else
		# each stock element can only be used once
		@constraint(m, [j = 1:colNum], sum(x[:, j]) <= 1)
		# oversize constraint
		@constraint(m, x*inventory_lengths .>= design_lengths)
	end

	#  the optimization problem
	optimize!(m)
	if verbose
		solution_summary(m, verbose=true)
	end
	if termination_status(m) == MOI.OPTIMAL
		# 
	elseif termination_status(m) == MOI.TIME_LIMIT && has_values(m)
		println("The model terminates due to time limits.")
	else
	    error("The model was not solved correctly: $(termination_status(m))")
	end

	x_opt = value.(x)
	y_opt = allow_cutoff ? value.(y) : zeros(colNum)
	# cost = objective_value(m)
	# if allow_cutoff
	# 	cost -= dot(cutoff_costs, y_opt)
	# end
	# @show x_opt

    assignment = zeros(Int, rowNum)
    for i = 1:rowNum
		for j = 1:colNum
        	if abs(x_opt[i, j]-1.0) < 1e-4
        	# if x_opt[i, j] ≈ 1.0
        	    if rowNum ≤ colNum
        	        assignment[i] = j
					if !allow_cutoff
						y_opt[j] = 1
					end
        	    else
        	        assignment[j] = i
					if !allow_cutoff
						y_opt[i] = 1
					end
        	    end
				# break
        	end
		end
    end
	cutoff_waste = sum(y_opt .* inventory_lengths - x_opt' * design_lengths)
    return assignment, (x_opt, y_opt), cutoff_waste
end