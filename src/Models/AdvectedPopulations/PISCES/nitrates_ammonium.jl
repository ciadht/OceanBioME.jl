
#We model the following nutrients in PISCES, NO₃, NH₄, PO₄, Fe, Si, CaCO₃, O₂.
#What is not assimilated from grazing and not routed to particles, is shared between dissolved organic and inorganic matter.
#The first 5 terms of the NH₄, PO₄, DIC equations are the same up to a redfield ratio. These terms describe how carbon is routed to inorganic matter. Contribution to each compartment then set by redfield ratio.

#This document contains functions for:
    #uptake_rate_nitrate,  uptake_rate_ammonium (eq8)
    #oxygen_condition (eq57)
    #Nitrif (eq56)
    #N_fix (eq58)
    #Forcing for NO₃ and NH₄ (eqs54, 55)

#Processes in the nitrogen cycle are represented through forcing equations for NO₃ and NH₄.
#Atmospheric nitrogen fixed as NH₄. Nitrification converts ammonium to nitrates. 
#Remin and denit terms are added from the remineralisation of DOM. In anoxic conditions, denitrification processes can occur where nitrates can oxidise ammonia, this is seen in 4th term of eq54.

#Uptake rate of nitrate by phytoplankton
@inline function uptake_rate_nitrate_P(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, T,  zₘₓₗ, zₑᵤ, κ, L_day, PARᴾ, t_darkᴾ, Si̅, bgc) 
    αᴾ = bgc.initial_slope_of_PI_curve.P
    Lₗᵢₘᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[1]
    μᴾ = phytoplankton_growth_rate(P, Pᶜʰˡ, PARᴾ, L_day, T, αᴾ, Lₗᵢₘᴾ, zₘₓₗ, zₑᵤ, κ, t_darkᴾ, bgc) 
    Lₙₒ₃ᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[4]
    Lₙₕ₄ᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[3]
    return μᴾ * concentration_limitation(Lₙₒ₃ᴾ, Lₙₕ₄ᴾ) #eq8
end

#Uptake rate of ammonium by phytoplankton
@inline function uptake_rate_ammonium_P(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴾ, t_darkᴾ, Si̅, bgc)
    αᴾ = bgc.initial_slope_of_PI_curve.P
    Lₗᵢₘᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[1]
    μᴾ = phytoplankton_growth_rate(P, Pᶜʰˡ, PARᴾ, L_day, T, αᴾ, Lₗᵢₘᴾ, zₘₓₗ, zₑᵤ, κ, t_darkᴾ, bgc) 
    Lₙₒ₃ᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[4]
    Lₙₕ₄ᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[3]
    return μᴾ * concentration_limitation(Lₙₕ₄ᴾ, Lₙₒ₃ᴾ) #eq8
end

#Uptake rate of nitrate by diatoms
@inline function uptake_rate_nitrate_D(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴰ, t_darkᴰ, Si̅, bgc) 
    αᴰ = bgc.initial_slope_of_PI_curve.D
    Lₗᵢₘᴰ = D_nutrient_limitation(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, Si̅, bgc)[1]
    μᴰ =  phytoplankton_growth_rate(D, Dᶜʰˡ, PARᴰ, L_day, T, αᴰ, Lₗᵢₘᴰ, zₘₓₗ, zₑᵤ, κ, t_darkᴰ, bgc)
    Lₙₒ₃ᴰ = D_nutrient_limitation(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, Si̅, bgc)[4]
    Lₙₕ₄ᴰ = D_nutrient_limitation(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, Si̅, bgc)[3]
    return μᴰ * concentration_limitation(Lₙₒ₃ᴰ, Lₙₕ₄ᴰ) #eq8
end

#Uptake rate of ammonium by diatoms
@inline function uptake_rate_ammonium_D(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴰ, t_darkᴰ, Si̅, bgc)
    αᴰ = bgc.initial_slope_of_PI_curve.D
    Lₗᵢₘᴰ = D_nutrient_limitation(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, Si̅, bgc)[1]
    μᴰ =  phytoplankton_growth_rate(D, Dᶜʰˡ, PARᴰ, L_day, T, αᴰ, Lₗᵢₘᴰ, zₘₓₗ, zₑᵤ, κ, t_darkᴰ, bgc)
    Lₙₒ₃ᴰ = D_nutrient_limitation(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, Si̅, bgc)[4]
    Lₙₕ₄ᴰ = D_nutrient_limitation(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, Si̅, bgc)[3]
    return μᴰ * concentration_limitation(Lₙₕ₄ᴰ, Lₙₒ₃ᴰ) #eq8
end

#Represents the oxygen conditions of the water. Is 0 for oxic waters, 1 for anoxic waters.
@inline function oxygen_conditions(O₂, bgc)
    O₂ᵐⁱⁿ¹ = bgc.half_sat_const_for_denitrification1
    O₂ᵐⁱⁿ² = bgc.half_sat_const_for_denitrification2
    return min(1, max(0, 0.4*(O₂ᵐⁱⁿ¹ - O₂)/(O₂ᵐⁱⁿ²+O₂+eps(0.0)))) #eq57
end

#Nitrification converts ammonium to nitrates, dimensions molN/L
@inline nitrification(NH₄, O₂, λₙₕ₄, PAR, bgc) = λₙₕ₄*NH₄*(1-oxygen_conditions(O₂, bgc))/(1+PAR) #eq56a

#Forcing for NO₃
@inline function (bgc::PISCES)(::Val{:NO₃}, x, y, z, t, P, D, Z, M, Pᶜʰˡ, Dᶜʰˡ, Pᶠᵉ, Dᶠᵉ, Dˢⁱ, DOC, POC, GOC, SFe, BFe, PSi, NO₃, NH₄, PO₄, Fe, Si, CaCO₃, DIC, Alk, O₂, T, zₘₓₗ, zₑᵤ, Si̅, D_dust, Ω, κ, PAR, PAR₁, PAR₂, PAR₃) 
    #Parameters
    λₙₕ₄ =  bgc.max_nitrification_rate
    θᴺᶜ = bgc.NC_redfield_ratio
    Rₙₕ₄ = bgc.NC_stoichiometric_ratio_of_ANOTHERPLACEHOLDER
    Rₙₒ₃ = bgc.NC_stoichiometric_ratio_of_dentitrification

    #Uptake of nitrate by phytoplankton and diatoms
    φ = bgc.latitude
    φ = latitude(φ, y)


    L_day = day_length(φ, t)
    t_darkᴾ = bgc.mean_residence_time_of_phytoplankton_in_unlit_mixed_layer.P
    t_darkᴰ = bgc.mean_residence_time_of_phytoplankton_in_unlit_mixed_layer.D
    PARᴾ = P_PAR(PAR₁, PAR₂, PAR₃, bgc)
    PARᴰ = D_PAR(PAR₁, PAR₂, PAR₃, bgc)

    μₙₒ₃ᴾ = uptake_rate_nitrate_P(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴾ, t_darkᴾ, Si̅, bgc)
    μₙₒ₃ᴰ = uptake_rate_nitrate_D(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴰ, t_darkᴰ, Si̅, bgc)

    #Bacteria
    zₘₐₓ = max(abs(zₑᵤ), abs(zₘₓₗ)) #35a
    Bact = bacterial_biomass(zₘₐₓ, z, Z, M)

    bFe = Fe

    return (θᴺᶜ*(- μₙₒ₃ᴾ*P - μₙₒ₃ᴰ*D 
             - Rₙₒ₃*denitrification(NO₃, PO₄, NH₄, DOC, O₂, T, bFe, Bact, bgc)) 
             + nitrification(NH₄, O₂, λₙₕ₄, PAR, bgc) - Rₙₕ₄*λₙₕ₄*oxygen_conditions(O₂, bgc)*NH₄)

    #Changes made:
        #In paper some dimensions of terms did not agree. Relevant terms have been multiplied by a redfield ratio to return in molN/L.
end

#Nitrogen fixation fixes atmospheric nitrogen into inorganic form, NH₄

@inline function N_fixation(bFe, PO₄, T, P, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, PAR, bgc) # Returns in μmolN/L
    N_fixᵐ = bgc.max_rate_of_nitrogen_fixation
    K_Feᴰᶻ = bgc.Fe_half_saturation_constant_of_nitrogen_fixation
    Kₚₒ₄ᴾᵐⁱⁿ = bgc.min_half_saturation_const_for_phosphate.P
    E_fix = bgc.photosynthetic_parameter_of_nitrogen_fixation
    μ⁰ₘₐₓ = bgc.growth_rate_at_zero
    bₚ = bgc.temperature_sensitivity_of_growth
    μₚ = μ⁰ₘₐₓ*(bₚ^T)
    Lₙᴾ = P_nutrient_limitation(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, bgc)[5]
        
    Lₙᴰᶻ = ifelse(Lₙᴾ>=0.08, 0.01, 1 - Lₙᴾ) #eq 58

    return (N_fixᵐ*max(0,μₚ - 2.15)*Lₙᴰᶻ*min(concentration_limitation(bFe, K_Feᴰᶻ), concentration_limitation(PO₄, Kₚₒ₄ᴾᵐⁱⁿ))*(1 - exp((-PAR/E_fix)))) #eq 58b
end

#Forcing for NH₄, redfield conversion to model in molN/L.
@inline function (bgc::PISCES)(::Val{:NH₄}, x, y, z, t, P, D, Z, M, Pᶜʰˡ, Dᶜʰˡ, Pᶠᵉ, Dᶠᵉ, Dˢⁱ, DOC, POC, GOC, SFe, BFe, PSi, NO₃, NH₄, PO₄, Fe, Si, CaCO₃, DIC, Alk, O₂, T, zₘₓₗ, zₑᵤ, Si̅, D_dust, Ω, κ, PAR, PAR₁, PAR₂, PAR₃) 
    #Parameters
    γᶻ = bgc.excretion_as_DOM.Z
    σᶻ = bgc.non_assimilated_fraction.Z
    γᴹ = bgc.excretion_as_DOM.M
    σᴹ = bgc.non_assimilated_fraction.M
    λₙₕ₄ = bgc.max_nitrification_rate
    t_darkᴾ = bgc.mean_residence_time_of_phytoplankton_in_unlit_mixed_layer.P
    t_darkᴰ = bgc.mean_residence_time_of_phytoplankton_in_unlit_mixed_layer.D
    eₘₐₓᶻ = bgc.max_growth_efficiency_of_zooplankton.Z
    eₘₐₓᴹ = bgc.max_growth_efficiency_of_zooplankton.M
    θᴺᶜ = bgc.NC_redfield_ratio

    #Uptake rates of ammonium
    φ = bgc.latitude
    φ = latitude(φ, y)


    L_day = day_length(φ, t)
    t_darkᴾ = bgc.mean_residence_time_of_phytoplankton_in_unlit_mixed_layer.P
    t_darkᴰ = bgc.mean_residence_time_of_phytoplankton_in_unlit_mixed_layer.D
    PARᴾ = P_PAR(PAR₁, PAR₂, PAR₃, bgc)
    PARᴰ = D_PAR(PAR₁, PAR₂, PAR₃, bgc)

    μₙₕ₄ᴾ = uptake_rate_ammonium_P(P, PO₄, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴾ, t_darkᴾ, Si̅, bgc)
    μₙₕ₄ᴰ = uptake_rate_ammonium_D(D, PO₄, NO₃, NH₄, Si, Dᶜʰˡ, Dᶠᵉ, T, zₘₓₗ, zₑᵤ, κ, L_day, PARᴰ, t_darkᴰ, Si̅, bgc)
    
    #Grazing
    ∑gᶻ, gₚᶻ, g_Dᶻ, gₚₒᶻ = grazing_Z(P, D, POC, T, bgc) 
    ∑gᴹ, gₚᴹ, g_Dᴹ, gₚₒᴹ, g_Zᴹ  = grazing_M(P, D, Z, POC, T, bgc) 
    ∑g_FFᴹ = flux_feeding(z, zₑᵤ, zₘₓₗ, T, POC, GOC, bgc)[1]

    #Gross growth efficiency
    eᶻ = growth_efficiency(eₘₐₓᶻ, σᶻ, gₚᶻ, g_Dᶻ, gₚₒᶻ, 0, Pᶠᵉ, Dᶠᵉ, SFe, P, D, POC, bgc)
    eᴹ =  growth_efficiency(eₘₐₓᴹ, σᴹ, gₚᴹ, g_Dᴹ, gₚₒᴹ, g_Zᴹ,Pᶠᵉ, Dᶠᵉ, SFe, P, D, POC, bgc)

    #Bacteria
    zₘₐₓ = max(abs(zₑᵤ), abs(zₘₓₗ)) #35a
    Bact = bacterial_biomass(zₘₐₓ, z, Z, M)

    bFe = Fe 
   
    return (θᴺᶜ*(γᶻ*(1-eᶻ-σᶻ)*∑gᶻ*Z + γᴹ*(1-eᴹ-σᴹ)*(∑gᴹ + ∑g_FFᴹ)*M + γᴹ*upper_respiration(M, T, bgc) 
          + oxic_remineralization(O₂, NO₃, PO₄, NH₄, DOC, T, bFe, Bact, bgc) + denitrification(NO₃, PO₄, NH₄, DOC, O₂, T, bFe, Bact, bgc)
          - μₙₕ₄ᴾ*P - μₙₕ₄ᴰ*D) + N_fixation(bFe, PO₄, T, P, NO₃, NH₄, Pᶜʰˡ, Pᶠᵉ, PAR, bgc)
          - nitrification(NH₄, O₂, λₙₕ₄, PAR, bgc) - λₙₕ₄*oxygen_conditions(O₂, bgc)*NH₄) #eq55

    #Changes made:
        #In paper some dimensions of terms did not agree. Relevant terms have been multiplied by a redfield ratio to return in molN/L.
end
