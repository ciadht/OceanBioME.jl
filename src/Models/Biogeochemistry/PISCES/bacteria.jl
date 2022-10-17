ΔO₂(O₂, O₂ᵐⁱⁿ¹, O₂ᵐⁱⁿ²) = min(1, max(0, 0.4*(O₂ᵐⁱⁿ¹ - O₂)/(O₂ᵐⁱⁿ² - O₂))) #eq 57

@inline function Bact(x, y, z, Z, M, zₘₐₓ)
    #The bacteria concentration paramterised in NEMOs source code is different from this (and the PISCES paper) but is as described in Aumount and Bopp 2006 supplimentary materials (which specifies the Bact_ref to be 1)
    #Do macroalgaes not contribute to the bacteria pool? So need to add some proxy from their biomass
    Zᵢⱼₖ = interpolate(Z, x, y, z)
    Mᵢⱼₖ = interpolate(M, x, y, z)

    return abs(z)<=zₘₐₓ ? min(0.7*(Zᵢⱼₖ + 2*Mᵢⱼₖ), 4) : Bact(x, y, -zₘₐₓ, Z, M, zₘₐₓ)*abs(zₘₐₓ/z)^0.683
end

@inline function Lₗᵢₘᴮᵃᶜᵗ(bFe, PO₄, NO₃, NH₄, K_Feᴮᵃᶜᵗ, Kₚₒ₄ᴮᵃᶜᵗ, K_NO₃, K_NH₄)
    L_Feᴮᵃᶜᵗ = L_mondo(bFe, K_Feᴮᵃᶜᵗ)
    Lₚₒ₄ᴮᵃᶜᵗ = L_mondo(PO₄, Kₚₒ₄ᴮᵃᶜᵗ)
    L_NO₃ᴮᵃᶜᵗ = L_NO₃(NO₃, NH₄, K_NO₃, K_NH₄)
    Lₙᴮᵃᶜᵗ = L_NO₃ᴮᵃᶜᵗ + L_NH₄(NO₃, NH₄, K_NO₃, K_NH₄) 
    return min(Lₙᴮᵃᶜᵗ, Lₚₒ₄ᴮᵃᶜᵗ, L_Feᴮᵃᶜᵗ)#eq 34c, assuming typo of Lₙₕ₄ vs Lₙ because why else is it defined?
end