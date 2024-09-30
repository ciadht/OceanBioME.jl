@inline function (poc::TwoCompartementParticulateOrganicMatter)(::Val{:SFe}, bgc,
                                                                x, y, z, t,
                                                                P, D, Z, M, 
                                                                PChl, DChl, PFe, DFe, DSi,
                                                                DOC, POC, GOC, 
                                                                SFe, BFe, PSi, 
                                                                NO₃, NH₄, PO₄, Fe, Si, 
                                                                CaCO₃, DIC, Alk, 
                                                                O₂, T, S,
                                                                zₘₓₗ, zₑᵤ, Si′, Ω, κ, mixed_layer_PAR, wPOC, wGOC, PAR, PAR₁, PAR₂, PAR₃)

    grazing_waste = specific_non_assimilated_iron_waste(bgc.microzooplankton, bgc, P, D, PFe, DFe, Z, POC, GOC, SFe, BFe, T, wPOC, wGOC) * Z

    # mortality terms
    R_CaCO₃ = rain_ratio(bgc.calcite, bgc, P, PChl, PFe, NO₃, NH₄, PO₄, Fe, Si, Si′, T, zₘₓₗ, PAR)

    nanophytoplankton_linear_mortality, nanophytoplankton_quadratic_mortality = mortality(bgc.nanophytoplankton, bgc, z, P, PChl, PFe, NO₃, NH₄, PO₄, Fe, Si, Si′, zₘₓₗ)

    nanophytoplankton_mortality = (1 - 0.5 * R_CaCO₃) * (nanophytoplankton_linear_mortality + nanophytoplankton_quadratic_mortality) * PFe / (P + eps(0.0))

    diatom_linear_mortality, = mortality(bgc.diatoms, bgc, z, D, DChl, DFe, NO₃, NH₄, PO₄, Fe, Si, Si′, zₘₓₗ)

    diatom_mortality = 0.5 * diatom_linear_mortality * DFe / (D + eps(0.0))

    microzooplankton_mortality = mortality(bgc.microzooplankton, bgc, Z, O₂, T) * bgc.microzooplankton.iron_ratio

    # degredation
    λ = specific_degredation_rate(poc, bgc, O₂, T)

    large_particle_degredation = λ * BFe
    degredation = λ * SFe

    # grazing
    microzooplankton_grazing = particulate_grazing(bgc.microzooplankton, P, D, Z, POC, T) * Z
    mesozooplankton_grazing  = particulate_grazing(bgc.mesozooplankton, P, D, Z, POC, T) * M

    small_flux_feeding = specific_flux_feeding(bgc.mesozooplankton, POC, T, wPOC) * M

    grazing = (microzooplankton_grazing + mesozooplankton_grazing + small_flux_feeding) * SFe / (POC + eps(0.0))

    # aggregation
    
    aggregation_to_large = aggregation(poc, bgc, z, POC, GOC, zₘₓₗ)

    total_aggregation = aggregation_to_large * SFe / (POC + eps(0.0))

    # scavenging
    λFe = iron_scavenging_rate(poc, POC, GOC, CaCO₃, PSi)
    
    Fe′ = free_iron(bgc.iron, Fe, DOC, T)

    scavenging = λFe * POC * Fe′

    # bacterial uptake of dissolved iron
    κ = poc.small_fraction_of_bacterially_consumed_iron

    BactFe = bacterial_iron_uptake(bgc.dissolved_organic_matter, z, Z, M, DOC, NO₃, NH₄, PO₄, Fe, T, zₘₓₗ, zₑᵤ)

    bacterial_assimilation = κ * BactFe

    # colloidal iron aggregation
    _, colloidal_aggregation = aggregation_of_colloidal_iron(bgc.iron, bgc.dissolved_organic_matter, bgc, z, DOC, POC, GOC, Fe, T, zₘₓₗ)

    return (grazing_waste 
            + nanophytoplankton_mortality + diatom_mortality + microzooplankton_mortality 
            + large_particle_degredation + scavenging + bacterial_assimilation + colloidal_aggregation
            - total_aggregation 
            - grazing - degredation)
end


@inline function (poc::TwoCompartementParticulateOrganicMatter)(::Val{:BFe}, bgc,
                                                                x, y, z, t,
                                                                P, D, Z, M, 
                                                                PChl, DChl, PFe, DFe, DSi,
                                                                DOC, POC, GOC, 
                                                                SFe, BFe, PSi, 
                                                                NO₃, NH₄, PO₄, Fe, Si, 
                                                                CaCO₃, DIC, Alk, 
                                                                O₂, T, S,
                                                                zₘₓₗ, zₑᵤ, Si′, Ω, κ, mixed_layer_PAR, wPOC, wGOC, PAR, PAR₁, PAR₂, PAR₃)

    grazing_waste = specific_non_assimilated_iron_waste(bgc.mesozooplankton, bgc, P, D, PFe, DFe, Z, POC, GOC, SFe, BFe, T, wPOC, wGOC) * M

    # mortality terms
    R_CaCO₃ = rain_ratio(bgc.calcite, bgc, P, PChl, PFe, NO₃, NH₄, PO₄, Fe, Si, Si′, T, zₘₓₗ, PAR)

    nanophytoplankton_linear_mortality, nanophytoplankton_quadratic_mortality = mortality(bgc.nanophytoplankton, bgc, z, P, PChl, PFe, NO₃, NH₄, PO₄, Fe, Si, Si′, zₘₓₗ)

    nanophytoplankton_mortality = 0.5 * R_CaCO₃ * (nanophytoplankton_linear_mortality + nanophytoplankton_quadratic_mortality) * PFe / (P + eps(0.0))

    diatom_linear_mortality, diatom_quadratic_mortality = mortality(bgc.diatoms, bgc, z, D, DChl, DFe, NO₃, NH₄, PO₄, Fe, Si, Si′, zₘₓₗ)

    diatom_mortality = (0.5 * diatom_linear_mortality + diatom_quadratic_mortality) * DFe / (D + eps(0.0))

    mesozooplankton_mortality = linear_mortality(bgc.mesozooplankton, bgc, M, O₂, T) * bgc.mesozooplankton.iron_ratio

    # degredation
    λ = specific_degredation_rate(poc, bgc, O₂, T)

    degredation = λ * BFe

    # grazing
    grazing = specific_flux_feeding(bgc.mesozooplankton, GOC, T,wGOC) * M * BFe / (GOC + eps(0.0))

    # aggregation    
    small_particle_aggregation = aggregation(poc, bgc, z, POC, GOC, zₘₓₗ) 

    total_aggregation = small_particle_aggregation * SFe / (POC + eps(0.0))

    # fecal pelet prodiction
    fecal_pelet_production = upper_trophic_fecal_product(bgc.mesozooplankton, M, T) * bgc.mesozooplankton.iron_ratio

    # scavenging
    λFe = iron_scavenging_rate(poc, POC, GOC, CaCO₃, PSi)
    
    Fe′ = free_iron(bgc.iron, Fe, DOC, T)

    scavenging = λFe * GOC * Fe′

    # bacterial uptake of dissolved iron
    κ = poc.large_fraction_of_bacterially_consumed_iron

    BactFe = bacterial_iron_uptake(bgc.dissolved_organic_matter, z, Z, M, DOC, NO₃, NH₄, PO₄, Fe, T, zₘₓₗ, zₑᵤ)

    bacterial_assimilation = κ * BactFe

    # colloidal iron aggregation
    _, _, colloidal_aggregation = aggregation_of_colloidal_iron(bgc.iron, bgc.dissolved_organic_matter, bgc, z, DOC, POC, GOC, Fe, T, zₘₓₗ)

    return (grazing_waste
            + nanophytoplankton_mortality + diatom_mortality + mesozooplankton_mortality 
            + total_aggregation + fecal_pelet_production + scavenging + bacterial_assimilation + colloidal_aggregation
            - grazing - degredation)
end

@inline function iron_scavenging_rate(pom, POC, GOC, CaCO₃, PSi)
    λ₀ = pom.minimum_iron_scavenging_rate
    λ₁ = pom.load_specific_iron_scavenging_rate

    return λ₀ + λ₁ * (POC + GOC + CaCO₃ + PSi)
end