
#Calcium carbonate is assumed only to exist in the form of calcite.

#This document contains functions for:
    #R_CaCO₃ (eq77)
    #production_of_sinking_calcite (eq76)
    #Forcing for CaCO₃ (eq75)

#A type of phytoplankton (coccolithophores) have shells made from calcium carbonate. Either through mortality or grazing, this may be routed to production of sinking calcite.

#Dissolution rate of calcite
@inline function dissolution_of_calcite(CaCO₃, bgc, Ω) 
    #Calcite can break down into DIC. This describes the dissolution rate.
    λ_CaCO₃ = bgc.dissolution_rate_of_calcite
    nca = bgc.exponent_in_the_dissolution_rate_of_calcite
    ΔCO₃²⁻ = max(0, 1 - Ω)
    return λ_CaCO₃*(ΔCO₃²⁻)^nca #79
end

#The rain ratio is a ratio of coccolithophores calcite to particles of organic carbon. Increases proportional to coccolithophores, and parametrised based on simple assumptions on coccolithophores growth.
@inline function rain_ratio(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, Fe, T, PAR, zₘₓₗ, bgc) 
    r_CaCO₃ = bgc.rain_ratio_parameter
    Kₙₕ₄ᴾᵐⁱⁿ = bgc.min_half_saturation_const_for_ammonium.P
    Sᵣₐₜᴾ = bgc.size_ratio_of_phytoplankton.P
    Pₘₐₓ = bgc.threshold_concentration_for_size_dependency.P
    P₁ =  I₁(P, Pₘₐₓ)
    P₂ = I₂(P, Pₘₐₓ)
    Lₙᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[5]
    Kₙₕ₄ᴾ = nutrient_half_saturation_const(Kₙₕ₄ᴾᵐⁱⁿ, P₁, P₂, Sᵣₐₜᴾ)
    Lₗᵢₘᶜᵃᶜᵒ³ = min(Lₙᴾ, concentration_limitation(Fe, 6e-11), concentration_limitation(PO₄, Kₙₕ₄ᴾ))
    return (r_CaCO₃*Lₗᵢₘᶜᵃᶜᵒ³*T*max(1, P/2)*max(0, PAR - 1)*30*(1 + exp((-(T-10)^2)/25))*min(1, 50/(abs(zₘₓₗ) + eps(0.0)))/((0.1 + T)*(4 + PAR)*(30 + PAR))) #eq77
end

#Defined the production of sinking calcite. This is calculated as a ratio to carbon. 
#Coccolithophores shells can be routed to sinking particles through mortality and as a proportion of grazed shells. The rain ratio then gives conversion to sinking calcite from carbon.
@inline function production_of_sinking_calcite(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, Fe, D, Z, M, POC, T, PAR, zₘₓₗ, z, bgc) 
    mᴾ = bgc.phytoplankton_mortality_rate.P
    Kₘ = bgc.half_saturation_const_for_mortality
    wᴾ = bgc.min_quadratic_mortality_of_phytoplankton
    ηᶻ = bgc.fraction_of_calcite_not_dissolving_in_guts.Z
    ηᴹ = bgc.fraction_of_calcite_not_dissolving_in_guts.M
    τ₀ = bgc.background_shear
    τₘₓₗ = bgc.mixed_layer_shear

    τ₀ = bgc.background_shear
    τₘₓₗ = bgc.mixed_layer_shear

    sh = shear(z, zₘₓₗ, τ₀, τₘₓₗ)

    return rain_ratio(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, Fe, T, PAR, zₘₓₗ, bgc)*(ηᶻ*grazing_Z(P, D, POC, T, bgc)[2]*Z+ηᴹ*grazing_M(P, D, Z, POC, T, bgc)[2]*M + 0.5*(mᴾ*concentration_limitation(P, Kₘ)*P + sh*wᴾ*P^2)) #eq76
end



#Forcing for calcite
@inline function (bgc::PISCES)(::Val{:CaCO₃}, x, y, z, t, P, D, Z, M, Pᶜʰˡ, Dᶜʰˡ, Pᶠᵉ, Dᶠᵉ, Dˢⁱ, DOC, POC, GOC, SFe, BFe, PSi, NO₃, NH₄, PO₄, Fe, Si, CaCO₃, DIC, Alk, O₂, T, zₘₓₗ, zₑᵤ, Si̅, D_dust, Ω, κ, PAR, PAR₁, PAR₂, PAR₃)

    return (production_of_sinking_calcite(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, Fe, D, Z, M, POC, T, PAR, zₘₓₗ, z, bgc) 
            - dissolution_of_calcite(CaCO₃, bgc, Ω)*CaCO₃) #eq75, partial derivative omitted as sinking is accounted for in other parts of model
end