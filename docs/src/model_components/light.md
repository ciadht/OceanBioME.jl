# [Light attenuation models](@id light)

Nearly all BGC models require some model of the attenuation of PAR through the water. Usually this depends on the concentration of chlorophyll in the water (in phytoplankton), and may depend on the concentration of coloured dissolved organic matter or particulates.

We have two models implemented, a two band model by [Karleskind2011](@citet), and a more generic "multi band" model which can have the PAR split into arbitary many wavelength bands, but default to the widely used three band model by [Morel1988](@citet). As the light level is diagnostic of the phytoplankton concentration these models are implemented with the light level as various auxiliary fields which are updated within the biogeochemical model.

Models requiring light attenuation models will set these up automatically, for example [LOBSTER](@ref LOBSTER) sets `light_attenuation_model = TwoBandPhotosyntheticallyActiveRadiation()`. You may choose others. Additionally, you can pass the surface PAR as a function of horizontal position and time. The default for LOBSTER is `(x, y, t) -> 100*max(0.0, cos(t*π/(12hours)))`.

## The multi band model
The surface intensity is split into multiple bands (usually with equal weight, but users may specify custom weights), and the attenuation of each band (i) is computed from the radiative transfer equation:
```math
\frac{\partial PAR^i}{\partial z} = PAR\^i (k^w(i) + \chi(i)Chl^{e(i)}),
```
where ``Chl`` is the concentration of chlorophyll, ``k^w(i)`` is the band specific water attenuation coefficient, ``\chi(i)`` the chlorophyll attenuation coefficient, and ``e(i)`` the chlorophyll exponent.

The water concentration of chlorophyll is returned by a function `chlorophyll` with arguments `biogeochemistry` and `model`. For the `LOBSTER` model this returns a constant ratio of the phytoplankton concentration, but may be different for other models.

## The two band model
Light attenuation is calculated by integrating attenuation (from the surface). The ``PAR`` is considered as two components attenuated at different rates. At depth $z$ the total $PAR$ is given by:

```math
PAR = \frac{PAR_0}{2} \left[\exp\left(k_rz + \chi_r\int_{z=0}^z Chl_r dz\right) + \exp\left(k_bz + \chi_b\int_{z=0}^z Chl_b dz\right)\right],
```

where ``PAR_0`` is the surface value, ``k_r`` and ``k_b`` are the red and blue attenuation coefficients of water, ``\chi_r`` and ``\chi_b`` are the red and blue chlorophyll attenuation coefficients, and ``Chl_r`` and ``Chl_b`` are the red and blue chlorophyll pigment concentrations. The chlorophyll pigment concentration is derived from the phytoplankton concentration where it is assumed that the pigment concentration is given by:

```math
Chl = PR_{Chl:P},
```

where the ratio is constant and found in [Parameters](@ref parameters). The red and blue pigment concentrations are then found as ``Chl_r = \left(\frac{Chl}{r_\text{pig}}\right)^{e_r}`` and ``Chl_b = \left(\frac{Chl}{r_\text{pig}}\right)^{e_b}``. 

### Parameter variable names

| Symbol           | Variable name                     | Units                             |
|------------------|-----------------------------------|-----------------------------------|
| ``k_r``          | `water_red_attenuation`           | 1 / m                             |
| ``k_b``          | `water_blue_attenuation`          | 1 / m                             |
| ``\chi_r``       | `chlorophyll_red_attenuation`     | 1 / m / (mg Chl / m³) ``^ {e_r}`` |
| ``\chi_b``       | `chlorophyll_blue_attenuation`    | 1 / m / (mg Chl / m³) ``^ {e_b}`` |
| ``e_r``          | `chlorophyll_red_exponent`        | -                                 |
| ``e_b``          | `chlorophyll_blue_exponent`       | -                                 |
| ``r_\text{pig}`` | `pigment_ratio`                   | -                                 |
| ``R_{Chl:P}``    | `phytoplankton_chlorophyll_ratio` | mg Chl / mmol N                   |