@inline function (poc::TwoCompartementParticulateOrganicMatter)(::Val{:PSi}, bgc,
                                                                x, y, z, t,
                                                                P, D, Z, M, 
                                                                PChl, DChl, PFe, DFe, DSi,
                                                                DOC, POC, GOC, 
                                                                SFe, BFe, PSi, 
                                                                NO₃, NH₄, PO₄, Fe, Si, 
                                                                CaCO₃, DIC, Alk, 
                                                                O₂, T, S,
                                                                zₘₓₗ, zₑᵤ, Si′, Ω, κ, mixed_layer_PAR, wPOC, wGOC, PAR, PAR₁, PAR₂, PAR₃)
    # diatom grazing
    gZ = diatom_grazing(bgc.microzooplankton, P, D, Z, POC, T)
    gM = diatom_grazing(bgc.mesozooplankton, P, D, Z, POC, T)

    grazing = (gZ * Z + gM * M) * DSi / (D + eps(0.0))

    # diatom mortality
    diatom_linear_mortality, diatom_quadratic_mortality = mortality(bgc.diatoms, bgc, z, D, DChl, DFe, NO₃, NH₄, PO₄, Fe, Si, Si′, zₘₓₗ)

    diatom_mortality = (diatom_linear_mortality + diatom_quadratic_mortality) * DSi / (D + eps(0.0))

    # dissolution
    dissolution = particulate_silicate_dissolution(poc, z, PSi, Si, T, zₘₓₗ, zₑᵤ, wGOC)

    return grazing + diatom_mortality - dissolution
end

@inline function particulate_silicate_dissolution(poc, z, PSi, Si, T, zₘₓₗ, zₑᵤ, wGOC)
    λₗ = poc.fast_dissolution_rate_of_silicate
    λᵣ = poc.slow_dissolution_rate_of_silicate

    χ = particulate_silicate_liable_fraction(poc, z, zₘₓₗ, zₑᵤ, wGOC)

    λ₀ = χ * λₗ + (1 - χ) * λᵣ

    equilibrium_silicate = 10^(6.44 - 968 / (T + 273.15))
    silicate_saturation  = (equilibrium_silicate - Si) / equilibrium_silicate

    λ = λ₀ * (0.225 * (1 + T/15) * silicate_saturation + 0.775 * ((1 + T/400)^4 * silicate_saturation)^9)

    return λ * PSi # assuming the Diss_Si is typo in Aumont 2015, consistent with Aumont 2005
end

@inline function particulate_silicate_liable_fraction(poc, z, zₘₓₗ, zₑᵤ, wGOC)
    χ₀ = poc.base_liable_silicate_fraction
    λₗ = poc.fast_dissolution_rate_of_silicate
    λᵣ = poc.slow_dissolution_rate_of_silicate

    zₘ = min(zₘₓₗ, zₑᵤ)

    return χ₀ * ifelse(z >= zₘ, 1, exp((λₗ - λᵣ) * (zₘ - z) / wGOC))
end
