using Hungarian

function compute_moment_of_inertia(b,h)
    # input: b,h in meter
    # return: I in cm^4
    return (b*h^3/12)*1e8
end

function compute_strength_capacity(b,h,Fy)
    # input: b,h in meter;
    #        Fy in kN/cm^2: allowable stress
    # return: Fmax in kN
    return b*h*1e4*Fy
end

function compute_buckling_capacity(b,h,L,E)
    # input: b,h,L in meter, E in kN/cm^2
    # return: buckling capacity R in kN
    I = compute_moment_of_inertia(b,h)
    return (1.0/3)*π^2*E*I/L^2*1e-4
end
    
######################################

function hungarian_upcycling_assignment(demand_lengths::AbstractVector, supply_lengths::AbstractVector,
    demand_loads::AbstractVector, supply_cross_sec_xs::AbstractVector, supply_cross_sec_ys::AbstractVector,
    allowable_stress::Real, elastic_modulus::Real, penalty::Real)
    demand_num = length(demand_lengths)
    supply_num = length(supply_lengths)

    if demand_num > supply_num ||
       length(demand_loads) != demand_num ||
       length(supply_cross_sec_xs) != supply_num ||
       length(supply_cross_sec_ys) != supply_num
       return nothing, nothing, nothing
    end

    cost_matrix = zeros(Float64, demand_num, supply_num)
    for i in 1:demand_num, j in 1:supply_num
        Li = demand_lengths[i]
        Lj = supply_lengths[j]
        if Li > Lj
            # ! length constraint violated
            cost_matrix[i,j] = penalty
        else
            demand_load = demand_loads[i]
            b = max(supply_cross_sec_xs[j], supply_cross_sec_ys[j])
            h = min(supply_cross_sec_xs[j], supply_cross_sec_ys[j])
            tensile_capacity = compute_strength_capacity(b,h,allowable_stress)
            capacity = 0.0
            if demand_load >= 0
                # tensile demand
                capacity = tensile_capacity
            else
                # compressive demand
                L = min(Li,Lj) # in meter
                buckling_capacity = compute_buckling_capacity(b,h,L,elastic_modulus)
                compressive_capacity = min(buckling_capacity, tensile_capacity)
                capacity = min(tensile_capacity, compressive_capacity)
            end
            if abs(demand_load) > capacity
                # capacity constraint violated
                cost_matrix[i,j] = penalty
            else
                # euclidean distance
                cost_matrix[i,j] = sqrt((Li-Lj)^2+(abs(capacity)-abs(demand_load))^2)
            end
        end
    end
    assignment, cost_star = hungarian(cost_matrix)
    material_coverage = sum(demand_lengths .* supply_cross_sec_xs[assignment] .* supply_cross_sec_ys[assignment]) / sum(supply_lengths .* supply_cross_sec_xs .* supply_cross_sec_ys)
    return assignment, cost_star, material_coverage
end