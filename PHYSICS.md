# Interplanetary mission physics — full walkthrough

*Curtis, Orbital Mechanics for Engineering Students (4th ed.), Chapters 6–8.*  
*Companion to the MATLAB scripts in this folder.*

This document explains **why** each step of the Earth → Mars → Earth → Jupiter (E–M–E–J) mission works, how it maps to Curtis, and which script implements what. It is written for exam reports and for understanding — not as a copy-paste answer key.

**Related files:**

| File | Role |
|------|------|
| [`SUMMARY.md`](SUMMARY.md) | One-page numbers and checklist |
| [`README.md`](README.md) | Full script reference and extension recipes |
| `exam_earth_mars_earth_jupiter.m` | Runnable exam solution |

```matlab
cd matlab
setup
exam_earth_mars_earth_jupiter
```

---

## Table of contents

1. [The problem we are solving](#1-the-problem-we-are-solving)
2. [Why patched conics?](#2-why-patched-conics)
3. [Two-body mechanics you need everywhere](#3-two-body-mechanics-you-need-everywhere)
4. [Spheres of influence](#4-spheres-of-influence)
5. [Launch windows, phase angle, and synodic period](#5-launch-windows-phase-angle-and-synodic-period)
6. [Hohmann transfer — the baseline Curtis starts with](#6-hohmann-transfer--the-baseline-curtis-starts-with)
7. [Why the exam uses Lambert, not Hohmann](#7-why-the-exam-uses-lambert-not-hohmann)
8. [Lambert’s problem — the physics and the code](#8-lamberts-problem--the-physics-and-the-code)
9. [Where the planets are — Algorithm 8.1](#9-where-the-planets-are--algorithm-81)
10. [Leaving Earth — parking orbit, hyperbola, and C3](#10-leaving-earth--parking-orbit-hyperbola-and-c3)
11. [Gravity assist — free heliocentric energy](#11-gravity-assist--free-heliocentric-energy)
12. [Arriving at Jupiter — capture hyperbola](#12-arriving-at-jupiter--capture-hyperbola)
13. [Full E–M–E–J mission, event by event](#13-full-em-ej-mission-event-by-event)
14. [Asteroid belt crossing](#14-asteroid-belt-crossing)
15. [Building the Δv budget](#15-building-the-δv-budget)
16. [What we simplify — and what to write in the exam](#16-what-we-simplify--and-what-to-write-in-the-exam)
17. [Extending the physics — moons, extra flybys, iteration](#17-extending-the-physics--moons-extra-flybys-iteration)
18. [Equation and script index](#18-equation-and-script-index)

---

## 1. The problem we are solving

### 1.1 Mission statement

Design a **feasibility study** for a spacecraft that:

1. Starts in **low Earth orbit** (300 km altitude in the exam).
2. Escapes Earth’s sphere of influence with enough energy to enter a **heliocentric transfer**.
3. Encounters **Mars** on a given calendar date and uses a **gravity assist** (no propulsion at Mars).
4. Returns to **Earth** on a given date for a second gravity assist.
5. Reaches **Jupiter** on a given date and performs a **capture burn** into orbit.

The exam sheet fixes the dates:

| Event | Date |
|-------|------|
| Earth departure | 2026-12-01 |
| Mars flyby | 2027-08-01 |
| Earth flyby | 2028-12-01 |
| Jupiter arrival | 2031-09-01 |

Those dates **determine** the time of flight (TOF) of each leg. You do not choose TOF to minimise energy — you choose it because the planets must be at the right places.

### 1.2 What “solve the mission” means in this course

Curtis Ch. 8 asks for:

- Trajectory **type** at each segment (ellipse/hyperbola about Sun or planet).
- **Phase angles** and comparison to Hohmann reference.
- **Hyperbolic excess speeds** \(v_\infty\) at each SOI crossing.
- **Launch energy** (C3) and LEO \(\Delta v\).
- **Flyby geometry** (turn angle, periapsis radius, heliocentric gain).
- **Capture** \(\Delta v\) at destination.
- A **Δv budget** separating propulsive burns from gravity-assist gains.
- **Limitations** of the patched-conic model.

The script `exam_earth_mars_earth_jupiter.m` automates the numerics; this document explains the physics behind each line.

---

## 2. Why patched conics?

### 2.1 The real solar system is n-body

Earth, Mars, Jupiter, and the spacecraft all attract each other simultaneously. The true motion has no closed-form solution. Numerical integration (ephemeris + force model) is what JPL uses for flight projects.

### 2.2 Curtis’s approximation — §8.5

**Patched conics** replace the full problem with a sequence of **two-body problems**:

| Region | Dominant body | Orbit type |
|--------|---------------|------------|
| Near Earth | Earth | Ellipse or hyperbola about Earth |
| Between planets | Sun | Conic about Sun |
| Near Mars | Mars | Hyperbola (flyby) about Mars |
| … | … | … |

At each **sphere of influence (SOI)** boundary you:

1. Match **position** (spacecraft and planet are at the same place at encounter).
2. Transform **velocity**: subtract planet velocity to get \(v_\infty\) in the planet frame; add it back when leaving.

```
         SUN-CENTRED ARC                    PLANET SOI
    ..............................          ┌─────────┐
    .                            .          │ hyper-  │
    .   Keplerian transfer       .  ──SOI──► │ bolic   │
    .   about the Sun            .  ◄──SOI── │ flyby   │
    .                            .          └─────────┘
    ..............................
```

**Why we use it:** It is exactly what Ch. 8 teaches. It gives closed-form \(\Delta v\) estimates good to a few percent when:

- Flyby periapsis is not dangerously low.
- You stay away from SOI boundaries for long coasts.
- Impulsive burns (not low-thrust).

**Script implication:** We never call an n-body integrator. Each leg is `interplanetary_lambert` (Sun) or `flyby_patch` / `departure_dv` / `capture_dv` (planet).

---

## 3. Two-body mechanics you need everywhere

Every segment — LEO, heliocentric transfer, flyby, capture — is a conic in a central gravity field. The same three ideas appear in every task.

### 3.1 Specific mechanical energy and orbit type — Ch. 2

Specific energy (energy per unit mass):

\[
\varepsilon = \frac{v^2}{2} - \frac{\mu}{r}
\]

| Sign of \(\varepsilon\) | Orbit |
|-------------------------|-------|
| \(\varepsilon < 0\) | Closed: circle or ellipse |
| \(\varepsilon = 0\) | Parabola: exactly escape |
| \(\varepsilon > 0\) | Hyperbola: unbound |

For bound orbits, \(\varepsilon = -\mu/(2a)\). The semi-major axis \(a\) fixes the energy.

**Exam use:** Asteroid belt check (Task 7) uses \(\varepsilon\) and eccentricity from the departure state on the Lambert orbit.

### 3.2 Vis-viva equation

At any point on a conic:

\[
v = \sqrt{\mu\left(\frac{2}{r} - \frac{1}{a}\right)}
\]

**Where it appears:**

- Circular parking speed in LEO: \(a = r\), so \(v_\text{circ} = \sqrt{\mu/r}\).
- Speed at periapsis of a transfer ellipse: set \(r = r_p\), \(a = (r_p + r_a)/2\).
- Heliocentric speed on a Hohmann transfer (§8.2): same formula with \(\mu = \mu_\odot\).

`multiburn_leo_escape.m` uses vis-viva at perigee for each ellipse before the final escape speed.

### 3.3 Hyperbolic excess speed \(v_\infty\)

When a spacecraft arrives at a planet from “far away” (outside the SOI), relative to the planet it moves on a **hyperbola** with a constant asymptotic speed called the **hyperbolic excess speed** \(v_\infty\).

In the planet frame:

\[
\varepsilon = \frac{v_\infty^2}{2}
\]

At periapsis radius \(r_p\) on that hyperbola:

\[
v_p = \sqrt{v_\infty^2 + \frac{2\mu}{r_p}}
\quad\text{(Eq. 8.40 / 8.42)}
\]

**Characteristic energy (launch energy):**

\[
C_3 = v_\infty^2 \quad \text{(km}^2/\text{s}^2\text{)}
\]

C3 is what launch vehicle people quote. Our leg-1 result \(v_\infty \approx 4.31\ \text{km/s}\) gives \(C_3 \approx 18.6\).

**Script:** `interplanetary_lambert` computes \(v_\infty = \|\mathbf{V}_\text{sc} - \mathbf{V}_\text{planet}\|\) at each end. `departure_dv` and `multiburn_leo_escape` convert required \(v_\infty\) into LEO \(\Delta v\).

### 3.4 Eccentricity of a flyby or departure hyperbola

For a hyperbola with periapsis \(r_p\) and \(v_\infty\):

\[
e = 1 + \frac{r_p v_\infty^2}{\mu}
\quad\text{(Eq. 8.54 context)}
\]

Used in `flyby_patch.m` and `flyby_delta.m`. Larger \(v_\infty\) or smaller \(r_p\) → larger \(e\) → sharper hyperbola.

---

## 4. Spheres of influence

### 4.1 Definition — Eq. (8.34)

Curtis uses a simple radius for the patch boundary:

\[
r_\text{SOI} = a_\text{planet} \left(\frac{m_\text{planet}}{m_\odot}\right)^{2/5}
\]

where \(a_\text{planet}\) is the planet’s heliocentric orbital radius.

**Script:** `sphere_of_influence.m`, values precomputed in `constants_curtis.m` (e.g. Earth ~925,000 km, Jupiter ~48 million km).

### 4.2 What SOI means physically

Inside SOI, the planet’s gravity dominates the spacecraft’s two-body motion **relative to that planet**. Outside, the Sun dominates **heliocentric** motion.

The patch model **instantly switches** between frames at the boundary. Real trajectories blur this transition (weak Sun perturbation near SOI). Curtis §8.5 and exam quiz MA013: accuracy drops near borders.

### 4.3 Why this matters for the E–M–E–J mission

- **Launch:** Burn in Earth frame; emerge with \(v_\infty\) matching Lambert leg 1.
- **Mars:** Spacecraft arrives on Lambert arc; inside Mars SOI it is a hyperbola; after flyby, new heliocentric \(\mathbf{V}\).
- **Earth GA:** Same pattern; trailing flyby adds heliocentric speed toward Jupiter.
- **Jupiter capture:** Arrival \(v_\infty\) from Lambert leg 3; burn at Jupiter periapsis to become bound.

Each event is a **patch**: solve one two-body problem, transform velocity, move on.

---

## 5. Launch windows, phase angle, and synodic period

### 5.1 Phase angle — Eq. (8.7)

For coplanar circular orbits, the **phase angle** between two planets is the difference in their heliocentric longitudes:

\[
\phi = \theta_2 - \theta_1
\]

**Script:** `heliocentric_phase_angle.m` projects `planet_elements_and_sv` positions onto the ecliptic plane and takes `atan2` difference.

**Physical meaning:** At departure, Mars (or Jupiter) must lead or lag Earth by \(\phi\) so that after TOF \(t_{12}\) both spacecraft and target planet arrive at the same heliocentric location (for a transfer — approximately for Lambert with real eccentric orbits).

### 5.2 Hohmann phase angle — Eqs. (8.12)–(8.13)

For a **minimum-energy Hohmann** transfer from inner planet 1 to outer planet 2, the departure phase angle is:

\[
\phi_0 = \pi - n_2 t_{12}
\]

where \(n_2 = \sqrt{\mu_\odot/a_2^3}\) is the mean motion of the outer planet and \(t_{12} = \pi\sqrt{a_\text{trans}^3/\mu_\odot}\) is half the Hohmann ellipse period.

**Script:** In `exam_earth_mars_earth_jupiter.m`:

```matlab
phi_hoh = rad2deg(pi - nM * tof_EM * 86400);   % Eq. 8.12 ref
```

**Why print both \(\phi\) and \(\phi_\text{Hohmann}\)?**  
The exam TOF (243 d for E–M) is **not** the Hohmann TOF (~259 d). Actual \(\phi \approx 155.7°\) vs Hohmann reference \(\approx 52.7°\). That tells you the exam trajectory is a **faster, higher-energy** arc — not a textbook minimum-energy transfer.

### 5.3 Synodic period — Eq. (8.10)

If you miss a launch window, similar geometry recurs after the **synodic period**:

\[
T_\text{syn} = \frac{T_1 T_2}{|T_1 - T_2|}
\]

**Script:** `synodic_period.m` — used in `exam_mission_saturn_titan.m` and `plot_launch_window.m`.

**Exam note:** The E–M–E–J sheet fixes dates; you report synodic period only if discussing **launch window repeat** in a feasibility section, not for computing the given legs.

---

## 6. Hohmann transfer — the baseline Curtis starts with

### 6.1 Geometry — §8.2

Coplanar circular orbits at radii \(R_1 < R_2\). The transfer is half an ellipse with:

\[
a_\text{trans} = \frac{R_1 + R_2}{2}
\]

Two **tangential** impulsive burns:

1. At \(R_1\): speed up from \(V_1 = \sqrt{\mu_\odot/R_1}\) to transfer perihelion speed.
2. At \(R_2\): speed down from transfer aphelion speed to \(V_2 = \sqrt{\mu_\odot/R_2}\).

**Properties:**

- Minimum **total \(\Delta v\)** for a two-impulse coplanar transfer (exam Q10).
- **Not** minimum time (Q10 C is false).
- TOF = half the transfer ellipse period.

**Script:** `hohmann_interplanetary.m` — used in `problem_8_1.m` (Earth–Saturn, book answer 15.74 km/s heliocentric) and `example_8_4.m` (Earth–Mars).

### 6.2 What Hohmann gives you vs what it does not

| Hohmann gives | Hohmann does **not** give |
|-------------|---------------------------|
| Minimum-energy template | Correct positions on **arbitrary calendar dates** |
| Reference TOF and \(\phi_0\) | Mars/Earth flyby targeting |
| Prob. 8.1 style answers | Fixed exam timeline legs |

**Why we still teach it first:** It builds intuition for \(v_\infty\), phase angle, and how much energy interplanetary flight needs before adding Lambert and flybys.

---

## 7. Why the exam uses Lambert, not Hohmann

### 7.1 The constraint is different

**Hohmann problem:** “Go from planet 1 to planet 2 with minimum \(\Delta v\).”  
**Lambert problem:** “Given \(\mathbf{R}_1\) at time \(t_1\), \(\mathbf{R}_2\) at time \(t_2\), find the conic about the central body that connects them in time \(\Delta t\).”

The exam says:

- Earth at position A on 2026-12-01.
- Mars at position B on 2027-08-01.

Those positions come from **real ephemeris** (eccentric, inclined orbits). The TOF is 243 days because that is what the calendar says — not because it equals \(\pi\sqrt{a^3/\mu}\) for a Hohmann ellipse.

### 7.2 Physical consequence

Shorter TOF than Hohmann (243 d vs ~259 d for E–M) generally means:

- Higher transfer orbit energy.
- Larger departure \(v_\infty\) and C3.
- Different phase angle \(\phi\).

You see exactly that: \(v_\infty \approx 4.31\ \text{km/s}\), C3 \(\approx 18.6\), while Hohmann Earth–Mars would be lower (~2.94 km/s in Ex. 8.4).

### 7.3 Curtis placement

- Lambert solver: **§5.3, Algorithm 5.2** (universal variables).
- Interplanetary application: **§8.11, Algorithm 8.2** (`interplanetary_lambert.m`).

---

## 8. Lambert’s problem — the physics and the code

### 8.1 Statement

Find velocities \(\mathbf{V}_1\), \(\mathbf{V}_2\) such that a body in gravity field \(\mu\) leaving \(\mathbf{R}_1\) at \(t=0\) arrives at \(\mathbf{R}_2\) at \(t = \Delta t\).

There are generally **two** solutions (short way / long way) and for some \((\mathbf{R}_1, \mathbf{R}_2, \Delta t)\) **no** real solution (TOF below minimum energy).

### 8.2 Universal variable formulation — Alg. 5.2

Curtis uses Stumpff functions \(C(z)\), \(S(z)\) and iterates on \(z\) until the time equation matches \(\Delta t\). This works for elliptic, parabolic, and hyperbolic cases in one framework.

**Script:** `lambert_universal.m` — low-level solver. Inputs: \(\mathbf{R}_1, \mathbf{R}_2\), \(\Delta t\) in seconds, \(\mu\), prograde/retrograde flag.

### 8.3 Prograde vs retrograde

For a given pair of radius vectors, the transfer can go the **short way** (prograde, typically < 180° sweep) or **long way** (retrograde). `interplanetary_lambert.m` tries both and picks the solution with **lower departure** \(v_\infty\) — a common launch-cost heuristic.

### 8.4 From Lambert to \(v_\infty\)

Algorithm 8.2 steps:

1. Get \(\mathbf{R}_1, \mathbf{V}_{p1}\) at departure planet (`planet_elements_and_sv`).
2. Get \(\mathbf{R}_2, \mathbf{V}_{p2}\) at arrival planet.
3. Solve Lambert: \(\mathbf{V}_1, \mathbf{V}_2\) = spacecraft heliocentric velocities on the transfer.
4. Hyperbolic excess at departure:

\[
\mathbf{v}_{\infty,\text{dep}} = \mathbf{V}_1 - \mathbf{V}_{p1}, \quad
v_{\infty,\text{dep}} = \|\mathbf{v}_{\infty,\text{dep}}\|
\]

5. Same at arrival with \(\mathbf{V}_2 - \mathbf{V}_{p2}\).

**Outputs used later:**

| Field | Used for |
|-------|----------|
| `v_inf_dep` | LEO escape (`multiburn_leo_escape`) |
| `V_arr` | Flyby input velocity (`flyby_patch`) |
| `V2_planet` | Planet velocity at encounter |
| `R1`, `V_dep` | Asteroid belt orbit determination |

### 8.5 Porkchop plots — §8.11

When departure date **and** TOF are free, you scan a grid and contour C3 = \(v_\infty^2\). Minimum-C3 regions are launch windows. Plots are **not symmetric** in time (planets move — exam Q9 D is false).

**Script:** `plot_launch_window.m` — optional, slow scan.

---

## 9. Where the planets are — Algorithm 8.1

### 9.1 Why Table A.1 alone is not enough

Table A.1 gives mean orbital radii and periods for circular approximations. Real planets have:

- Eccentricity \(e\)
- Inclination \(i\)
- Longitude of perihelion, node, mean longitude — all slowly varying

For a **dated** mission, Mars on 2027-08-01 is not at the same heliocentric angle as a circular mean model would predict.

### 9.2 Algorithm 8.1 steps (Curtis §8.10)

1. Convert calendar date to **Julian day** (`julian_day.m`, Ch. 5).
2. Compute centuries from J2000: \(T_0 = (JD - 2451545)/36525\).
3. Linearly update orbital elements from **Table 8.1** rates.
4. Solve Kepler’s equation \(M = E - e\sin E\) for eccentric anomaly \(E\) (`kepler_E.m`).
5. True anomaly \(\theta\) from \(E\).
6. Build heliocentric ecliptic \(\mathbf{R}, \mathbf{V}\) via **Algorithm 4.5** (`heliocentric_coe_to_sv.m`).

**Script chain:** `planet_elements_and_sv.m` wraps all of this.

### 9.3 Frame choice

Ch. 8 uses the **heliocentric ecliptic** frame. Inclinations from Table 8.1 are small for the inner planets; the exam scripts treat transfers as **coplanar in the ecliptic** for \(\Delta v\) even though Alg. 8.1 returns full 3D vectors. Mention this as a limitation in the report.

---

## 10. Leaving Earth — parking orbit, hyperbola, and C3

### 10.1 The patched-conic departure picture — §8.6

Sequence:

1. Spacecraft orbits Earth in a **circular parking orbit** at radius \(r_p = R_\Earth + 300\ \text{km}\).
2. Impulsive burn(s) raise energy until at perigee the speed matches the **departure hyperbola** that has the required \(v_\infty\) relative to Earth.
3. Coast to Earth SOI; outside, the heliocentric velocity must match Lambert \(\mathbf{V}_1\) from leg 1.

Earth moves at ~29.8 km/s heliocentric. The vector sum \(\mathbf{V}_\text{sc} = \mathbf{V}_\Earth + \mathbf{v}_\infty\) sets the actual departure direction (launch azimuth / asymptote — Curtis discusses departure cones in §8.6).

### 10.2 Single-burn escape — Eq. (8.42)

Minimum one-impulse solution from circular parking:

\[
v_p = \sqrt{v_\infty^2 + \frac{2\mu}{r_p}}, \quad
\Delta v = v_p - v_\text{circ}
\]

**Script:** `departure_dv.m` — `example_8_4.m` compares to book (Mars Hohmann, \(\Delta v \approx 3.59\ \text{km/s}\)).

### 10.3 Why the exam uses three burns — Task 1

The exam asks for **at least three apogee-raising manoeuvres** before escape. This is Chapter 6 logic:

- **Prograde burn at perigee** increases energy and raises **apogee** without changing perigee radius.
- Each intermediate orbit is an ellipse with the same \(r_p\) and larger \(r_a\).
- After two raises (apogees 120,000 km and 800,000 km in the script), a third burn at perigee brings speed to escape hyperbola speed.

**Vis-viva at perigee** for ellipse with semi-major axis \(a = (r_p + r_a)/2\):

\[
v_p = \sqrt{\frac{2\mu}{r_p} - \frac{\mu}{a}}
\]

Each burn increment: \(\Delta v_i = v_{p,i} - v_{p,i-1}\).

Final burn uses Eq. (8.40) with \(v_\infty\) from **Lambert leg 1**, not Hohmann:

\[
v_{p,\text{esc}} = \sqrt{v_\infty^2 + \frac{2\mu}{r_p}}
\]

**Script:** `multiburn_leo_escape.m`

**Why compute leg 1 before Task 1 in the script?**  
The required \(v_\infty\) is whatever the **actual** Earth–Mars transfer demands. A Hohmann value would under- or over-estimate launch \(\Delta v\).

**Typical result:** Total ~4.02 km/s for three burns vs ~3.59 km/s single-burn to Hohmann Mars — because Lambert leg 1 needs more energy than Hohmann.

### 10.4 Why not low-thrust spiral?

Electric propulsion can raise energy continuously with high \(I_\text{sp}\) but low thrust. Patched conics and impulsive \(\Delta v\) sums **do not** model that (exam Q13 C: patched conics not good for low-thrust).

---

## 11. Gravity assist — free heliocentric energy

### 11.1 The central trick — §8.9

In the **planet’s frame**, gravity is a central force. With no propulsion during flyby:

\[
|v_{\infty,\text{in}}| = |v_{\infty,\text{out}}|
\]

Only the **direction** of \(v_\infty\) changes. Speed relative to the planet is unchanged.

In the **Sun’s frame**, the planet itself moves at \(V_p \sim\) tens of km/s. Rotating \(v_\infty\) and re-adding \(V_p\) changes the spacecraft’s heliocentric velocity magnitude — sometimes by several km/s **without fuel**.

That is a **gravity assist** (slingshot).

### 11.2 Turn angle — Eq. (8.54)

Hyperbola periapsis \(r_p\), eccentricity:

\[
e = 1 + \frac{r_p v_\infty^2}{\mu}
\]

Turn angle (deflection of \(v_\infty\) vector):

\[
\delta = 2\arcsin\left(\frac{1}{e}\right)
\]

**Closer flyby** (smaller \(r_p\)) → larger \(\delta\).

**Scripts:** `flyby_delta.m` (scalar); full vector rotation in `flyby_patch.m`.

### 11.3 Leading vs trailing — Figs. 8.18–8.19

The sign of the heliocentric energy change depends on which side of the planet you pass relative to its motion around the Sun.

| Geometry | Effect on heliocentric speed (typical) | E–M–E–J use |
|----------|----------------------------------------|-------------|
| **Leading** side | Component opposite planet motion → **lose** heliocentric energy | Mars (`leading = true`) |
| **Trailing** side | Component along planet motion → **gain** heliocentric energy | Earth (`leading = false`), Cassini-class |

**Script:** `flyby_patch(..., leading)` picks rotation sign via Rodrigues’ formula about \(\hat{k} \parallel \mathbf{v}_\infty \times \mathbf{V}_p\).

### 11.4 What `flyby_patch` computes

Inputs:

- \(\mathbf{V}_p\) — planet heliocentric velocity at encounter.
- \(\mathbf{V}_\text{in}\) — spacecraft heliocentric velocity **before** flyby (from Lambert `V_arr`).
- \(r_p\) — flyby periapsis radius (Mars: \(R + 500\) km; Earth: \(R + 1000\) km).
- \(\mu\) — planet gravitational parameter.

Steps:

1. \(\mathbf{v}_{\infty,\text{in}} = \mathbf{V}_\text{in} - \mathbf{V}_p\)
2. \(e\), \(\delta\) from Eq. (8.54)
3. Rotate \(\mathbf{v}_{\infty,\text{in}}\) by \(\pm\delta\) in the appropriate plane
4. \(\mathbf{V}_\text{out} = \mathbf{V}_p + \mathbf{v}_{\infty,\text{out}}\)
5. Report \(\Delta V_\odot = \|\mathbf{V}_\text{out} - \mathbf{V}_\text{in}\|\)

**Not propulsive.** Budget line item = 0 fuel; report as “heliocentric gain.”

### 11.5 Typical E–M–E–J flyby results

| Flyby | \(r_p\) | \(\delta\) | \(\Delta V_\odot\) |
|-------|---------|------------|-------------------|
| Mars | 3896 km | ~63° | ~3.31 km/s |
| Earth | 7378 km | ~66° | ~7.32 km/s |

Earth trailing GA is the **main** reason Jupiter arrival \(v_\infty\) can be moderate (~5.76 km/s) despite a long outbound leg.

### 11.6 What Curtis adds that we simplify

Full §8.9 uses **aim angle** \(\phi_1\) and **periapsis argument** in the approach b-plane. `flyby_patch` rotates in the plane of \(\mathbf{v}_\infty\) and \(\mathbf{V}_p\) — enough for exam magnitude and direction discussion, not for JPL targeting.

---

## 12. Arriving at Jupiter — capture hyperbola

### 12.1 Arrival state

Lambert leg 3 gives \(v_{\infty,\text{arr}}\) at Jupiter SOI (~5.76 km/s in the default run). Relative to Jupiter, the spacecraft approaches on a hyperbola.

### 12.2 Capture burn — Eq. (8.60)

At periapsis radius \(r_p\) (Jupiter cloud tops + altitude in script: \(R_J + 100{,}000\) km):

Hyperbolic speed at periapsis:

\[
v_\text{hyp} = \sqrt{v_\infty^2 + \frac{2\mu}{r_p}}
\]

Target circular speed at capture (eccentricity \(e_\text{cap} = 0\)):

\[
v_\text{circ} = \sqrt{\frac{\mu}{r_p}}
\]

**Capture \(\Delta v\):**

\[
\Delta v_\text{cap} = v_\text{hyp} - v_\text{circ}
\]

**Script:** `capture_dv.m`

**Why capture dominates the budget (~11.7 km/s of ~15.8 km/s total):** Jupiter’s \(\mu\) is large and the parking orbit is deep in the well. Slowing from hyperbolic to circular at 171,492 km radius costs much more than Earth escape.

### 12.3 Elliptic capture

If `e_cap > 0`, target speed is \(\sqrt{\mu/r_p \cdot (1 + e_\text{cap})}\) at periapsis — useful if the exam asks for a **highly elliptical capture** instead of circular parking.

---

## 13. Full E–M–E–J mission, event by event

This section ties every exam task to physics, Curtis section, and script line.

### Event 0 — Timeline

```
2026-12-01  Earth departure
    |  243 d  (leg 1, Lambert, Sun-centred)
2027-08-01  Mars flyby
    |  488 d  (leg 2)
2028-12-01  Earth flyby
    | 1004 d  (leg 3)
2031-09-01  Jupiter capture
```

Total: 1735 d ≈ 4.75 yr. Script: `days_between.m`.

---

### Task 2 (computed first in script) — Earth → Mars

**Physics:** Sun-centred Lambert arc connecting Earth’s position on 2026-12-01 to Mars’s position on 2027-08-01 in 243 days.

**Curtis:** Alg. 8.1 (positions) + Alg. 8.2 (Lambert) + Eq. (8.7) (phase angle).

**Script:**

```matlab
leg1 = interplanetary_lambert('earth', t0, 'mars', tM, tof_EM);
phi = heliocentric_phase_angle(R_E, R_M);
```

**Key outputs:**

- \(v_{\infty,\Earth} \approx 4.31\ \text{km/s}\) → C3 ≈ 18.6
- \(v_{\infty,\Mars} \approx 3.18\ \text{km/s}\) at Mars arrival (before flyby)
- \(\phi \approx 155.7°\) vs Hohmann ref ~52.7°

**Interpretation:** Fast transfer; launch energy well above Hohmann Earth–Mars (Ex. 8.4).

---

### Task 1 — Earth escape (three burns)

**Physics:** Raise energy in Earth SOI until perigee speed matches departure hyperbola for leg-1 \(v_\infty\).

**Curtis:** §8.6, Eq. (8.40); Ch. 6 perigee-burn logic.

**Script:** `multiburn_leo_escape(leg1.v_inf_dep, c.earth.mu, rp, Ra1, Ra2)`

**Key outputs:** Three burns ~2.91 + 0.25 + 0.86 km/s; total ~4.02 km/s.

**Report wording:** “Required \(v_\infty\) taken from Lambert leg 1, not Hohmann, because exam dates fix TOF and endpoints.”

---

### Task 3 — Mars gravity assist

**Physics:** Hyperbolic flyby at Mars; rotate \(v_\infty\); leading-side pass.

**Curtis:** §8.9, Eq. (8.54).

**Script:**

```matlab
fbM = flyby_patch(leg1.V2_planet, leg1.V_arr, rpM, c.mars.mu, true);
```

**Key outputs:** \(\delta \approx 63°\), \(e \approx 1.92\), \(\Delta V_\odot \approx 3.31\ \text{km/s}\) (heliocentric, not fuel).

**Note:** In a fully consistent patch, \(\mathbf{V}_\text{out}\) would start leg 2. Our script computes leg 2 independently from Mars/Earth positions on the exam dates — acceptable for the exam if you state the limitation (§16).

---

### Task 4 — Mars → Earth

**Physics:** Second Lambert arc, TOF 488 d (~1.34 yr). Long return from Mars to Earth.

**Script:** `interplanetary_lambert('mars', tM, 'earth', tE, tof_ME)`

**Key outputs:**

- \(v_{\infty,\Mars,\text{dep}} \approx 10.72\ \text{km/s}\) (high — different from post-flyby state if chained)
- \(v_{\infty,\Earth,\text{arr}} \approx 6.71\ \text{km/s}\) at Earth arrival
- \(\phi \approx -155.2°\)

---

### Task 5 — Earth gravity assist

**Physics:** Trailing-side Earth flyby to **gain** heliocentric speed toward Jupiter (Cassini Fig. 8.24 philosophy).

**Script:**

```matlab
fbE = flyby_patch(leg2.V2_planet, leg2.V_arr, rpE, c.earth.mu, false);
```

**Key outputs:** \(\delta \approx 66°\), \(\Delta V_\odot \approx 7.32\ \text{km/s}\).

**Why this matters:** Without Earth GA, direct Earth–Jupiter launch energy would be impractical for chemical propulsion. The assist trades **time** (extra flybys, 4.75 yr) for **launch mass**.

---

### Task 6 — Earth → Jupiter + capture

**Physics:** Third Lambert leg, TOF 1004 d (~2.75 yr). Arrival hyperbola at Jupiter; impulsive capture.

**Script:**

```matlab
leg3 = interplanetary_lambert('earth', tE, 'jupiter', tJ, tof_EJ);
dv_cap = capture_dv(leg3.v_inf_arr, c.jupiter.mu, rpJ, 0);
```

**Key outputs:**

- \(v_{\infty,\text{dep}} \approx 10.02\ \text{km/s}\), \(v_{\infty,\text{arr}} \approx 5.76\ \text{km/s}\)
- Capture \(\Delta v \approx 11.69\ \text{km/s}\)

---

### Task 7 — Asteroid belt

**Physics:** Not a numbered Curtis section — engineering assessment. The E–J Lambert orbit has perihelion ~0.96 AU and aphelion ~5.26 AU, so it sweeps through the main belt (2.1–3.3 AU).

**Method:** From departure \(\mathbf{R}_1, \mathbf{V}_1\) on leg 3, compute orbital energy and eccentricity vector → \(r_p\), \(r_a\) → check interval overlap.

**Script:** `asteroid_belt_crossing.m`

**Mitigation (qualitative):** Small inclination change to avoid ecliptic plane dust; Whipple shield; TCM if tracking shows deflection risk.

---

## 14. Asteroid belt crossing

### 14.1 Orbit determination from state vector

Given \(\mathbf{r}, \mathbf{v}\) in the Sun’s field:

\[
\varepsilon = \frac{v^2}{2} - \frac{\mu_\odot}{r}
\]

\[
a = -\frac{\mu_\odot}{2\varepsilon}
\]

Eccentricity vector:

\[
\mathbf{e} = \frac{1}{\mu_\odot}\left[\left(v^2 - \frac{\mu_\odot}{r}\right)\mathbf{r} - (\mathbf{r}\cdot\mathbf{v})\mathbf{v}\right]
\]

Then \(e = \|\mathbf{e}\|\), and:

\[
r_p = a(1-e), \quad r_a = a(1+e)
\]

### 14.2 Belt overlap criterion

Main belt approximated as annulus 2.1–3.3 AU. Crosses if:

\[
r_p < 3.3\ \text{AU} \quad \text{and} \quad r_a > 2.1\ \text{AU}
\]

For our E–J leg: **yes**.

---

## 15. Building the Δv budget

### 15.1 Propulsive vs non-propulsive

| Manoeuvre | Propulsive? | Reason |
|-----------|-------------|--------|
| LEO escape burns | Yes | Chemical thrusters in Earth SOI |
| Mars / Earth flyby | **No** | \(\|v_\infty\|\) conserved in planet frame |
| TCM reserve | Yes | Small mid-course corrections (§8.7 sensitivity) |
| Jupiter capture | Yes | Braking at Jupiter |
| Jupiter → moon Hohmann | Yes (if added) | Planetocentric transfer |

Heliocentric “\(\Delta v\)” at SOI boundaries in a Hohmann analysis (Prob. 8.1) is a **kinematic** difference relative to planet’s circular speed — it is **already accounted for** in \(v_\infty\) when you compute launch and capture burns. Do not double-count.

### 15.2 Default E–M–E–J totals

| Item | km/s |
|------|------|
| LEO escape (3 burns) | 4.02 |
| TCM | 0.05 |
| Jupiter capture | 11.69 |
| **Total propulsive** | **~15.76** |

Report separately:

| GA | Heliocentric \(\Delta V\) |
|----|---------------------------|
| Mars | 3.31 |
| Earth | 7.32 |

### 15.3 Sensitivity — §8.7

Curtis notes launch and arrival geometry are sensitive to small errors. That motivates a **TCM reserve** (~50 m/s in the script). Flyby periapsis must be controlled — too low risks atmosphere/plasma; too high reduces \(\delta\).

---

## 16. What we simplify — and what to write in the exam

Copy these into your “Limitations” section:

1. **Patched conics** — no simultaneous Sun–Earth–Mars gravity (§8.5).
2. **Instant SOI transitions** — velocity transform is discontinuous at boundary.
3. **No flyby–leg chaining** — `V_out` from Mars/Earth GA is not fed into the next `interplanetary_lambert` solve; exam dates fix endpoints anyway.
4. **Coplanar ecliptic** — inclinations from Table 8.1 neglected in \(\Delta v\); `heliocentric_phase_angle` uses ecliptic projection only.
5. **Impulsive burns** — finite burn time and gravity loss near Earth not included.
6. **Three-burn apogees** — Ra₁, Ra₂ are design choices, not optimised.
7. **Flyby aim** — simplified rotation in `flyby_patch`; full b-plane targeting not implemented.

These are **features of the course model**, not bugs — but a good report names them.

---

## 17. Extending the physics — moons, extra flybys, iteration

### 17.1 Jupiter moon (planetocentric leg)

After Jupiter capture, the spacecraft is in a **Jupiter-centred** bound orbit. A moon (Europa, Ganymede, …) orbits Jupiter, not the Sun.

**Physics:** Coplanar circular Hohmann between parking radius \(r_1\) and moon orbital radius \(r_2\):

\[
\Delta v_\text{total} = |v_{t1} - v_1| + |v_2 - v_{t2}|
\]

with vis-viva at transfer periapsis/apoapsis (Ch. 6).

**Script:** `hohmann_planet(c.jupiter.mu, rpJ, r_moon)`

**Heliocentric legs unchanged.** Total propulsive rises to ~26–30 km/s depending on moon.

### 17.2 Saturn → Titan template

`exam_mission_saturn_titan.m` uses **Hohmann** for the interplanetary leg (free TOF, minimum energy) then the same capture + moon pattern. Compare:

- E–M–E–J: fixed dates → Lambert + flybys.
- Earth–Saturn–Titan: baseline energy → Hohmann + direct capture.

### 17.3 Extra gravity assist (e.g. Venus)

Insert `flyby_patch` at Venus between legs. Physics identical to Mars/Earth. Choose `leading` true/false depending on whether you need energy gain or loss for the next target.

### 17.4 Proper iteration (beyond exam)

Production design loops:

1. Lambert → flyby → check \(\mathbf{V}_\text{out}\) vs next leg required \(\mathbf{V}_\text{dep}\).
2. Adjust flyby \(r_p\) or aim angle until mismatch is below tolerance.
3. Repeat for full trajectory.

Curtis §8.9 and Cassini example (Fig. 8.24) describe this qualitatively; the exam script stops at one pass for clarity.

---

## 18. Equation and script index

### 18.1 Curtis equations → scripts

| Equation / Algorithm | Topic | Script |
|----------------------|-------|--------|
| Alg. 5.2 | Lambert universal | `lambert_universal.m` |
| Alg. 8.1 | Planet ephemeris | `planet_elements_and_sv.m` |
| Alg. 8.2 | Interplanetary Lambert | `interplanetary_lambert.m` |
| Eq. (8.7) | Phase angle | `heliocentric_phase_angle.m` |
| Eq. (8.10) | Synodic period | `synodic_period.m` |
| Eq. (8.12) | Hohmann phase | `hohmann_interplanetary.m`, exam ref line |
| §8.2 | Hohmann transfer | `hohmann_interplanetary.m` |
| Eq. (8.34) | SOI radius | `sphere_of_influence.m` |
| Eq. (8.40) / (8.42) | Departure hyperbola | `departure_dv.m`, `multiburn_leo_escape.m` |
| Eq. (8.54) | Flyby turn angle | `flyby_delta.m`, `flyby_patch.m` |
| Eq. (8.60) | Capture | `capture_dv.m` |
| Ch. 6 | Planet Hohmann | `hohmann_planet.m` |
| Eqs. (5.47)–(5.48) | Julian day | `julian_day.m` |

### 18.2 Exam tasks → scripts

| Task | Script(s) |
|------|-------------|
| Timeline / TOF | `days_between.m` |
| 1 — Earth escape | `multiburn_leo_escape.m` |
| 2 — E–M transfer | `interplanetary_lambert.m`, `planet_elements_and_sv.m`, `heliocentric_phase_angle.m` |
| 3 — Mars GA | `flyby_patch.m` |
| 4 — M–E transfer | `interplanetary_lambert.m` |
| 5 — Earth GA | `flyby_patch.m` |
| 6 — E–J + capture | `interplanetary_lambert.m`, `capture_dv.m` |
| 7 — Asteroid belt | `asteroid_belt_crossing.m` |
| Δv table | `exam_earth_mars_earth_jupiter.m` (fprintf block) |

### 18.3 Book verification scripts

| Script | Verifies |
|--------|----------|
| `example_8_4.m` | Ex. 8.4 Earth–Mars departure \(\Delta v\) |
| `problem_8_1.m` | Prob. 8.1 Earth–Saturn Hohmann total 15.74 km/s |
| `problem_8_12.m` | Prob. 8.12 Jupiter flyby \(\delta\) |

---

## Closing summary

The E–M–E–J mission is a **chain of two-body problems**:

1. **Calendar dates** fix TOFs and planet locations (Alg. 8.1).
2. **Lambert** solves Sun-centred transfers between those locations (Alg. 8.2).
3. **Launch** provides the \(v_\infty\) Lambert demands (Eq. 8.40, three-burn exam variant).
4. **Flybys** rotate \(v_\infty\) without fuel, changing heliocentric energy (§8.9).
5. **Capture** removes hyperbolic excess at Jupiter (Eq. 8.60).

The physics is classical orbital mechanics from Ch. 6–8; the scripts are a faithful Curtis-algorithm implementation with explicit exam simplifications. Name those simplifications in your report, and you have a complete feasibility narrative.

*For numbers only, see [`SUMMARY.md`](SUMMARY.md). For every file and extension recipe, see [`README.md`](README.md).*
