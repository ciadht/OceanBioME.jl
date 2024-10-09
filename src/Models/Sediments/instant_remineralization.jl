"""
    struct InstantRemineralisation

Hold the parameters and fields the simplest benthic boundary layer where
organic carbon is assumed to remineralise instantly with some portion 
becoming N, and a fraction being permanently buried.

Burial efficiency from [RemineralisationFraction](@citet).
"""
struct InstantRemineralisation{FT, F, TE, B} <: FlatSediment
          burial_efficiency_constant1 :: FT
          burial_efficiency_constant2 :: FT
    burial_efficiency_half_saturation :: FT

                               fields :: F
                           tendencies :: TE
                       bottom_indices :: B

    InstantRemineralisation(burial_efficiency_constant1::FT,
                            burial_efficiency_constant2::FT,
                            burial_efficiency_half_saturation::FT,
                            fields::F,
                            tendencies::TE,
                            bottom_indices::B) where {FT, F, TE, B} =
        new{FT, F, TE, B}(burial_efficiency_constant1,
                          burial_efficiency_constant2,
                          burial_efficiency_half_saturation,
                          fields,
                          tendencies,
                          bottom_indices)
end

"""
    InstantRemineralisation(; grid,
        burial_efficiency_constant1::FT = 0.013,
        burial_efficiency_constant2::FT = 0.53,
        burial_efficiency_half_saturation::FT = 7)

Return a single-layer instant remineralisaiton model for NPZD bgc models.

Example
=======

```@example
using OceanBioME, Oceananigans, OceanBioME.Sediments

grid = RectilinearGrid(size=(3, 3, 30), extent=(10, 10, 200))

sediment_model = InstantRemineralisation(; grid)
```
"""
function InstantRemineralisation(; grid,
            burial_efficiency_constant1 = 0.013,
            burial_efficiency_constant2 = 0.53,
            burial_efficiency_half_saturation = 7.0)

    @warn "Sediment models are an experimental feature and have not yet been validated"

    tracer_names = (:N_storage, )

    # add field slicing back ( indices = (:, :, 1)) when output writer can cope
    fields = NamedTuple{tracer_names}(Tuple(CenterField(grid) for tracer in tracer_names))
    tendencies = (Gⁿ = NamedTuple{tracer_names}(Tuple(CenterField(grid) for tracer in tracer_names)),
                  G⁻ = NamedTuple{tracer_names}(Tuple(CenterField(grid) for tracer in tracer_names)))

    bottom_indices = on_architecture(architecture(grid), calculate_bottom_indices(grid))

    return InstantRemineralisation(burial_efficiency_constant1,
                                   burial_efficiency_constant2,
                                   burial_efficiency_half_saturation,
                                   fields,
                                   tendencies,
                                   bottom_indices)
end

adapt_structure(to, sediment::InstantRemineralisation) = 
    InstantRemineralisation(adapt(to, sediment.burial_efficiency_constant1),
                            adapt(to, sediment.burial_efficiency_constant2),
                            adapt(to, sediment.burial_efficiency_half_saturation),
                            adapt(to, sediment.fields),
                            nothing,
                            adapt(to, sediment.bottom_indices))
                  
sediment_tracers(::InstantRemineralisation) = (:N_storage, )
sediment_fields(model::InstantRemineralisation) = (N_storage = model.fields.N_storage, )

@inline required_tracers(::InstantRemineralisation, bgc, tracers) = tracers[(sinking_tracers(bgc)..., remineralisation_receiver(bgc))]
@inline required_tendencies(::InstantRemineralisation, bgc, tracers) = tracers[remineralisation_receiver(bgc)]

@inline bottom_index_array(sediment::InstantRemineralisation) = sediment.bottom_indices

function _calculate_sediment_tendencies!(i, j, sediment::InstantRemineralisation, bgc, grid, advection, tracers, tendencies, sediment_tendencies, time)
    k = bottom_index(i, j, sediment)

    Δz = zspacing(i, j, k, grid, Center(), Center(), Center())

    flux = nitrogen_flux(i, j, k, grid, advection, bgc, tracers) * Δz

    burial_efficiency = sediment.burial_efficiency_constant1 + sediment.burial_efficiency_constant2 * ((flux * 6.56) / (7 + flux * 6.56)) ^ 2

    # sediment evolution
    @inbounds sediment_tendencies.N_storage[i, j, 1] = burial_efficiency * flux

    @inbounds tendencies[i, j, k] += flux * (1 - burial_efficiency) / Δz
end

summary(::InstantRemineralisation{FT}) where {FT} = string("Single-layer instant remineralisaiton ($FT)")
show(io::IO, model::InstantRemineralisation) = print(io, summary(model))