"""
    Zooplankton

The PISCES zooplankton growth model where each class has preferences
for grazing on nanophytoplankton (P), diatoms (D), microzooplankton (Z),
and particulate organic matter (POC), and can flux feed on sinking 
particulates (POC and GOC).

This model assumes a fixed ratio for all other elements (i.e. N, P, Fe).
"""
@kwdef struct Zooplankton{FT}
    temperature_sensetivity :: FT = 1.079                  #
    maximum_grazing_rate :: FT                             # 1 / s

    preference_for_nanophytoplankton :: FT                 #
    preference_for_diatoms :: FT                           #
    preference_for_particulates :: FT                      #
    preference_for_zooplankton :: FT                       #

    food_threshold_concentration :: FT = 0.3               # mmol C / m³
    specific_food_thresehold_concentration :: FT = 0.001   # mmol C / m³

    grazing_half_saturation :: FT = 20.0                   # mmol C / m³

    maximum_flux_feeding_rate :: FT                        # m / (mmol C / m³)

    iron_ratio :: FT                                       # μmol Fe / mmol C

    minimum_growth_efficiency :: FT                        #
    non_assililated_fraction :: FT = 0.3                   #

    mortality_half_saturation :: FT = 0.2                  # mmol C / m³
    quadratic_mortality :: FT                              # 1 / (mmol C / m³) / s
    linear_mortality :: FT                                 # 1 / s

    dissolved_excretion_fraction :: FT = 0.6               #
    undissolved_calcite_fraction :: FT                     #
end

@inline zooplankton_concentration(::Val{:Z}, Z, M) = Z
@inline zooplankton_concentration(::Val{:M}, Z, M) = M

@inline function specific_grazing(zoo::Zooplankton, P, D, Z, POC, T)
    g₀   = zoo.maximum_grazing_rate
    b    = zoo.temperature_sensetivity
    pP   = zoo.preference_for_nanophytoplankton
    pD   = zoo.preference_for_diatoms
    pPOC = zoo.preference_for_particulates
    pZ   = zoo.preference_for_zooplankton
    J    = zoo.specific_food_thresehold_concentration
    K    = zoo.grazing_half_saturation

    food_threshold_concentration = zoo.food_threshold_concentration

    base_grazing_rate = g₀ * b ^ T

    food_availability = pP * P + pD * D + pPOC * POC + pZ * Z

    weighted_food_availability = pP * max(0, P - J) + pD * max(0, D - J) + pPOC * max(0, POC - J) + pZ * max(0, Z - J)

    concentration_limited_grazing = max(0, weighted_food_availability - min(weighted_food_availability / 2, food_threshold_concentration))

    total_specific_grazing = base_grazing_rate * concentration_limited_grazing / (K + food_availability) 

    phytoplankton_grazing = pP   * max(0, P - J)     * total_specific_grazing / (weighted_food_availability + eps(0.0))
    diatom_grazing        = pD   * max(0, D - J)     * total_specific_grazing / (weighted_food_availability + eps(0.0))
    particulate_grazing   = pPOC * max(0, POC - J)   * total_specific_grazing / (weighted_food_availability + eps(0.0))
    zooplankton_grazing   = pZ   * max(0, Z - J)     * total_specific_grazing / (weighted_food_availability + eps(0.0))

    return total_specific_grazing, phytoplankton_grazing, diatom_grazing, particulate_grazing, zooplankton_grazing
end

@inline function specific_flux_feeding(zoo::Zooplankton, POC, T, w)
    g₀ = zoo.maximum_flux_feeding_rate
    b  = zoo.temperature_sensetivity

    base_flux_feeding_rate = g₀ * b ^ T

    return base_flux_feeding_rate * w * POC
end

@inline function (zoo::Zooplankton)(val_name::Union{Val{:Z}, Val{:M}}, bgc,
                                    x, y, z, t,
                                    P, D, Z, M, 
                                    PChl, DChl, PFe, DFe, DSi, 
                                    DOC, POC, GOC, 
                                    SFe, BFe, PSi, 
                                    NO₃, NH₄, PO₄, Fe, Si, 
                                    CaCO₃, DIC, Alk, 
                                    O₂, T, S,
                                    zₘₓₗ, zₑᵤ, Si′, Ω, κ, mixed_layer_PAR, wPOC, wGOC, PAR, PAR₁, PAR₂, PAR₃)

    I = zooplankton_concentration(val_name, Z, M)

    # grazing
    total_specific_grazing, gP, gD, gPOC, gZ = specific_grazing(zoo, P, D, Z, POC, T)

    grazing = total_specific_grazing * I

    # flux feeding
    small_flux_feeding = specific_flux_feeding(zoo, POC, T, wPOC)
    large_flux_feeding = specific_flux_feeding(zoo, GOC, T, wGOC)

    flux_feeding = (small_flux_feeding + large_flux_feeding) * I

    # grazing mortality
    specific_grazing_mortality = zooplankton_grazing_mortality(val_name, bgc.mesozooplankton, P, D, Z, POC, T)

    grazing_mortality = specific_grazing_mortality * M

    # mortality
    total_mortality = mortality(zoo, bgc, I, O₂, T)

    growth_efficiency = grazing_growth_efficiency(zoo, P, D, PFe, DFe, POC, SFe, total_specific_grazing, gP, gD, gPOC, gZ)

    return growth_efficiency * (grazing + flux_feeding) - grazing_mortality - total_mortality
end

@inline function nanophytoplankton_grazing(zoo::Zooplankton, P, D, Z, POC, T) 
    _, g = specific_grazing(zoo, P, D, Z, POC, T)

    return g
end

@inline function diatom_grazing(zoo::Zooplankton, P, D, Z, POC, T) 
    _, _, g = specific_grazing(zoo, P, D, Z, POC, T)

    return g
end

@inline function particulate_grazing(zoo::Zooplankton, P, D, Z, POC, T) 
    _, _, _, g = specific_grazing(zoo, P, D, Z, POC, T)

    return g
end

@inline function zooplankton_grazing(zoo::Zooplankton, P, D, Z, POC, T) 
    _, _, _, _, g = specific_grazing(zoo, P, D, Z, POC, T)

    return g
end

@inline zooplankton_grazing_mortality(val_name, zoo, P, D, Z, POC, T) = 0
@inline zooplankton_grazing_mortality(::Val{:Z}, zoo, P, D, Z, POC, T) = zooplankton_grazing(zoo, P, D, Z, POC, T)

@inline function dissolved_upper_trophic_respiration_product(zoo, M, T)
    γ = zoo.dissolved_excretion_fraction

    R = upper_trophic_respiration_product(zoo, M, T)

    return (1 - γ) * R
end

@inline function inorganic_upper_trophic_respiration_product(zoo, M, T)
    γ = zoo.dissolved_excretion_fraction

    R = upper_trophic_respiration_product(zoo, M, T)

    return γ * R
end

@inline function upper_trophic_waste(zoo, M, T)
    e₀ = zoo.minimum_growth_efficiency
    b  = zoo.temperature_sensetivity
    m₀ = zoo.quadratic_mortality

    temperature_factor = b^T

    return 1 / (1 - e₀) * m₀ * temperature_factor * M^2
end

@inline upper_trophic_respiration_product(zoo, M, T) = 
    (1 - zoo.minimum_growth_efficiency - zoo.non_assililated_fraction) * upper_trophic_waste(zoo, M, T)

@inline upper_trophic_fecal_product(zoo, M, T) =
    zoo.non_assililated_fraction * upper_trophic_waste(zoo, M, T)

@inline function grazing_growth_efficiency(zoo, P, D, PFe, DFe, POC, SFe, g, gP, gD, gPOC, gZ)
    θFe = zoo.iron_ratio
    e₀  = zoo.minimum_growth_efficiency
    σ   = zoo.non_assililated_fraction

    iron_grazing = PFe / (P + eps(0.0)) * gP + DFe / (D + eps(0.0)) * gD + SFe / (POC + eps(0.0)) * gPOC + θFe * gZ

    iron_grazing_ratio = iron_grazing / (θFe * g + eps(0.0))

    food_quality = min(1, iron_grazing_ratio)

    return food_quality * min(e₀, (1 - σ) * iron_grazing_ratio)
end

@inline function specific_excretion(zoo, P, D, PFe, DFe, Z, POC, GOC, SFe, T, wPOC, wGOC)
    σ = zoo.non_assililated_fraction

    total_specific_grazing, gP, gD, gPOC, gZ = specific_grazing(zoo, P, D, Z, POC, T)

    small_flux_feeding = specific_flux_feeding(zoo, POC, T, wPOC)
    large_flux_feeding = specific_flux_feeding(zoo, GOC, T, wGOC)

    total_specific_flux_feeding = small_flux_feeding + large_flux_feeding

    e = grazing_growth_efficiency(zoo, P, D, PFe, DFe, POC, SFe, total_specific_grazing, gP, gD, gPOC, gZ)

    return (1 - e - σ) * (total_specific_grazing + total_specific_flux_feeding)
end

@inline specific_dissolved_grazing_waste(zoo, P, D, PFe, DFe, Z, POC, GOC, SFe, T, wPOC, wGOC) = 
    (1 - zoo.dissolved_excretion_fraction) * specific_excretion(zoo, P, D, PFe, DFe, Z, POC, GOC, SFe, T, wPOC, wGOC)

@inline specific_inorganic_grazing_waste(zoo, P, D, PFe, DFe, Z, POC, GOC, SFe, T, wPOC, wGOC) = 
    zoo.dissolved_excretion_fraction * specific_excretion(zoo, P, D, PFe, DFe, Z, POC, GOC, SFe, T, wPOC, wGOC)

@inline function specific_non_assimilated_waste(zoo, P, D, Z, POC, GOC, T, wPOC, wGOC)
    σ = zoo.non_assililated_fraction

    g, = specific_grazing(zoo, P, D, Z, POC, T)

    small_flux_feeding = specific_flux_feeding(zoo, POC, T, wPOC)
    large_flux_feeding = specific_flux_feeding(zoo, GOC, T, wGOC)
    
    return σ * (g + small_flux_feeding + large_flux_feeding)
end

@inline function specific_non_assimilated_iron_waste(zoo, bgc, P, D, PFe, DFe, Z, POC, GOC, SFe, BFe, T, wPOC, wGOC)
    _, gP, gD, gPOC, gZ = specific_grazing(zoo, P, D, Z, POC, T)

    θᶻ = bgc.microzooplankton.iron_ratio
    σ = zoo.non_assililated_fraction

    small_flux_feeding = specific_flux_feeding(zoo, POC, T, wPOC)
    large_flux_feeding = specific_flux_feeding(zoo, GOC, T, wGOC)

    return σ * (gP * PFe / (P + eps(0.0)) + gD * DFe / (D + eps(0.0)) + gPOC * SFe / (POC + eps(0.0)) + gZ * θᶻ
                + small_flux_feeding * SFe / (POC + eps(0.0)) + large_flux_feeding * BFe / (GOC + eps(0.0)))
end

@inline function specific_non_assimilated_iron(zoo, bgc, P, D, PFe, DFe, Z, POC, GOC, SFe, BFe, T, wPOC, wGOC)
    θ = zoo.iron_ratio
    θᶻ = bgc.microzooplankton.iron_ratio

    σ = zoo.non_assililated_fraction

    g, gP, gD, gPOC, gZ = specific_grazing(zoo, P, D, Z, POC, T)

    small_flux_feeding = specific_flux_feeding(zoo, POC, T, wPOC)
    large_flux_feeding = specific_flux_feeding(zoo, GOC, T, wGOC)

    total_iron_consumed = (gP * PFe / (P + eps(0.0)) + gD * DFe / (D + eps(0.0)) + gZ * θᶻ 
                           + (gPOC + small_flux_feeding) * SFe / (POC + eps(0.0)) 
                           + large_flux_feeding * BFe / (GOC + eps(0.0)))
                           

    grazing_iron_ratio = (1 - σ) * total_iron_consumed / (g + small_flux_feeding + large_flux_feeding + eps(0.0))

    growth_efficiency = grazing_growth_efficiency(zoo, P, D, PFe, DFe, POC, SFe, g, gP, gD, gPOC, gZ) * θ

    non_assimilated_iron_ratio = max(0, grazing_iron_ratio - growth_efficiency)

    return non_assimilated_iron_ratio * g
end

@inline function specific_calcite_grazing_loss(zoo, P, D, Z, POC, T)
    η = zoo.undissolved_calcite_fraction

    _, gP = specific_grazing(zoo, P, D, Z, POC, T)

    return η * gP
end

@inline function mortality(zoo::Zooplankton, bgc, I, O₂, T)
    b  = zoo.temperature_sensetivity
    m₀ = zoo.quadratic_mortality
    Kₘ = zoo.mortality_half_saturation
    r  = zoo.linear_mortality

    temperature_factor = b^T

    concentration_factor = I / (I + Kₘ)

    return temperature_factor * I * (m₀ * I + r * (concentration_factor + 3 * anoxia_factor(bgc, O₂)))
end

@inline function linear_mortality(zoo::Zooplankton, bgc, I, O₂, T)
    b  = zoo.temperature_sensetivity
    Kₘ = zoo.mortality_half_saturation
    r  = zoo.linear_mortality

    temperature_factor = b^T

    concentration_factor = I / (I + Kₘ)

    return temperature_factor * I * r * (concentration_factor + 3 * anoxia_factor(bgc, O₂))
end
