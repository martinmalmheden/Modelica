within Modelica.Media.Air;
  package ReferenceAir
    "ReferenceAir: Detailed dry air model with a large operating range (130 ... 2000 K, 0 ... 2000 MPa) based on Helmholtz equations of state"
    extends Modelica.Icons.MaterialPropertiesPackage;
    import SI = Modelica.SIunits;

    constant Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants
      airConstants(
      each chemicalFormula="N2+O2+Ar",
      each structureFormula="N2+O2+Ar",
      each casRegistryNumber="1",
      each iupacName="air",
      each molarMass=0.02896546,
      each criticalTemperature=132.5306,
      each criticalPressure=3.786e6,
      each criticalMolarVolume=0.02896546/342.68,
      each triplePointTemperature=63.05 "from N2",
      each triplePointPressure=0.1253e5 "from N2",
      each normalBoilingPoint=78.903,
      each meltingPoint=0,
      each acentricFactor=0.0335,
      each dipoleMoment=0.0,
      each hasCriticalData=true,
      each hasFundamentalEquation=true,
      each hasAccurateViscosityData=true,
      each hasAcentricFactor=true);

  protected
    type MolarHeatCapacity = SI.MolarHeatCapacity (
        min=0,
        max=3.e5,
        nominal=3.e1,
        start=3.e1)
      "Type for molar heat capacity with medium specific attributes";

    type MolarDensity = Real (
        final quantity="MolarDensity",
        final unit="mol/m3",
        min=0);

    type IsothermalExpansionCoefficient = Real (
        min=0,
        max=1e8,
        unit="1");

  public
    package Air_ph
      "RealGasAir.Air_ph: Detailed dry air model (130 ... 2000 K) explicit in p and h"
      extends Modelica.Media.Air.ReferenceAir.Air_Base(
        ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.ph,

        final ph_explicit=true,
        final dT_explicit=false,
        final pT_explicit=false);

      annotation (Documentation(info="<html>
<h4>Usage</h4>
<p>
The package Air_ph can be used as any other medium model (see <a href=\"modelica://Modelica.Media.UsersGuide\">User's Guide of Media Library</a> for further information).
</p>
</html>"));
    end Air_ph;

    package Air_pT
      "RealGasAir.Air_pT: Detailed dry air model (130 ... 2000 K) explicit in p and T"
      extends Modelica.Media.Air.ReferenceAir.Air_Base(
        ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.pT,

        final ph_explicit=false,
        final dT_explicit=false,
        final pT_explicit=true);

      annotation (Documentation(info="<html>
<h4>Usage</h4>
<p>
The package Air_pT can be used as any other medium model (see <a href=\"modelica://Modelica.Media.UsersGuide\">User's Guide of Media Library</a> for further information).
</p>
</html>"));
    end Air_pT;

  public
    package Air_dT
      "RealGasAir.Air_dT: Detailed dry air model (130 ... 2000 K) explicit in d and T"
      extends Modelica.Media.Air.ReferenceAir.Air_Base(
        ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.dTX,

        final ph_explicit=false,
        final dT_explicit=true,
        final pT_explicit=false);

      annotation (Documentation(info="<html>
<h4>Usage</h4>
<p>
The package Air_dT can be used as any other medium model (see <a href=\"modelica://Modelica.Media.UsersGuide\">User's Guide of Media Library</a> for further information).
</p>
</html>"));
    end Air_dT;

  public
    partial package Air_Base
      "Properties of dry air calculated using the equation of state by Lemmon et. al."

      extends Modelica.Media.Interfaces.PartialPureSubstance(
        mediumName="Air",
        substanceNames={"air"},
        singleState=false,
        SpecificEnthalpy(start=1.0e5, nominal=5.0e5),
        Density(start=1.0, nominal=1.2),
        AbsolutePressure(
          start=1e5,
          nominal=1e5,
          min=1.0,
          max=2000e6),
        Temperature(
          start=273.15,
          nominal=293.15,
          min=130,
          max=2000));

      constant Boolean ph_explicit
        "true if explicit in pressure and specific enthalpy";
      constant Boolean dT_explicit
        "true if explicit in density and temperature";
      constant Boolean pT_explicit
        "true if explicit in pressure and temperature";

      redeclare record extends ThermodynamicState "thermodynamic state"
        SpecificEnthalpy h "specific enthalpy";
        Density d "density";
        Temperature T "temperature";
        AbsolutePressure p "pressure";
      end ThermodynamicState;

      redeclare replaceable model extends BaseProperties(
        h(stateSelect=if ph_explicit and preferredMediumStates then StateSelect.prefer
               else StateSelect.default),
        d(stateSelect=if dT_explicit and preferredMediumStates then StateSelect.prefer
               else StateSelect.default),
        T(stateSelect=if (pT_explicit or dT_explicit) and preferredMediumStates
               then StateSelect.prefer else StateSelect.default),
        p(stateSelect=if (pT_explicit or ph_explicit) and preferredMediumStates
               then StateSelect.prefer else StateSelect.default))
        "Base properties of water"

      equation
        MM = ReferenceAir.Air_Utilities.Basic.Constants.MM;
        if dT_explicit then
          p = pressure_dT(d, T);
          h = specificEnthalpy_dT(d, T);
        elseif ph_explicit then
          d = density_ph(p, h);
          T = temperature_ph(p, h);
        else
          h = specificEnthalpy_pT(p, T);
          d = density_pT(p, T);
        end if;
        u = h - p/d;
        R = Constants.R;
        h = state.h;
        p = state.p;
        T = state.T;
        d = state.d;
      end BaseProperties;

      redeclare function density_ph
        "Computes density as a function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        output Density d "Density";
      algorithm
        d := Air_Utilities.rho_ph(p, h);
      end density_ph;

      redeclare function temperature_ph
        "Computes temperature as a function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        output Temperature T "Temperature";
      algorithm
        T := Air_Utilities.T_ph(p, h);
      end temperature_ph;

      redeclare function temperature_ps
        "Compute temperature from pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output Temperature T "Temperature";
      algorithm
        T := Air_Utilities.T_ps(p, s);
      end temperature_ps;

      redeclare function density_ps
        "Computes density as a function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output Density d "density";
      algorithm
        d := Air_Utilities.rho_ps(p, s);
      end density_ps;

      redeclare function pressure_dT
        "Computes pressure as a function of density and temperature"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        output AbsolutePressure p "Pressure";
      algorithm
        p := Air_Utilities.p_dT(d, T);
      end pressure_dT;

      redeclare function specificEnthalpy_dT
        "Computes specific enthalpy as a function of density and temperature"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        output SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := Air_Utilities.h_dT(d, T);
      end specificEnthalpy_dT;

      redeclare function specificEnthalpy_pT
        "Computes specific enthalpy as a function of pressure and temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        output SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := Air_Utilities.h_pT(p, T);
      end specificEnthalpy_pT;

      redeclare function specificEnthalpy_ps
        "Computes specific enthalpy as a function of pressure and temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := Air_Utilities.h_ps(p, s);
      end specificEnthalpy_ps;

      redeclare function density_pT
        "Computes density as a function of pressure and temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        output Density d "Density";
      algorithm
        d := Air_Utilities.rho_pT(p, T);
      end density_pT;

      redeclare function extends dynamicViscosity
        "Return dynamic viscosity as a function of the thermodynamic state record"
      algorithm
        eta := Air_Utilities.dynamicViscosity(state);
      end dynamicViscosity;

      redeclare function extends thermalConductivity
        "Thermal conductivity of water"
      algorithm
        lambda := Air_Utilities.thermalConductivity(state);
      end thermalConductivity;

      redeclare function extends pressure "return pressure of ideal gas"
      algorithm
        p := state.p;
      end pressure;

      redeclare function extends temperature "return temperature of ideal gas"
      algorithm
        T := state.T;
      end temperature;

      redeclare function extends density "return density of ideal gas"
      algorithm
        d := state.d;
      end density;

      redeclare function extends specificEnthalpy "Return specific enthalpy"
      algorithm
        h := state.h;
      end specificEnthalpy;

      redeclare function extends specificInternalEnergy
        "Return specific internal energy"
      algorithm
        u := state.h - state.p/state.d;
      end specificInternalEnergy;

      redeclare function extends specificGibbsEnergy
        "Return specific Gibbs energy"
      algorithm
        g := state.h - state.T*specificEntropy(state);
      end specificGibbsEnergy;

      redeclare function extends specificHelmholtzEnergy
        "Return specific Helmholtz energy"
      algorithm
        f := state.h - state.p/state.d - state.T*specificEntropy(state);
      end specificHelmholtzEnergy;

      redeclare function extends specificEntropy "specific entropy of water"
      algorithm
        if dT_explicit then
          s := Air_Utilities.s_dT(state.d, state.T);
        elseif pT_explicit then
          s := Air_Utilities.s_pT(state.p, state.T);
        else
          s := Air_Utilities.s_ph(state.p, state.h);
        end if;
      end specificEntropy;

      redeclare function extends specificHeatCapacityCp
        "specific heat capacity at constant pressure of water"

      algorithm
        if dT_explicit then
          cp := Air_Utilities.cp_dT(state.d, state.T);
        elseif pT_explicit then
          cp := Air_Utilities.cp_pT(state.p, state.T);
        else
          cp := Air_Utilities.cp_ph(state.p, state.h);
        end if;
      end specificHeatCapacityCp;

      redeclare function extends specificHeatCapacityCv
        "specific heat capacity at constant volume of water"
      algorithm
        if dT_explicit then
          cv := Air_Utilities.cv_dT(state.d, state.T);
        elseif pT_explicit then
          cv := Air_Utilities.cv_pT(state.p, state.T);
        else
          cv := Air_Utilities.cv_ph(state.p, state.h);
        end if;
      end specificHeatCapacityCv;

      redeclare function extends isentropicExponent
        "Return isentropic exponent"
      algorithm
        if dT_explicit then
          gamma := Air_Utilities.isentropicExponent_dT(state.d, state.T);
        elseif pT_explicit then
          gamma := Air_Utilities.isentropicExponent_pT(state.p, state.T);
        else
          gamma := Air_Utilities.isentropicExponent_ph(state.p, state.h);
        end if;
      end isentropicExponent;

      redeclare function extends isothermalCompressibility
        "Isothermal compressibility of water"
      algorithm
        if dT_explicit then
          kappa := Air_Utilities.kappa_dT(state.d, state.T);
        elseif pT_explicit then
          kappa := Air_Utilities.kappa_pT(state.p, state.T);
        else
          kappa := Air_Utilities.kappa_ph(state.p, state.h);
        end if;
      end isothermalCompressibility;

      redeclare function extends isobaricExpansionCoefficient
        "isobaric expansion coefficient of water"
      algorithm
        if dT_explicit then
          beta := Air_Utilities.beta_dT(state.d, state.T);
        elseif pT_explicit then
          beta := Air_Utilities.beta_pT(state.p, state.T);
        else
          beta := Air_Utilities.beta_ph(state.p, state.h);
        end if;
      end isobaricExpansionCoefficient;

      redeclare function extends velocityOfSound
        "Return velocity of sound as a function of the thermodynamic state record"
      algorithm
        if dT_explicit then
          a := Air_Utilities.velocityOfSound_dT(state.d, state.T);
        elseif pT_explicit then
          a := Air_Utilities.velocityOfSound_pT(state.p, state.T);
        else
          a := Air_Utilities.velocityOfSound_ph(state.p, state.h);
        end if;
      end velocityOfSound;

      redeclare function extends density_derh_p
        "density derivative by specific enthalpy"
      algorithm
        ddhp := Air_Utilities.ddhp(state.p, state.h);
      end density_derh_p;

      redeclare function extends density_derp_h
        "density derivative by pressure"
      algorithm
        ddph := Air_Utilities.ddph(state.p, state.h);
      end density_derp_h;

      //   redeclare function extends density_derT_p
      //     "density derivative by temperature"
      //   algorithm
      //     ddTp := IF97_Utilities.ddTp(state.p, state.h, state.phase);
      //   end density_derT_p;
      //
      //   redeclare function extends density_derp_T
      //     "density derivative by pressure"
      //   algorithm
      //     ddpT := IF97_Utilities.ddpT(state.p, state.h, state.phase);
      //   end density_derp_T;

      redeclare function extends setState_dTX
        "Return thermodynamic state of water as function of d and T"
      algorithm
        state := ThermodynamicState(
                d=d,
                T=T,
                h=specificEnthalpy_dT(d, T),
                p=pressure_dT(d, T));
      end setState_dTX;

      redeclare function extends setState_phX
        "Return thermodynamic state of water as function of p and h"
      algorithm
        state := ThermodynamicState(
                d=density_ph(p, h),
                T=temperature_ph(p, h),
                h=h,
                p=p);
      end setState_phX;

      redeclare function extends setState_psX
        "Return thermodynamic state of water as function of p and s"
      algorithm
        state := ThermodynamicState(
                d=density_ps(p, s),
                T=temperature_ps(p, s),
                h=specificEnthalpy_ps(p, s),
                p=p);
      end setState_psX;

      redeclare function extends setState_pTX
        "Return thermodynamic state of water as function of p and T"
      algorithm
        state := ThermodynamicState(
                d=density_pT(p, T),
                T=T,
                h=specificEnthalpy_pT(p, T),
                p=p);
      end setState_pTX;

      redeclare function extends setSmoothState
        "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        import Modelica.Media.Common.smoothStep;
      algorithm
        state := ThermodynamicState(
                p=smoothStep(
                  x,
                  state_a.p,
                  state_b.p,
                  x_small),
                h=smoothStep(
                  x,
                  state_a.h,
                  state_b.h,
                  x_small),
                d=density_ph(smoothStep(
                  x,
                  state_a.p,
                  state_b.p,
                  x_small), smoothStep(
                  x,
                  state_a.h,
                  state_b.h,
                  x_small)),
                T=temperature_ph(smoothStep(
                  x,
                  state_a.p,
                  state_b.p,
                  x_small), smoothStep(
                  x,
                  state_a.h,
                  state_b.h,
                  x_small)));
      end setSmoothState;

      redeclare function extends isentropicEnthalpy
      algorithm
        h_is := specificEnthalpy_psX(
                p_downstream,
                specificEntropy(refState),
                reference_X);
      end isentropicEnthalpy;

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Text(
                  extent={{-94,84},{94,40}},
                  lineColor={127,191,255},
                  textString="IF97"),Text(
                  extent={{-94,20},{94,-24}},
                  lineColor={127,191,255},
                  textString="water")}), Documentation(info="<HTML>
<p>
This model calculates medium properties
for water in the <b>liquid</b>, <b>gas</b> and <b>two phase</b> regions
according to the IAPWS/IF97 standard, i.e., the accepted industrial standard
and best compromise between accuracy and computation time.
For more details see <a href=\"modelica://Modelica.Media.Water.IF97_Utilities\">
Modelica.Media.Water.IF97_Utilities</a>. Three variable pairs can be the
independent variables of the model:
</p>
<ol>
<li>Pressure <b>p</b> and specific enthalpy <b>h</b> are the most natural choice for general applications. This is the recommended choice for most general purpose applications, in particular for power plants.</li>
<li>Pressure <b>p</b> and temperature <b>T</b> are the most natural choice for applications where water is always in the same phase, both for liquid water and steam.</li>
<li>Density <b>d</b> and temperature <b>T</b> are explicit variables of the Helmholtz function in the near-critical region and can be the best choice for applications with super-critical or near-critial states.</li>
</ol>
<p>
The following quantities are always computed:
</p>
<table border=1 cellspacing=0 cellpadding=2>
  <tr><td valign=\"top\"><b>Variable</b></td>
      <td valign=\"top\"><b>Unit</b></td>
      <td valign=\"top\"><b>Description</b></td></tr>
  <tr><td valign=\"top\">T</td>
      <td valign=\"top\">K</td>
      <td valign=\"top\">temperature</td></tr>
  <tr><td valign=\"top\">u</td>
      <td valign=\"top\">J/kg</td>
      <td valign=\"top\">specific internal energy</td></tr>
  <tr><td valign=\"top\">d</td>
      <td valign=\"top\">kg/m^3</td>
      <td valign=\"top\">density</td></tr>
  <tr><td valign=\"top\">p</td>
      <td valign=\"top\">Pa</td>
      <td valign=\"top\">pressure</td></tr>
  <tr><td valign=\"top\">h</td>
      <td valign=\"top\">J/kg</td>
      <td valign=\"top\">specific enthalpy</td></tr>
</table>
<p>
In some cases additional medium properties are needed.
A component that needs these optional properties has to call
one of the functions listed in
<a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.OptionalProperties\">
Modelica.Media.UsersGuide.MediumUsage.OptionalProperties</a> and in
<a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.TwoPhase\">
Modelica.Media.UsersGuide.MediumUsage.TwoPhase</a>.
</p>
<p>Many further properties can be computed. Using the well-known Bridgman's Tables, all first partial derivatives of the standard thermodynamic variables can be computed easily.</p>
</html>"));
    end Air_Base;

    package Air_Utilities
      "Low level and utility computation for high accuracy dry air properties"
      extends Modelica.Icons.Package;

      record iter = Inverses.accuracy;
      package Basic "Fundamental equation of state"
        extends Modelica.Icons.BasesPackage;

        constant Modelica.Media.Common.FundamentalConstants Constants(
          final R_bar=8.31451,
          final R=287.117,
          final MM=28.9586E-003,
          final rhored=10447.7,
          final Tred=132.6312,
          final pred=3785020,
          h_off=1589557.62320524,
          s_off=6610.41237132543);

        function Helmholtz "Helmholtz equation of state"
          extends Modelica.Icons.Function;
          input SI.Density d "density";
          input SI.Temperature T "temperature (K)";
          output Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives w.r.t. delta and tau";

        protected
          final constant Real[13] N_0={0.605719400E-007,-0.210274769E-004,-0.158860716E-003,
              -0.13841928076E002,0.17275266575E002,-0.195363420E-003,
              0.2490888032E001,0.791309509,0.212236768,0.197938904,
              0.2536365E002,0.1690741E002,0.8731279E002};
          final constant Real[19] N={0.118160747229,0.713116392079,-0.161824192067E001,
              0.714140178971E-001,-0.865421396646E-001,0.134211176704,
              0.112626704218E-001,-0.420533228842E-001,0.349008431982E-001,
              0.164957183186E-003,-0.101365037912,-0.173813690970,-0.472103183731E-001,
              -0.122523554253E-001,-0.146629609713,-0.316055879821E-001,
              0.233594806142E-003,0.148287891978E-001,-0.938782884667E-002};
          final constant Integer[19] i={1,1,1,2,3,3,4,4,4,6,1,3,5,6,1,3,11,1,3};
          final constant Real[19] j={0,0.33,1.01,0,0,0.15,0,0.2,0.35,1.35,1.6,
              0.8,0.95,1.25,3.6,6,3.25,3.5,15};
          final constant Integer[19] l={0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3};

        algorithm
          f.d := d;
          f.T := T;
          f.R := ReferenceAir.Air_Utilities.Basic.Constants.R;
          //Reduced density
          f.delta := d/(ReferenceAir.Air_Utilities.Basic.Constants.MM*
            ReferenceAir.Air_Utilities.Basic.Constants.rhored);
          //Reciprocal reduced temperature
          f.tau := ReferenceAir.Air_Utilities.Basic.Constants.Tred/T;

          //Dimensionless Helmholtz equation
          f.f := 0;
          //Ideal-gas part
          for k in 1:5 loop
            f.f := f.f + N_0[k]*f.tau^(k - 4);
          end for;
          f.f := f.f + log(f.delta) + N_0[6]*f.tau*sqrt(f.tau) + N_0[7]*log(f.tau)
             + N_0[8]*log(1 - exp(-N_0[11]*f.tau)) + N_0[9]*log(1 - exp(-N_0[12]
            *f.tau)) + N_0[10]*log(2/3 + exp(N_0[13]*f.tau));
          //Residual part
          for k in 1:10 loop
            f.f := f.f + N[k]*f.delta^i[k]*f.tau^j[k];
          end for;
          for k in 11:19 loop
            f.f := f.f + N[k]*f.delta^i[k]*f.tau^j[k]*exp(-f.delta^l[k]);
          end for;

          //First derivative of f w.r.t. delta
          f.fdelta := 0;
          //Ideal-gas part
          f.fdelta := 1/f.delta;
          //Residual part
          for k in 1:10 loop
            f.fdelta := f.fdelta + i[k]*N[k]*f.delta^(i[k] - 1)*f.tau^j[k];
          end for;
          for k in 11:19 loop
            f.fdelta := f.fdelta + N[k]*f.delta^(i[k] - 1)*f.tau^j[k]*exp(-f.delta
              ^l[k])*(i[k] - l[k]*f.delta^l[k]);
          end for;

          //Second derivative of f w.r.t. delta
          f.fdeltadelta := 0;
          //Ideal-gas part
          f.fdeltadelta := -1/f.delta^2;
          //Residual part
          for k in 1:10 loop
            f.fdeltadelta := f.fdeltadelta + i[k]*(i[k] - 1)*N[k]*f.delta^(i[k]
               - 2)*f.tau^j[k];
          end for;
          for k in 11:19 loop
            f.fdeltadelta := f.fdeltadelta + N[k]*f.delta^(i[k] - 2)*f.tau^j[k]
              *exp(-f.delta^l[k])*((i[k] - l[k]*f.delta^l[k])*(i[k] - 1 - l[k]*
              f.delta^l[k]) - l[k]^2*f.delta^l[k]);
          end for;

          //First derivative of f w.r.t. tau
          f.ftau := 0;
          //Ideal-gas part
          for k in 1:5 loop
            f.ftau := f.ftau + (k - 4)*N_0[k]*f.tau^(k - 5);
          end for;
          f.ftau := f.ftau + 1.5*N_0[6]*sqrt(f.tau) + N_0[7]/f.tau + N_0[8]*N_0
            [11]/(exp(N_0[11]*f.tau) - 1) + N_0[9]*N_0[12]/(exp(N_0[12]*f.tau)
             - 1) + N_0[10]*N_0[13]/(2/3*exp(-N_0[13]*f.tau) + 1);
          //Residual part
          for k in 1:10 loop
            f.ftau := f.ftau + j[k]*N[k]*f.delta^i[k]*f.tau^(j[k] - 1);
          end for;
          for k in 11:19 loop
            f.ftau := f.ftau + j[k]*N[k]*f.delta^i[k]*f.tau^(j[k] - 1)*exp(-f.delta
              ^l[k]);
          end for;

          //Second derivative of f w.r.t. tau
          f.ftautau := 0;
          //Ideal-gas part
          for k in 1:3 loop
            f.ftautau := f.ftautau + (k - 4)*(k - 5)*N_0[k]*f.tau^(k - 6);
          end for;
          f.ftautau := f.ftautau + 0.75*N_0[6]/sqrt(f.tau) - N_0[7]/f.tau^2 -
            N_0[8]*N_0[11]^2*exp(N_0[11]*f.tau)/(exp(N_0[11]*f.tau) - 1)^2 -
            N_0[9]*N_0[12]^2*exp(N_0[12]*f.tau)/(exp(N_0[12]*f.tau) - 1)^2 + 2/
            3*N_0[10]*N_0[13]^2*exp(-N_0[13]*f.tau)/(2/3*exp(-N_0[13]*f.tau) +
            1)^2;
          //Residual part
          for k in 1:10 loop
            f.ftautau := f.ftautau + j[k]*(j[k] - 1)*N[k]*f.delta^i[k]*f.tau^(j[
              k] - 2);
          end for;
          for k in 11:19 loop
            f.ftautau := f.ftautau + j[k]*(j[k] - 1)*N[k]*f.delta^i[k]*f.tau^(j[
              k] - 2)*exp(-f.delta^l[k]);
          end for;

          //Mixed derivative of f w.r.t. delta and tau
          f.fdeltatau := 0;
          //Residual part (Ideal-gas part is zero)
          for k in 1:10 loop
            f.fdeltatau := f.fdeltatau + i[k]*j[k]*N[k]*f.delta^(i[k] - 1)*f.tau
              ^(j[k] - 1);
          end for;
          for k in 11:19 loop
            f.fdeltatau := f.fdeltatau + j[k]*N[k]*f.delta^(i[k] - 1)*f.tau^(j[
              k] - 1)*exp(-f.delta^l[k])*(i[k] - l[k]*f.delta^l[k]);
          end for;

        end Helmholtz;
      end Basic;

      package Inverses "Inverse function"
        extends Modelica.Icons.BasesPackage;

        record accuracy "Accuracy of the iterations"
          extends Modelica.Icons.Record;
          constant Real delp=1E-001 "Accuracy of p";
          constant Real delh=1E-009 "Accuracy of h";
          constant Real dels=1E-006 "Accuracy of s";
        end accuracy;

        function dofpT "Compute d for given p and T"
          extends Modelica.Icons.Function;
          input SI.Pressure p "pressure";
          input SI.Temperature T "temperature (K)";
          input SI.Pressure delp "iteration converged if (p-pre(p) < delp)";
          output SI.Density d "density";

        protected
          Integer i=0 "loop counter";
          Real dp "pressure difference";
          SI.Density deld "density step";
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives w.r.t. delta and tau";
          Modelica.Media.Common.NewtonDerivatives_pT nDerivs
            "derivatives needed in Newton iteration";
          Boolean found=false "flag for iteration success";

        algorithm
          d := p/(ReferenceAir.Air_Utilities.Basic.Constants.R*T);

          while ((i < 100) and not found) loop
            f := Basic.Helmholtz(d, T);
            nDerivs := Modelica.Media.Common.Helmholtz_pT(f);
            dp := nDerivs.p - p;
            if (abs(dp) <= delp) then
              found := true;
            end if;
            deld := dp/nDerivs.pd;
            d := d - deld;
            i := i + 1;
          end while;
        end dofpT;

        function dTofph "Return d and T as a function of p and h"
          extends Modelica.Icons.Function;
          input SI.Pressure p "pressure";
          input SI.SpecificEnthalpy h "specific enthalpy";
          input SI.Pressure delp "iteration accuracy";
          input SI.SpecificEnthalpy delh "iteration accuracy";
          output SI.Density d "density";
          output SI.Temperature T "temperature (K)";

        protected
          SI.Temperature Tguess "initial temperature";
          SI.Density dguess "initial density";
          Integer i "iteration counter";
          Real dh "Newton-error in h-direction";
          Real dp "Newton-error in p-direction";
          Real det "determinant of directional derivatives";
          Real deld "Newton-step in d-direction";
          Real delt "Newton-step in T-direction";
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives w.r.t. delta and tau";
          Modelica.Media.Common.NewtonDerivatives_ph nDerivs
            "derivatives needed in Newton iteration";
          Boolean found=false "flag for iteration success";

        algorithm
          // Stefan Wischhusen: better guess for high temperatures:
          T := h/1000 + 273.15;
          d := p/(ReferenceAir.Air_Utilities.Basic.Constants.R*T);
          i := 0;

          while ((i < 100) and not found) loop
            f := Basic.Helmholtz(d, T);
            nDerivs := Modelica.Media.Common.Helmholtz_ph(f);
            dh := nDerivs.h - ReferenceAir.Air_Utilities.Basic.Constants.h_off
               - h;
            dp := nDerivs.p - p;
            if ((abs(dh) <= delh) and (abs(dp) <= delp)) then
              found := true;
            end if;
            det := nDerivs.ht*nDerivs.pd - nDerivs.pt*nDerivs.hd;
            delt := (nDerivs.pd*dh - nDerivs.hd*dp)/det;
            deld := (nDerivs.ht*dp - nDerivs.pt*dh)/det;
            T := T - delt;
            d := d - deld;
            i := i + 1;
          end while;
        end dTofph;

        function dTofps "Return d and T as a function of p and s"
          extends Modelica.Icons.Function;
          input SI.Pressure p "pressure";
          input SI.SpecificEntropy s "specific entropy";
          input SI.Pressure delp "iteration accuracy";
          input SI.SpecificEntropy dels "iteration accuracy";
          output SI.Density d "density";
          output SI.Temperature T "temperature (K)";

        protected
          SI.Temperature Tguess "initial temperature";
          SI.Density dguess "initial density";
          Integer i "iteration counter";
          Real ds "Newton-error in s-direction";
          Real dp "Newton-error in p-direction";
          Real det "determinant of directional derivatives";
          Real deld "Newton-step in d-direction";
          Real delt "Newton-step in T-direction";
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives w.r.t. delta and tau";
          Modelica.Media.Common.NewtonDerivatives_ps nDerivs
            "derivatives needed in Newton iteration";
          Boolean found=false "flag for iteration success";

        algorithm
          T := 273.15;
          d := p/(ReferenceAir.Air_Utilities.Basic.Constants.R*T);
          i := 0;

          while ((i < 100) and not found) loop
            f := Basic.Helmholtz(d, T);
            nDerivs := Modelica.Media.Common.Helmholtz_ps(f);
            ds := nDerivs.s - ReferenceAir.Air_Utilities.Basic.Constants.s_off
               - s;
            dp := nDerivs.p - p;
            if ((abs(ds) <= dels) and (abs(dp) <= delp)) then
              found := true;
            end if;
            det := nDerivs.st*nDerivs.pd - nDerivs.pt*nDerivs.sd;
            delt := (nDerivs.pd*ds - nDerivs.sd*dp)/det;
            deld := (nDerivs.st*dp - nDerivs.pt*ds)/det;
            T := T - delt;
            d := d - deld;
            i := i + 1;
          end while;
        end dTofps;
      end Inverses;

      package Transport "Transport properties for air"
        extends Modelica.Icons.BasesPackage;

        function eta_dT "Return dynamic viscosity as a function of d and T"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          output SI.DynamicViscosity eta "Dynamic viscosity";

        protected
          Real delta=d/(ReferenceAir.Air_Utilities.Basic.Constants.MM*
              ReferenceAir.Air_Utilities.Basic.Constants.rhored)
            "Reduced density";
          Real tau=ReferenceAir.Air_Utilities.Basic.Constants.Tred/T
            "Reciprocal reduced temperature";
          Real Omega "Collision integral";
          SI.DynamicViscosity eta_0=0 "Dilute gas viscosity";
          SI.DynamicViscosity eta_r=0 "Residual fluid viscosity";
          final constant Real[5] b={0.431,-0.4623,0.08406,0.005341,-0.00331};
          final constant Real[5] Nvis={10.72,1.122,0.002019,-8.876,-0.02916};
          final constant Real[5] tvis={0.2,0.05,2.4,0.6,3.6};
          final constant Integer[5] dvis={1,4,9,1,8};
          final constant Integer[5] lvis={0,0,0,1,1};
          final constant Integer[5] gammavis={0,0,0,1,1};

        algorithm
          Omega := exp(
            Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate(
            {b[5],b[4],b[3],b[2],b[1]}, log(T/103.3)));
          eta_0 := 0.0266958*sqrt(1000*ReferenceAir.Air_Utilities.Basic.Constants.MM
            *T)/(0.36^2*Omega);
          for i in 1:5 loop
            eta_r := eta_r + (Nvis[i]*(tau^tvis[i])*(delta^dvis[i])*exp(-
              gammavis[i]*(delta^lvis[i])));
          end for;
          eta := (eta_0 + eta_r)*1E-006;
        end eta_dT;

        function lambda_dT
          "Return thermal conductivity as a function of d and T"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          output SI.ThermalConductivity lambda "Thermal conductivity";

        protected
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives w.r.t. delta and tau";
          SI.ThermalConductivity lambda_0=0 "Dilute gas thermal conductivity";
          SI.ThermalConductivity lambda_r=0
            "Residual fluid thermal conductivity";
          SI.ThermalConductivity lambda_c=0
            "Thermal conductivity critical enhancement";
          Real Omega "Collision integral";
          SI.DynamicViscosity eta_0=0 "Dilute gas viscosity";
          Real pddT;
          Real pddTref;
          Real pdTp;
          Real xi;
          Real xiref;
          Real Omega_tilde;
          Real Omega_0_tilde;
          Real cv;
          Real cp;
          final constant Real[5] b={0.431,-0.4623,0.08406,0.005341,-0.00331};
          final constant Real[9] Ncon={1.308,1.405,-1.036,8.743,14.76,-16.62,
              3.793,-6.142,-0.3778};
          final constant Real[9] tcon={0.0,-1.1,-0.3,0.1,0.0,0.5,2.7,0.3,1.3};
          final constant Integer[9] dcon={0,0,0,1,2,3,7,7,11};
          final constant Integer[9] lcon={0,0,0,0,0,2,2,2,2};
          final constant Integer[9] gammacon={0,0,0,0,0,1,1,1,1};

        algorithm
          //chi_tilde in at the reference temperature 265.262
          f := Basic.Helmholtz(d, 265.262);
          pddTref := ReferenceAir.Air_Utilities.Basic.Constants.R_bar*265.262*(
            1 + 2*f.delta*(f.fdelta - 1/f.delta) + f.delta^2*(f.fdeltadelta + 1
            /f.delta^2));
          xiref := ReferenceAir.Air_Utilities.Basic.Constants.pred*(d/
            ReferenceAir.Air_Utilities.Basic.Constants.MM)/ReferenceAir.Air_Utilities.Basic.Constants.rhored
            ^2/pddTref;
          //calculating f at the given state
          f := Basic.Helmholtz(d, T);
          Omega := exp(
            Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate(
            {b[5],b[4],b[3],b[2],b[1]}, log(T/103.3)));
          //Ideal-gas part of dynamic viscosity
          eta_0 := 0.0266958*sqrt(1000*ReferenceAir.Air_Utilities.Basic.Constants.MM
            *T)/(0.36^2*Omega);
          //Ideal-gas part of thermal conductivity
          lambda_0 := Ncon[1]*eta_0 + Ncon[2]*f.tau^tcon[2] + Ncon[3]*f.tau^
            tcon[3];
          //Residual part of thermal conductivity
          for i in 4:9 loop
            lambda_r := lambda_r + Ncon[i]*f.tau^tcon[i]*f.delta^dcon[i]*exp(-
              gammacon[i]*f.delta^lcon[i]);
          end for;
          //Derivative of p w.r.t. d at constant temperature
          pddT := ReferenceAir.Air_Utilities.Basic.Constants.R*T*(1 + 2*f.delta
            *(f.fdelta - 1/f.delta) + f.delta^2*(f.fdeltadelta + 1/f.delta^2));
          //chi_tilde at the given state
          xi := ReferenceAir.Air_Utilities.Basic.Constants.pred*(d/ReferenceAir.Air_Utilities.Basic.Constants.MM)
            /ReferenceAir.Air_Utilities.Basic.Constants.rhored^2/(pddT*
            ReferenceAir.Air_Utilities.Basic.Constants.MM);
          //Thermal conductivity critical enhancement
          xi := xi - xiref*265.262/T;
          if (xi <= 0) then
            lambda_c := 0;
          else
            xi := 0.11*(xi/0.055)^(0.63/1.2415);
            //Derivative of p w.r.t. T at constant p
            pdTp := ReferenceAir.Air_Utilities.Basic.Constants.R*d*(1 + f.delta
              *(f.fdelta - 1/f.delta) - f.delta*f.tau*f.fdeltatau);
            //Specific isochoric heat capacity
            cv := ReferenceAir.Air_Utilities.Basic.Constants.R*(-f.tau*f.tau*f.ftautau);
            //Specific isobaric heat capacity
            cp := cv + T*pdTp*pdTp/(d*d*pddT);
            Omega_tilde := 2/Modelica.Constants.pi*((cp - cv)/cp*atan(xi/0.31)
               + cv/cp*xi/0.31);
            Omega_0_tilde := 2/Modelica.Constants.pi*(1 - exp(-1/((0.31/xi) + 1
              /3*(xi/0.31)^2*(ReferenceAir.Air_Utilities.Basic.Constants.rhored
              /(d/ReferenceAir.Air_Utilities.Basic.Constants.MM))^2)));
            lambda_c := d*cp*1.380658E-023*1.01*T/(6*Modelica.Constants.pi*xi*
              eta_dT(d, T))*(Omega_tilde - Omega_0_tilde)*1E012;
          end if;
          lambda := (lambda_0 + lambda_r + lambda_c)/1000;
        end lambda_dT;
      end Transport;

      function airBaseProp_ps "intermediate property record for air"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        output Common.AuxiliaryProperties aux "auxiliary record";
      protected
        Modelica.Media.Common.HelmholtzDerivs f
          "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
      algorithm
        aux.p := p;
        aux.s := s;
        aux.R := ReferenceAir.Air_Utilities.Basic.Constants.R;
        (aux.rho,aux.T) := Inverses.dTofps(
                p=p,
                s=s,
                delp=iter.delp,
                dels=iter.dels);
        f := Basic.Helmholtz(aux.rho, aux.T);
        aux.h := aux.R*aux.T*(f.tau*f.ftau + f.delta*f.fdelta) - ReferenceAir.Air_Utilities.Basic.Constants.h_off;
        aux.pd := aux.R*aux.T*f.delta*(2*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt := aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv := aux.R*(-f.tau*f.tau*f.ftautau);
        aux.cp := aux.cv + aux.T*aux.pt*aux.pt/(aux.rho*aux.rho*aux.pd);
        aux.vp := -1/(aux.rho*aux.rho)*1/aux.pd;
        aux.vt := aux.pt/(aux.rho*aux.rho*aux.pd);
      end airBaseProp_ps;

      function rho_props_ps
        "density as function of pressure and specific entropy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Density rho "density";
      algorithm
        rho := aux.rho;
        annotation (Inline=false, LateInline=true);
      end rho_props_ps;

      function rho_ps "density as function of pressure and specific entropy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        output Modelica.SIunits.Density rho "density";
      algorithm
        rho := rho_props_ps(
                p,
                s,
                Air_Utilities.airBaseProp_ps(p, s));
      end rho_ps;

      function T_props_ps
        "temperature as function of pressure and specific entropy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Temperature T "temperature";
      algorithm
        T := aux.T;
        annotation (Inline=false, LateInline=true);
      end T_props_ps;

      function T_ps "temperature as function of pressure and specific entropy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        output Modelica.SIunits.Temperature T "Temperature";
      algorithm
        T := T_props_ps(
                p,
                s,
                Air_Utilities.airBaseProp_ps(p, s));
      end T_ps;

      function h_props_ps
        "specific enthalpy as function or pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := aux.h;
        annotation (Inline=false, LateInline=true);
      end h_props_ps;

      function h_ps "specific enthalpy as function or pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEntropy s "specific entropy";
        output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := h_props_ps(
                p,
                s,
                Air_Utilities.airBaseProp_ps(p, s));
      end h_ps;

      function airBaseProp_ph "intermediate property record for air"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Common.AuxiliaryProperties aux "auxiliary record";
      protected
        Modelica.Media.Common.HelmholtzDerivs f
          "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
        Integer error "error flag for inverse iterations";
      algorithm
        aux.p := p;
        aux.h := h;
        aux.R := ReferenceAir.Air_Utilities.Basic.Constants.R;
        (aux.rho,aux.T) := Inverses.dTofph(
                p,
                h,
                delp=iter.delp,
                delh=iter.delh);
        f := Basic.Helmholtz(aux.rho, aux.T);
        aux.s := aux.R*(f.tau*f.ftau - f.f) - ReferenceAir.Air_Utilities.Basic.Constants.s_off;
        aux.pd := aux.R*aux.T*f.delta*(2*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt := aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv := aux.R*(-f.tau*f.tau*f.ftautau);
        aux.cp := aux.cv + aux.T*aux.pt*aux.pt/(aux.rho*aux.rho*aux.pd);
        aux.vp := -1/(aux.rho*aux.rho)*1/aux.pd;
        aux.vt := aux.pt/(aux.rho*aux.rho*aux.pd);
      end airBaseProp_ph;

      function rho_props_ph
        "density as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Density rho "density";
      algorithm
        rho := aux.rho;
        annotation (
          derivative(noDerivative=aux) = rho_ph_der,
          Inline=false,
          LateInline=true);
      end rho_props_ph;

      function rho_ph "density as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.Density rho "density";
      algorithm
        rho := rho_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end rho_ph;

      function rho_ph_der "derivative function of rho_ph"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real p_der "derivative of pressure";
        input Real h_der "derivative of specific enthalpy";
        output Real rho_der "derivative of density";
      algorithm
        rho_der := ((aux.rho*(aux.cv*aux.rho + aux.pt))/(aux.rho*aux.rho*aux.pd
          *aux.cv + aux.T*aux.pt*aux.pt))*p_der + (-aux.rho*aux.rho*aux.pt/(aux.rho
          *aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt))*h_der;
      end rho_ph_der;

      function T_props_ph
        "temperature as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Temperature T "temperature";
      algorithm
        T := aux.T;
        annotation (
          derivative(noDerivative=aux) = T_ph_der,
          Inline=false,
          LateInline=true);
      end T_props_ph;

      function T_ph "temperature as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.Temperature T "Temperature";
      algorithm
        T := T_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end T_ph;

      function T_ph_der "derivative function of T_ph"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real p_der "derivative of pressure";
        input Real h_der "derivative of specific enthalpy";
        output Real T_der "derivative of temperature";
      algorithm
        T_der := ((-aux.rho*aux.pd + aux.T*aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv
           + aux.T*aux.pt*aux.pt))*p_der + ((aux.rho*aux.rho*aux.pd)/(aux.rho*
          aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt))*h_der;
      end T_ph_der;

      function s_props_ph
        "specific entropy as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificEntropy s "specific entropy";
      algorithm
        s := aux.s;
        annotation (
          derivative(noDerivative=aux) = s_ph_der,
          Inline=false,
          LateInline=true);
      end s_props_ph;

      function s_ph
        "specific entropy as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.SpecificEntropy s "specific entropy";
      algorithm
        s := s_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end s_ph;

      function s_ph_der
        "specific entropy as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real p_der "derivative of pressure";
        input Real h_der "derivative of specific enthalpy";
        output Real s_der "derivative of entropy";
      algorithm
        s_der := -1/(aux.rho*aux.T)*p_der + 1/aux.T*h_der;
      end s_ph_der;

      function cv_props_ph
        "specific heat capacity at constant volume as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificHeatCapacity cv
          "specific heat capacity";
      algorithm
        cv := aux.cv;
        annotation (Inline=false, LateInline=true);
      end cv_props_ph;

      function cv_ph
        "specific heat capacity at constant volume as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.SpecificHeatCapacity cv
          "specific heat capacity";
      algorithm
        cv := cv_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end cv_ph;

      function cp_props_ph
        "specific heat capacity at constant pressure as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificHeatCapacity cp
          "specific heat capacity";
      algorithm
        cp := aux.cp;
        annotation (Inline=false, LateInline=true);
      end cp_props_ph;

      function cp_ph
        "specific heat capacity at constant pressure as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.SpecificHeatCapacity cp
          "specific heat capacity";
      algorithm
        cp := cp_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end cp_ph;

      function beta_props_ph
        "isobaric expansion coefficient as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.RelativePressureCoefficient beta
          "isobaric expansion coefficient";
      algorithm
        beta := aux.pt/(aux.rho*aux.pd);
        annotation (Inline=false, LateInline=true);
      end beta_props_ph;

      function beta_ph
        "isobaric expansion coefficient as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.RelativePressureCoefficient beta
          "isobaric expansion coefficient";
      algorithm
        beta := beta_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end beta_ph;

      function kappa_props_ph
        "isothermal compressibility factor as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.IsothermalCompressibility kappa
          "isothermal compressibility factor";
      algorithm
        kappa := 1/(aux.rho*aux.pd);
        annotation (Inline=false, LateInline=true);
      end kappa_props_ph;

      function kappa_ph
        "isothermal compressibility factor as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.IsothermalCompressibility kappa
          "isothermal compressibility factor";
      algorithm
        kappa := kappa_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end kappa_ph;

      function velocityOfSound_props_ph
        "speed of sound as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Velocity a "speed of sound";
      algorithm
        a := sqrt(max(0, aux.pd + aux.pt*aux.pt*aux.T/(aux.rho*aux.rho*aux.cv)));
        annotation (Inline=false, LateInline=true);
      end velocityOfSound_props_ph;

      function velocityOfSound_ph
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.Velocity a "speed of sound";
      algorithm
        a := velocityOfSound_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end velocityOfSound_ph;

      function isentropicExponent_props_ph
        "isentropic exponent as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Real gamma "isentropic exponent";
      algorithm
        gamma := 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*
          aux.T)/(aux.cv));
        annotation (Inline=false, LateInline=true);
      end isentropicExponent_props_ph;

      function isentropicExponent_ph
        "isentropic exponent as function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Real gamma "isentropic exponent";
      algorithm
        gamma := isentropicExponent_props_ph(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
        annotation (Inline=false, LateInline=true);
      end isentropicExponent_ph;

      function ddph_props "density derivative by pressure"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.DerDensityByPressure ddph
          "density derivative by pressure";
      algorithm
        ddph := ((aux.rho*(aux.cv*aux.rho + aux.pt))/(aux.rho*aux.rho*aux.pd*
          aux.cv + aux.T*aux.pt*aux.pt));
        annotation (Inline=false, LateInline=true);
      end ddph_props;

      function ddph "density derivative by pressure"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.DerDensityByPressure ddph
          "density derivative by pressure";
      algorithm
        ddph := ddph_props(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end ddph;

      function ddhp_props "density derivative by specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.DerDensityByEnthalpy ddhp
          "density derivative by specific enthalpy";
      algorithm
        ddhp := -aux.rho*aux.rho*aux.pt/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*
          aux.pt*aux.pt);
        annotation (Inline=false, LateInline=true);
      end ddhp_props;

      function ddhp "density derivative by specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        output Modelica.SIunits.DerDensityByEnthalpy ddhp
          "density derivative by specific enthalpy";
      algorithm
        ddhp := ddhp_props(
                p,
                h,
                Air_Utilities.airBaseProp_ph(p, h));
      end ddhp;

      function airBaseProp_pT
        "intermediate property record for air (p and T prefered states)"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Common.AuxiliaryProperties aux "auxiliary record";
      protected
        Modelica.Media.Common.HelmholtzDerivs f
          "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
      algorithm
        aux.p := p;
        aux.T := T;
        aux.R := ReferenceAir.Air_Utilities.Basic.Constants.R;
        (aux.rho) := Inverses.dofpT(
                p=p,
                T=T,
                delp=iter.delp);
        f := Basic.Helmholtz(aux.rho, T);
        aux.h := aux.R*T*(f.tau*f.ftau + f.delta*f.fdelta) - ReferenceAir.Air_Utilities.Basic.Constants.h_off;
        aux.s := aux.R*(f.tau*f.ftau - f.f) - ReferenceAir.Air_Utilities.Basic.Constants.s_off;
        aux.pd := aux.R*T*f.delta*(2*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt := aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv := aux.R*(-f.tau*f.tau*f.ftautau);
        aux.cp := aux.cv + aux.T*aux.pt*aux.pt/(aux.rho*aux.rho*aux.pd);
        aux.vp := -1/(aux.rho*aux.rho)*1/aux.pd;
        aux.vt := aux.pt/(aux.rho*aux.rho*aux.pd);
      end airBaseProp_pT;

      function rho_props_pT "density as function or pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Density rho "density";
      algorithm
        rho := aux.rho;
        annotation (
          derivative(noDerivative=aux) = rho_pT_der,
          Inline=false,
          LateInline=true);
      end rho_props_pT;

      function rho_pT "density as function or pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.Density rho "density";
      algorithm
        rho := rho_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end rho_pT;

      function rho_pT_der "derivative function of rho_pT"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real p_der "derivative of pressure";
        input Real T_der "derivative of temperature";
        output Real rho_der "derivative of density";
      algorithm
        rho_der := (1/aux.pd)*p_der - (aux.pt/aux.pd)*T_der;
      end rho_pT_der;

      function h_props_pT
        "specific enthalpy as function or pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := aux.h;
        annotation (
          derivative(noDerivative=aux) = h_pT_der,
          Inline=false,
          LateInline=true);
      end h_props_pT;

      function h_pT "specific enthalpy as function or pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "Temperature";
        output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := h_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end h_pT;

      function h_pT_der "derivative function of h_pT"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real p_der "derivative of pressure";
        input Real T_der "derivative of temperature";
        output Real h_der "derivative of specific enthalpy";
      algorithm
        h_der := ((-aux.rho*aux.pd + T*aux.pt)/(aux.rho*aux.rho*aux.pd))*p_der
           + ((aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*
          aux.rho*aux.pd))*T_der;
      end h_pT_der;

      function s_props_pT
        "specific entropy as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificEntropy s "specific entropy";
      algorithm
        s := aux.s;
        annotation (Inline=false, LateInline=true);
      end s_props_pT;

      function s_pT "temperature as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.SpecificEntropy s "specific entropy";
      algorithm
        s := s_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end s_pT;

      function cv_props_pT
        "specific heat capacity at constant volume as function of pressure and temperature"

        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificHeatCapacity cv
          "specific heat capacity";
      algorithm
        cv := aux.cv;
        annotation (Inline=false, LateInline=true);
      end cv_props_pT;

      function cv_pT
        "specific heat capacity at constant volume as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.SpecificHeatCapacity cv
          "specific heat capacity";
      algorithm
        cv := cv_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end cv_pT;

      function cp_props_pT
        "specific heat capacity at constant pressure as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificHeatCapacity cp
          "specific heat capacity";
      algorithm
        cp := aux.cp;
        annotation (Inline=false, LateInline=true);
      end cp_props_pT;

      function cp_pT
        "specific heat capacity at constant pressure as function of pressure and temperature"

        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.SpecificHeatCapacity cp
          "specific heat capacity";
      algorithm
        cp := cp_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end cp_pT;

      function beta_props_pT
        "isobaric expansion coefficient as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.RelativePressureCoefficient beta
          "isobaric expansion coefficient";
      algorithm
        beta := aux.pt/(aux.rho*aux.pd);
        annotation (Inline=false, LateInline=true);
      end beta_props_pT;

      function beta_pT
        "isobaric expansion coefficient as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.RelativePressureCoefficient beta
          "isobaric expansion coefficient";
      algorithm
        beta := beta_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end beta_pT;

      function kappa_props_pT
        "isothermal compressibility factor as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.IsothermalCompressibility kappa
          "isothermal compressibility factor";
      algorithm
        kappa := 1/(aux.rho*aux.pd);
        annotation (Inline=false, LateInline=true);
      end kappa_props_pT;

      function kappa_pT
        "isothermal compressibility factor as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.IsothermalCompressibility kappa
          "isothermal compressibility factor";
      algorithm
        kappa := kappa_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end kappa_pT;

      function velocityOfSound_props_pT
        "speed of sound as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Velocity a "speed of sound";
      algorithm
        a := sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/
          (aux.rho*aux.rho*aux.cv)));
        annotation (Inline=false, LateInline=true);
      end velocityOfSound_props_pT;

      function velocityOfSound_pT
        "speed of sound as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.Velocity a "speed of sound";
      algorithm
        a := velocityOfSound_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end velocityOfSound_pT;

      function isentropicExponent_props_pT
        "isentropic exponent as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Real gamma "isentropic exponent";
      algorithm
        gamma := 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*
          aux.T)/(aux.cv));
        annotation (Inline=false, LateInline=true);
      end isentropicExponent_props_pT;

      function isentropicExponent_pT
        "isentropic exponent as function of pressure and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Real gamma "isentropic exponent";
      algorithm
        gamma := isentropicExponent_props_pT(
                p,
                T,
                Air_Utilities.airBaseProp_pT(p, T));
      end isentropicExponent_pT;

      function airBaseProp_dT
        "intermediate property record for air (d and T prefered states)"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Common.AuxiliaryProperties aux "auxiliary record";
      protected
        Modelica.Media.Common.HelmholtzDerivs f
          "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
      algorithm
        aux.rho := d;
        aux.T := T;
        aux.R := ReferenceAir.Air_Utilities.Basic.Constants.R;
        f := Basic.Helmholtz(d, T);
        aux.p := aux.R*d*T*f.delta*f.fdelta;
        aux.h := aux.R*T*(f.tau*f.ftau + f.delta*f.fdelta) - ReferenceAir.Air_Utilities.Basic.Constants.h_off;
        aux.s := aux.R*(f.tau*f.ftau - f.f) - ReferenceAir.Air_Utilities.Basic.Constants.s_off;
        aux.pd := aux.R*T*f.delta*(2*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt := aux.R*d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv := aux.R*(-f.tau*f.tau*f.ftautau);
        aux.cp := aux.cv + aux.T*aux.pt*aux.pt/(d*d*aux.pd);
        aux.vp := -1/(aux.rho*aux.rho)*1/aux.pd;
        aux.vt := aux.pt/(aux.rho*aux.rho*aux.pd);
      end airBaseProp_dT;

      function h_props_dT
        "specific enthalpy as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "Temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := aux.h;
        annotation (
          derivative(noDerivative=aux) = h_dT_der,
          Inline=false,
          LateInline=true);
      end h_props_dT;

      function h_dT "specific enthalpy as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "Temperature";
        output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      algorithm
        h := h_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end h_dT;

      function h_dT_der "derivative function of h_dT"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real d_der "derivative of density";
        input Real T_der "derivative of temperature";
        output Real h_der "derivative of specific enthalpy";
      algorithm
        h_der := ((-d*aux.pd + T*aux.pt)/(d*d))*d_der + ((aux.cv*d + aux.pt)/d)
          *T_der;
      end h_dT_der;

      function p_props_dT "pressure as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "Temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Pressure p "pressure";
      algorithm
        p := aux.p;
        annotation (
          derivative(noDerivative=aux) = p_dT_der,
          Inline=false,
          LateInline=true);
      end p_props_dT;

      function p_dT "pressure as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "Temperature";
        output Modelica.SIunits.Pressure p "pressure";
      algorithm
        p := p_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end p_dT;

      function p_dT_der "derivative function of p_dT"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        input Real d_der "derivative of density";
        input Real T_der "derivative of temperature";
        output Real p_der "derivative of pressure";
      algorithm
        p_der := aux.pd*d_der + aux.pt*T_der;
      end p_dT_der;

      function s_props_dT
        "specific entropy as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "Temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificEntropy s "specific entropy";
      algorithm
        s := aux.s;
        annotation (Inline=false, LateInline=true);
      end s_props_dT;

      function s_dT "temperature as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "Temperature";
        output Modelica.SIunits.SpecificEntropy s "specific entropy";
      algorithm
        s := s_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end s_dT;

      function cv_props_dT
        "specific heat capacity at constant volume as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificHeatCapacity cv
          "specific heat capacity";
      algorithm
        cv := aux.cv;
        annotation (Inline=false, LateInline=true);
      end cv_props_dT;

      function cv_dT
        "specific heat capacity at constant volume as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.SpecificHeatCapacity cv
          "specific heat capacity";
      algorithm
        cv := cv_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end cv_dT;

      function cp_props_dT
        "specific heat capacity at constant pressure as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.SpecificHeatCapacity cp
          "specific heat capacity";
      algorithm
        cp := aux.cp;
        annotation (Inline=false, LateInline=true);
      end cp_props_dT;

      function cp_dT
        "specific heat capacity at constant pressure as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.SpecificHeatCapacity cp
          "specific heat capacity";
      algorithm
        cp := cp_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end cp_dT;

      function beta_props_dT
        "isobaric expansion coefficient as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.RelativePressureCoefficient beta
          "isobaric expansion coefficient";
      algorithm
        beta := aux.pt/(aux.rho*aux.pd);
        annotation (Inline=false, LateInline=true);
      end beta_props_dT;

      function beta_dT
        "isobaric expansion coefficient as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.RelativePressureCoefficient beta
          "isobaric expansion coefficient";
      algorithm
        beta := beta_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end beta_dT;

      function kappa_props_dT
        "isothermal compressibility factor as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.IsothermalCompressibility kappa
          "isothermal compressibility factor";
      algorithm
        kappa := 1/(aux.rho*aux.pd);
        annotation (Inline=false, LateInline=true);
      end kappa_props_dT;

      function kappa_dT
        "isothermal compressibility factor as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.IsothermalCompressibility kappa
          "isothermal compressibility factor";
      algorithm
        kappa := kappa_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end kappa_dT;

      function velocityOfSound_props_dT
        "speed of sound as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Modelica.SIunits.Velocity a "speed of sound";
      algorithm
        a := sqrt(max(0, ((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)
          /(aux.rho*aux.rho*aux.cv))));
        annotation (Inline=false, LateInline=true);
      end velocityOfSound_props_dT;

      function velocityOfSound_dT
        "speed of sound as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.SIunits.Velocity a "speed of sound";
      algorithm
        a := velocityOfSound_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end velocityOfSound_dT;

      function isentropicExponent_props_dT
        "isentropic exponent as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Common.AuxiliaryProperties aux "auxiliary record";
        output Real gamma "isentropic exponent";
      algorithm
        gamma := 1/(aux.rho*aux.p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt
          *aux.T)/(aux.cv));
        annotation (Inline=false, LateInline=true);
      end isentropicExponent_props_dT;

      function isentropicExponent_dT
        "isentropic exponent as function of density and temperature"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        output Real gamma "isentropic exponent";
      algorithm
        gamma := isentropicExponent_props_dT(
                d,
                T,
                Air_Utilities.airBaseProp_dT(d, T));
      end isentropicExponent_dT;

      function dynamicViscosity
        "Return dynamic viscosity as a function of the thermodynamic state record"
        extends Modelica.Icons.Function;
        input Air_Base.ThermodynamicState state "Thermodynamic state record";
        output SI.DynamicViscosity eta "Dynamic viscosity";
      algorithm
        eta := Transport.eta_dT(state.d, state.T);
      end dynamicViscosity;

      function thermalConductivity
        "Return thermal conductivity as a function of the thermodynamic state record"
        extends Modelica.Icons.Function;
        input Air_Base.ThermodynamicState state "Thermodynamic state record";
        output SI.ThermalConductivity lambda "Thermal conductivity";
      algorithm
        lambda := Transport.lambda_dT(state.d, state.T);
      end thermalConductivity;

    protected
      package ThermoFluidSpecial

        function air_ph
          "calculate the property record for dynamic simulation properties using p,h as states"
          extends Modelica.Icons.Function;
          input Modelica.SIunits.Pressure p "pressure";
          input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
          output Modelica.Media.Common.ThermoFluidSpecial.ThermoProperties_ph
            pro "property record for dynamic simulation";
        protected
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
          Modelica.SIunits.Temperature T "temperature";
          Modelica.SIunits.Density d "density";
        algorithm
          (d,T) := Air_Utilities.Inverses.dTofph(
                    p=p,
                    h=h,
                    delp=1.0e-7,
                    delh=1.0e-6);
          f := Air_Utilities.Basic.Helmholtz(d, T);
          pro := Modelica.Media.Common.ThermoFluidSpecial.helmholtzToProps_ph(f);
        end air_ph;

        function air_dT
          "calculate property record for dynamic simulation properties using d and T as dynamic states"
          extends Modelica.Icons.Function;
          input Modelica.SIunits.Density d "density";
          input Modelica.SIunits.Temperature T "temperature";
          output Modelica.Media.Common.ThermoFluidSpecial.ThermoProperties_dT
            pro "property record for dynamic simulation";
        protected
          Modelica.SIunits.Pressure p "pressure";
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
        algorithm
          f := Air_Utilities.Basic.Helmholtz(d, T);
          pro := Modelica.Media.Common.ThermoFluidSpecial.helmholtzToProps_dT(f);
        end air_dT;

        function air_pT
          "calculate property record for dynamic simulation properties using p and T as dynamic states"

          extends Modelica.Icons.Function;
          input Modelica.SIunits.Pressure p "pressure";
          input Modelica.SIunits.Temperature T "temperature";
          output Modelica.Media.Common.ThermoFluidSpecial.ThermoProperties_pT
            pro "property record for dynamic simulation";
        protected
          Modelica.SIunits.Density d "density";
          Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz funcion and dervatives w.r.t. delta and tau";
        algorithm
          d := Modelica.Media.Air.ReferenceAir.Air_Utilities.Inverses.dofpT(
                    p=p,
                    T=T,
                    delp=1e-7);
          f := Air_Utilities.Basic.Helmholtz(d, T);
          pro := Modelica.Media.Common.ThermoFluidSpecial.helmholtzToProps_pT(f);
        end air_pT;
      end ThermoFluidSpecial;

    end Air_Utilities;
    annotation (Documentation(info="<html>
<p>
Calculation of fluid properties of air in the fluid region of 130 Kelvin to 2000 Kelvin at pressures up to 2000 MPa. To use this package in your model, select <a href=\"modelica://Modelica.Media.Air.RealGasAir.Air_dT\">
Air_dT</a>, <a href=\"modelica://Modelica.Media.Air.RealGasAir.Air_pT\">
Air_pT</a> or <a href=\"modelica://Modelica.Media.Air.RealGasAir.Air_ph\">Air_ph</a> according to which variables you choose to determine your state.
</p>

<h4>Restriction</h4>
<p>
The functions provided by this package shall be used inside of the restricted limits according to the referenced literature.
</p>

<ul>
<li>
<b>p &le; 2000 MPa</b>
</li>
<li>
<b>130 K &le; T &le; 2000 K</b>
</li>
</ul>

<h4>References</h4>
<dl>
<dt>Lemmon, E. W., Jacobsen, R. T., Penoncello, S. G., Friend, D. G.:</dt>
<dd><b>Thermodynamic Properties of Air and Mixtures of Nitrogen, Argon,
and Oxygen From 60 to 2000 K at Pressures to 2000 MPa</b>. J. Phys. Chem. Ref. Data, Vol. 29, No. 3, 2000.
</dd>
<dt>Lemmon, E. W., Jacobsen, R. T.:</dt>
<dd><b>Viscosity and Thermal Conductivity Equations for
Nitrogen, Oxygen, Argon, and Air</b>. International Journal of Thermophysics, Vol. 25, No. 1, January 2004
</dd>
</dl>


<h4>Verification</h4>
<p>
The verification report for the development of this library is provided
<a href=\"modelica://Modelica/Resources/Documentation/Media/MoMoLib_VerificationResults_XRG.pdf\">here</a>.
</p>

<h4>Acknowledgment</h4>
<p>
This library was developed by XRG Simulation GmbH as part of the <a href=\"http://www.cleansky.eu/\">Clean Sky</a> JTI project (Project title: MoMoLib-Modelica Model Library Development for Media, Magnetic Systems and Wavelets; Project number: 296369; Theme: JTI-CS-2011-1-SGO-02-026: Modelica Model Library Development Part I). The partial financial support for the development of this library by the European Union is highly appreciated.
</p>

<p>
Some parts of this library refer to the ThermoFluid library developed at Lund University (<a href=\"http://thermofluid.sourceforge.net/\">http://thermofluid.sourceforge.net</a>).
</p>

<h4>Disclaimer</h4>
<p>
In no event will XRG Simulation GmbH be liable for any direct, indirect, incidental, special, exemplary, or consequential damages, arising in any way out of the use of this software, even if advised of the possibility of such damage.
</p>
<h4> Copyright (C) 2013, XRG Simulation GmbH </h4>

</html>"));
end ReferenceAir;