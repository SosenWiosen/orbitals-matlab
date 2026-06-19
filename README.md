# Mission design scripts — reference manual

Curtis *Orbital Mechanics for Engineering Students* (4th ed.), Chapters 5–8.  
Primary exam template: **Earth → Mars → Earth → Jupiter** (250-ST-2S-028).

**Quick reference:** [`SUMMARY.md`](SUMMARY.md) — one-page cheat sheet.  
**Physics walkthrough:** [`PHYSICS.md`](PHYSICS.md) — full Curtis-aligned theory.  
This file is the full script manual.

```matlab
cd matlab
setup                          % add utils/, interplanetary/, exercises/ to path
exam_earth_mars_earth_jupiter  % full E–M–E–J exam answer
```

---

## Table of contents

1. [Directory layout](#1-directory-layout)
2. [Quick workflow](#2-quick-workflow)
3. [Overall approach (patched conics)](#3-overall-approach-patched-conics)
4. [Extending the mission with other legs](#4-extending-the-mission-with-other-legs)
5. [E–M–E–J exam task map](#5-em-ej-exam-task-map)
6. [Complete script reference](#6-complete-script-reference)
7. [How scripts call each other](#7-how-scripts-call-each-other)
8. [Simplifications (say in the exam report)](#8-simplifications-say-in-the-exam-report)
9. [Δv budget rules](#9-δv-budget-rules)
10. [Curtis references](#10-curtis-references)

---

## 1. Directory layout

```
matlab/
├── setup.m                    % run once — adds folders to path
├── README.md                  % this file
│
├── interplanetary/            % Ch. 8 mission design (main exam code)
│   ├── exam_earth_mars_earth_jupiter.m   % E–M–E–J exam driver
│   ├── exam_mission_saturn_titan.m       % Saturn → Titan template
│   ├── exam_formulas_demo.m              % written-quiz numeric checks
│   ├── constants_curtis.m                % Table A.1 + Table 8.1
│   ├── interplanetary_lambert.m            % Alg. 8.2 wrapper
│   ├── lambert_universal.m                 % Alg. 5.2 solver
│   ├── planet_elements_and_sv.m            % Alg. 8.1 ephemeris
│   ├── heliocentric_coe_to_sv.m            % Alg. 4.5 (ecliptic frame)
│   ├── kepler_E.m                          % Kepler’s equation
│   ├── days_between.m                      % calendar TOF
│   ├── heliocentric_phase_angle.m          % Eq. 8.7
│   ├── hohmann_interplanetary.m            % Sec. 8.2 baseline
│   ├── hohmann_planet.m                    % Ch. 6 planetocentric Hohmann
│   ├── departure_dv.m                      % Eq. 8.42 single-burn escape
│   ├── multiburn_leo_escape.m              % three perigee burns + escape
│   ├── capture_dv.m                        % Eq. 8.60 arrival capture
│   ├── flyby_patch.m                       % Sec. 8.9 vector flyby
│   ├── soi_patch_dv.m                      % SOI burn to next Lambert leg
│   ├── propagate_twobody.m                 % Keplerian coast verification
│   ├── flyby_delta.m                       % Eq. 8.54 turn angle only
│   ├── asteroid_belt_crossing.m            % exam Task 7
│   ├── synodic_period.m                    % Eq. 8.10
│   ├── sphere_of_influence.m               % Eq. 8.34
│   ├── plot_launch_window.m                % optional porkchop
│   ├── example_8_4.m                       % verify Ex. 8.4
│   ├── problem_8_1.m                       % verify Prob. 8.1
│   └── problem_8_12.m                      % verify Prob. 8.12
│
├── utils/                     % Ch. 5 time / tracking (exam: only julian_day required)
│   ├── julian_day.m
│   ├── J0.m
│   ├── local_sidereal_time.m
│   ├── dms_to_deg.m
│   ├── wrap360.m
│   ├── observer_position.m
│   └── state_vector_from_tracking.m
│
└── exercises/                 % Ch. 5–7 homework scripts (not used in E–M–E–J exam)
    ├── Example_5_04.m
    ├── exercise_5_08.m … exercise_5_12.m
    ├── exercise_6_10.m
    └── exercise_7_2.m
```

---

## 2. Quick workflow

| Goal | Command |
|------|---------|
| Full E–M–E–J exam | `exam_earth_mars_earth_jupiter` |
| Saturn → Titan template | `exam_mission_saturn_titan` |
| Check book Ex. 8.4 | `example_8_4` |
| Check book Prob. 8.1 | `problem_8_1` |
| Check book Prob. 8.12 | `problem_8_12` |
| Written-quiz formulas | `exam_formulas_demo` |
| Porkchop plot (slow) | `plot_launch_window('earth','jupiter')` |

Always run `setup` first (or call it from inside exam scripts).

---

## 3. Overall approach (patched conics)

The exam gives **fixed flyby/arrival dates**. You cannot freely pick a Hohmann TOF — Mars must be there in Aug 2027, Earth in Dec 2028, Jupiter in Sep 2031.

Curtis **§8.5** splits the mission into three arc types:

1. **Inside a planet SOI** — Keplerian hyperbola (launch, flyby, capture).
2. **Between SOIs** — Keplerian conic about the **Sun**.
3. **At each SOI boundary** — match position; transform velocity (\(v_\infty\) relative to planet).

We never integrate full n-body equations. That is patched conics: good enough for feasibility studies, exactly what the course expects.

**Why Lambert instead of Hohmann?**  
Hohmann (§8.2) assumes coplanar circular orbits and a **specific** TOF (half the transfer ellipse period). Exam TOFs come from calendar dates (~243 d, ~488 d, ~1004 d). For each leg: given “planet A here on day 1, planet B there on day 2”, use **Lambert’s problem** (Alg. 5.2 / §8.11) to find the Sun-centred transfer and \(v_\infty\) at each end.

Hohmann is still used as a **reference** (Eq. 8.12 for \(\phi_0\)) to show how far the real geometry is from minimum energy.

### Mission timeline (E–M–E–J)

```
Dec 2026   LEAVE EARTH (3 burns from 300 km LEO)
    |
    |  heliocentric leg 1 (Lambert, ~243 d)
    v
Aug 2027   MARS FLYBY (gravity only)
    |
    |  heliocentric leg 2 (Lambert, ~488 d)
    v
Dec 2028   EARTH FLYBY (trailing — boost toward Jupiter)
    |
    |  heliocentric leg 3 (Lambert, ~1004 d)
    v
Sep 2031   JUPITER — capture burn
```

Gravity assists rotate \(v_\infty\) without fuel. **SOI patch burns** (`soi_patch_dv`) after each GA match the next Lambert departure — required because passive flybys cannot change \(|v_\infty|\) enough between legs.

---

## 4. Extending the mission with other legs

The E–M–E–J script is a **template**, not a closed box. Every new requirement is one more patched-conic leg. Use the patterns below.

### 4.1 Decision tree — what kind of leg?

```
New requirement                          Tool to add                    Budget line?
─────────────────────────────────────────────────────────────────────────────────
Different departure/arrival dates        Change epochs in exam script   (recalc all)
Different TOF on one heliocentric leg    days_between / new tof_days    Lambert v∞ changes
Target is a moon, not the planet         capture_dv + hohmann_planet    Yes (both burns)
Extra gravity assist (Venus, Jupiter…)   flyby_patch at that body       No (heliocentric ΔV)
Plane change at moon or parking orbit    2 v sin(Δi/2) by hand          Yes
Launch window study (free dates)         plot_launch_window             —
Different planet pair entirely           Copy exam script, new dates    —
Chain flyby output → next Lambert        Custom loop (see §4.6)         —
Science orbit (eccentric, not circular)  capture_dv(..., e_cap ≠ 0)     Yes
```

### 4.2 Add a Jupiter moon (Europa, Ganymede, …)

**Heliocentric part unchanged** (Tasks 1–6, GAs, asteroid belt). After Jupiter SOI arrival, add a **planetocentric Hohmann** — same pattern as Saturn → Titan in `exam_mission_saturn_titan.m`.

Galilean moon semi-major axes (km, J2000 approximate):

| Moon | \(a\) (km) |
|------|-----------|
| Io | 421,700 |
| Europa | 671,034 |
| Ganymede | 1,070,412 |
| Callisto | 1,882,709 |

Add after the Jupiter capture block in `exam_earth_mars_earth_jupiter.m`:

```matlab
%% 6b) Jupiter parking -> moon (Ch. 6 Hohmann)
r_moon = 671034;   % Europa — change for other targets
[dv_moon, dv_m1, dv_m2] = hohmann_planet(c.jupiter.mu, rpJ, r_moon);

fprintf('\n--- 6b) Jupiter -> Europa ---\n');
fprintf('Hohmann dv = %.3f km/s  (burn1=%.3f, burn2=%.3f)\n', dv_moon, dv_m1, dv_m2);

%% dv table (updated)
fprintf('Jupiter -> moon:       %.4f\n', dv_moon);
fprintf('TOTAL propulsive:      %.4f km/s\n', dv_leo + dv_tcm + dv_cap + dv_moon);
```

**Typical totals** (with current capture \(r_p = 171{,}492\) km, coplanar):

| Target | Extra Hohmann Δv | New total propulsive |
|--------|------------------|----------------------|
| Jupiter only | — | ~15.8 km/s |
| Io | ~9.4 km/s | ~25.1 km/s |
| Europa | ~12.1 km/s | ~27.9 km/s |
| Ganymede | ~13.7 km/s | ~29.4 km/s |
| Callisto | ~14.5 km/s | ~30.2 km/s |

**Exam report note:** Galilean moons are nearly coplanar with Jupiter (\(i \lesssim 0.5°\)). State “coplanar Hohmann; plane change negligible.” If given a large \(\Delta i\), add \(\Delta v = 2v\sin(\Delta i/2)\) at the moon transfer.

**Optional:** add moon constants to `constants_curtis.m`:

```matlab
c.europa.a = 671034;
c.europa.R = 1560.8;
```

(\(\mu\) of moons is only needed for low-orbit work, not for Hohmann between circular orbits about Jupiter.)

### 4.3 Add a Saturn moon leg (Titan / Enceladus)

Use `exam_mission_saturn_titan.m` as the starting point. It already chains:

1. Hohmann baseline Earth → Saturn (`hohmann_interplanetary`)
2. LEO escape (`departure_dv` — single burn; swap for `multiburn_leo_escape` if exam asks)
3. Saturn capture (`capture_dv`)
4. Saturn parking → Titan (`hohmann_planet`)

**Enceladus variant** — change one line:

```matlab
r_moon = c.enceladus.a;   % 238,020 km — already in constants_curtis
[dv_moon, ~, ~] = hohmann_planet(c.saturn.mu, rp_sat, r_moon);
```

Closer moon → lower Hohmann Δv, but science orbit may need extra inclination work.

### 4.4 Add an extra gravity-assist flyby

Pattern (same as Tasks 3 and 5):

```matlab
% After computing legK = interplanetary_lambert(...)
rp_V = c.venus.R + 300;   % flyby altitude — design choice
fbV = flyby_patch(legK.V2_planet, legK.V_arr, rp_V, c.venus.mu, true);
% leading = true  → energy loss (typical inner-planet outbound)
% leading = false → energy gain (trailing, like Earth GA toward Jupiter)

fprintf('Venus GA: delta=%.1f deg, dV_sun=%.3f km/s\n', fbV.delta_deg, fbV.dV_sun);
```

**Insert a new heliocentric leg** between two existing events:

1. Pick departure date \(t_A\) and flyby date \(t_B\).
2. `leg_new = interplanetary_lambert('earth', tA, 'venus', tB, days_between(tA,tB))`.
3. `fb = flyby_patch(leg_new.V2_planet, leg_new.V_arr, rp, mu, leading)`.
4. Next leg: `interplanetary_lambert('venus', tB, 'jupiter', tJ, days_between(tB,tJ))`.

**Budget:** flyby Δv is **not propulsive**. Report `fb.dV_sun` separately as “gravity assist gain.”

**Cassini-style chain** (discuss in report, Fig. 8.24): Venus ×2 → Earth → Jupiter → Saturn. Each inner flyby lowers launch C3; script quantifies one flyby at a time.

### 4.5 Change dates, parking altitudes, or burn strategy

| Parameter | Where to edit | Effect |
|-----------|---------------|--------|
| Mission dates | `t0`, `tM`, `tE`, `tJ` in exam script | All TOFs and Lambert solutions change |
| LEO altitude | `rp = c.earth.R + 300` | Escape Δv |
| Apogee heights | `Ra1`, `Ra2` in `multiburn_leo_escape` call | Split of 3-burn budget |
| Mars flyby altitude | `rpM = c.mars.R + 500` | Turn angle \(\delta\), `dV_sun` |
| Earth flyby altitude | `rpE = c.earth.R + 1000` | Turn angle, GA boost |
| Jupiter capture radius | `rpJ = c.jupiter.R + 100000` | Capture Δv vs moon-transfer Δv |
| TCM reserve | `dv_tcm = 0.05` | Report margin |
| Single-burn escape | Replace `multiburn_leo_escape` with `departure_dv` | Matches Ex. 8.4 style |

### 4.6 Chain flyby output into the next Lambert leg (proper iteration)

The exam script **does not** do this — it uses fixed calendar positions. For a more consistent patched-conics study:

```matlab
% After Mars flyby:
V_after_Mars = fbM.V_out;   % heliocentric velocity leaving Mars SOI

% Option A — report only: compare |V_after_Mars - leg2.V_dep| as mismatch
% Option B — iterate: adjust Mars flyby aim (phi_1 in Sec. 8.9) until
%            V_after_Mars matches Lambert departure for leg 2

% Option C — skip Lambert at Mars departure; coast with V_after_Mars
%            and propagate to Earth flyby date (not implemented here;
%            would need Kepler propagation about the Sun)
```

For the 2.5 h exam: **state the limitation** in §8.5 language and show both the Lambert leg and the GA analysis separately.

### 4.7 Add a plane-change manoeuvre

Not wrapped in a function — add by hand where needed:

```matlab
v = sqrt(c.jupiter.mu / r_moon);   % speed at moon orbit
di_deg = 5;                          % example inclination offset
dv_plane = 2 * v * sind(di_deg / 2);
```

Best done at an apsis (min \(v\)). Exam scripts assume coplanar ecliptic transfers.

### 4.8 Add launch-window / porkchop analysis

When dates are **free** (not the E–M–E–J exam):

```matlab
plot_launch_window('earth', 'jupiter')   % scans dep date vs TOF, plots C3
```

Slow (15×15 Lambert solves). Use for report figures, not during timed exam unless pre-computed.

### 4.9 Create a new exam script from scratch

1. Copy `exam_earth_mars_earth_jupiter.m` → `exam_my_mission.m`.
2. Define calendar epochs and compute `days_between` for each leg.
3. For each heliocentric leg: `interplanetary_lambert(planet1, dep, planet2, arr, tof)`.
4. For each flyby: `flyby_patch(V_planet, V_sc_in, rp, mu, leading)`.
5. For launch: `multiburn_leo_escape` or `departure_dv` using `leg1.v_inf_dep`.
6. For arrival: `capture_dv(v_inf_arr, mu_planet, rp, e_cap)`.
7. For moons: `hohmann_planet(mu_planet, rp_park, r_moon)`.
8. Sum propulsive lines; list GA gains separately.

### 4.10 Example — E–M–E–J with Europa orbiter

Minimal diff from current exam (conceptual budget):

| Phase | Δv (km/s) |
|-------|-----------|
| LEO escape (3 burns) | 4.02 |
| TCM | 0.05 |
| Jupiter capture | 11.69 |
| Jupiter → Europa Hohmann | 12.10 |
| **Total propulsive** | **~27.9** |
| Mars GA (heliocentric) | 3.31 (no fuel) |
| Earth GA (heliocentric) | 7.32 (no fuel) |

---

## 5. E–M–E–J exam task map

| Task | Script(s) | Curtis |
|------|-----------|--------|
| 1 — Earth escape (3 burns) | `multiburn_leo_escape` | §8.6, Eq. 8.40 |
| 2 — Earth–Mars Lambert | `interplanetary_lambert`, `planet_elements_and_sv`, `heliocentric_phase_angle` | Alg. 8.1–8.2, Eq. 8.7 |
| 3 — Mars GA | `flyby_patch(..., true)` | §8.9, Eq. 8.54 |
| 4 — Mars–Earth Lambert | same as Task 2 | Alg. 8.2 |
| 5 — Earth GA | `flyby_patch(..., false)` | §8.9, Fig. 8.19 |
| 6 — Earth–Jupiter + capture | `interplanetary_lambert`, `capture_dv` | §8.8, Eq. 8.60 |
| 7 — Asteroid belt | `asteroid_belt_crossing` | engineering (not numbered) |

### Task details (why each method)

**Task 1 — three apogee-raising burns**  
Exam asks for ≥3 manoeuvres from 300 km LEO. Each prograde burn at **perigee** raises apogee (Ch. 6). Final burn uses Eq. (8.40): \(v_p = \sqrt{v_\infty^2 + 2\mu/r_p}\). Required \(v_\infty\) comes from leg 1 Lambert, not Hohmann.

**Task 2 — Lambert not Hohmann**  
`planet_elements_and_sv` (Alg. 8.1) needs Table 8.1 + Julian date. Lambert returns \(v_\infty\) and C3 at each SOI. Hohmann \(\phi_0\) (Eq. 8.12) is printed as reference only.

**Task 3 — Mars leading flyby**  
In planet frame: \(|v_\infty|\) unchanged; turn \(\delta = 2\arcsin(1/e)\), \(e = 1 + r_p v_\infty^2/\mu\). In Sun frame: \(\mathbf{V}_\text{out} = \mathbf{V}_\text{planet} + \mathbf{v}_{\infty,\text{out}}\). Leading side → energy loss (typical inner flyby on outbound leg).

**Task 5 — Earth trailing flyby**  
Trailing side → positive component along Earth’s velocity → heliocentric speed-up toward Jupiter (Cassini-class).

**Task 6 — capture**  
`capture_dv`: hyperbolic speed at \(r_p\) minus circular (or elliptic if `e_cap ≠ 0`) capture speed.

**Task 7 — belt crossing**  
From departure \(\mathbf{R},\mathbf{V}\) on Lambert orbit: compute \(\varepsilon\), \(e\), \(r_p\), \(r_a\); check overlap with [2.1, 3.3] AU.

---

## 6. Complete script reference

Every `.m` file, what it does, inputs/outputs, and when to use it.

### 6.1 Root

#### `setup.m`
- **Purpose:** Add `utils/`, `interplanetary/`, `exercises/` to MATLAB path.
- **Usage:** `setup` once per session after `cd matlab`.
- **Inputs/outputs:** none.

---

### 6.2 Interplanetary — exam drivers

#### `exam_earth_mars_earth_jupiter.m`
- **Purpose:** Full AGH exam solution — E–M–E–J with fixed dates Dec 2026 → Sep 2031.
- **Usage:** `exam_earth_mars_earth_jupiter`
- **Does:** Lambert legs on fixed dates, passive flybys, **SOI patch burns** to chain legs, LEO escape, Jupiter capture, coast verification, Δv table.
- **Key outputs (printed):** TOFs, \(\phi\), \(v_\infty\), C3, flyby \(\delta\)/`dV_sun`, SOI patch Δv, capture Δv, total propulsive **~26.6 km/s** (patched).
- **Edit here to:** change dates, flyby radii, capture altitude, add moon leg (§4.2).

#### `exam_mission_saturn_titan.m`
- **Purpose:** Alternate exam template — Earth → Saturn → Titan (Hohmann baseline + capture + moon Hohmann).
- **Usage:** `exam_mission_saturn_titan`
- **Does:** Hohmann Δv, synodic period, LEO escape, Saturn capture, Titan transfer, SOI printout, optional Lambert comparison, GA discussion.
- **Book checks:** Prob. 8.1 total heliocentric Δv ≈ 15.74 km/s.

#### `exam_formulas_demo.m`
- **Purpose:** Numeric checks for written T/F exam (C3, escape fraction, plane change, etc.).
- **Usage:** `exam_formulas_demo`
- **Note:** calls `plane_change_delta_v` which is **not** in the repo — inline `2*v*sind(di/2)` if needed.

#### `example_8_4.m`
- **Purpose:** Verify Curtis Ex. 8.4 (Earth → Mars, single-burn escape from 300 km).
- **Book values:** \(v_\infty \approx 2.943\) km/s, \(\Delta v \approx 3.590\) km/s.

#### `problem_8_1.m`
- **Purpose:** Verify Prob. 8.1 Hohmann Earth → Saturn heliocentric Δv.
- **Book answer:** 15.74 km/s total.

#### `problem_8_12.m`
- **Purpose:** Jupiter flyby turn angle on Hohmann Earth approach.
- **Uses:** `flyby_delta` only; full vector ΔV needs `flyby_patch`.

---

### 6.3 Interplanetary — constants & ephemeris

#### `constants_curtis.m`
- **Purpose:** Load all planetary data from Curtis Table A.1 and Table 8.1.
- **Usage:** `c = constants_curtis()`
- **Returns struct `c` with fields:**
  - `c.AU`, `c.mu_sun`, `c.m_sun`
  - Per planet (`earth`, `mars`, …): `.R_orbit`, `.T`, `.m`, `.mu`, `.R`, `.r_soi`
  - `c.table81` — J2000 elements for Alg. 8.1
  - Moons: `c.titan`, `c.enceladus` (add Jupiter moons here if desired)
- **When:** Any script needing \(\mu\), radii, or orbital elements.

#### `planet_elements_and_sv.m`
- **Purpose:** Algorithm 8.1 — heliocentric \(\mathbf{R}, \mathbf{V}\) for a named planet at a calendar epoch.
- **Signature:** `[R, V, el] = planet_elements_and_sv(planet, year, month, day, hour, minute, second)`
- **`planet`:** `mercury` … `neptune` (lowercase string).
- **`el`:** struct with \(a, e, i, \Omega, \omega, \theta, h\).
- **Calls:** `julian_day`, `kepler_E`, `heliocentric_coe_to_sv`.
- **When:** Every dated interplanetary leg; flyby planet velocity.

#### `heliocentric_coe_to_sv.m`
- **Purpose:** Algorithm 4.5 — COE → state vector in **heliocentric ecliptic** frame.
- **Signature:** `[R, V] = heliocentric_coe_to_sv(h, e, RA, incl, w, theta, mu)`
- **Angles in degrees.** Used internally by Alg. 8.1.

#### `kepler_E.m`
- **Purpose:** Solve Kepler’s equation \(M = E - e\sin E\) by Newton iteration.
- **Signature:** `E = kepler_E(M, e)` — both in radians.
- **When:** Alg. 8.1 eccentric anomaly from mean anomaly.

---

### 6.4 Interplanetary — time

#### `days_between.m`
- **Purpose:** Calendar time difference in days between two `[y m d h min s]` epochs.
- **Signature:** `d = days_between(epoch1, epoch2)`
- **Calls:** `julian_day`.
- **When:** Exam TOFs from fixed dates.

---

### 6.5 Interplanetary — Lambert & transfers

#### `lambert_universal.m`
- **Purpose:** Algorithm 5.2 — universal-variable Lambert solver (Appendix D.11).
- **Signature:** `[V1, V2, extremal] = lambert_universal(R1, R2, dt, mu, direction)`
- **`R1, R2`:** 3×1 position vectors (km).
- **`dt`:** time of flight (seconds, positive).
- **`direction`:** `'prograde'` (default) or `'retrograde'`.
- **`extremal`:** true if on minimum-energy conic (short way).
- **When:** Core of all fixed-TOF transfers; usually called via `interplanetary_lambert`, not directly.

#### `interplanetary_lambert.m`
- **Purpose:** Algorithm 8.2 wrapper — planet names + dates + TOF → full leg struct.
- **Signature:** `out = interplanetary_lambert(planet1, dep, planet2, arr, tof_days)`
- **`dep`, `arr`:** `[year month day hour minute second]` UTC.
- **`arr`:** pass `[]` to auto-compute from `dep + tof_days`.
- **Logic:** Gets planet \(\mathbf{R},\mathbf{V}\) at both ends; tries prograde and retrograde Lambert; picks lower departure \(v_\infty\) (typical launch minimum).
- **Output struct fields:**

| Field | Meaning |
|-------|---------|
| `R1`, `R2` | Departure/arrival position (km) |
| `V1_planet`, `V2_planet` | Planet heliocentric velocities |
| `V_dep`, `V_arr` | Spacecraft heliocentric velocities on transfer |
| `v_inf_dep`, `v_inf_arr` | Speed of \(v_\infty\) at each SOI (km/s) |
| `v_inf_dep_vec`, `v_inf_arr_vec` | \(v_\infty\) vectors |
| `tof_days`, `dep`, `arr` | Metadata |

#### `hohmann_interplanetary.m`
- **Purpose:** Section 8.2 — coplanar circular Hohmann between two heliocentric radii.
- **Signature:** `out = hohmann_interplanetary(R1, R2, mu_sun, T1, T2)`
- **`R1`:** inner planet radius; **`R2`:** outer (must have `R2 ≥ R1`).
- **`T1, T2`:** optional orbital periods (days) for phase angles Eqs. (8.12)–(8.13).
- **Output:** `V_dep`, `V_arr`, `dv_dep`, `dv_arr`, `v_inf_dep`, `v_inf_arr`, `TOF_days`, `phi0_deg`, etc.
- **When:** Baselines (Prob. 8.1), reference φ, Ex. 8.4 — **not** for fixed-date exam legs.

#### `hohmann_planet.m`
- **Purpose:** Chapter 6 Hohmann between two **coplanar circular orbits about a planet**.
- **Signature:** `[dv1, dv2, dv_total] = hohmann_planet(mu, r1, r2)`
- **When:** Saturn → Titan, Jupiter → moon, parking → science orbit.

#### `heliocentric_phase_angle.m`
- **Purpose:** Eq. (8.7) — phase angle \(\phi = \theta_2 - \theta_1\) projected to ecliptic plane.
- **Signature:** `phi_deg = heliocentric_phase_angle(R1, R2)`
- **When:** Report φ on each Lambert leg; compare to Hohmann reference.

---

### 6.6 Interplanetary — launch, capture, flyby

#### `departure_dv.m`
- **Purpose:** Eq. (8.42) — **single** tangential burn from circular parking to escape hyperbola.
- **Signature:** `[dv, vp, vc, e, beta_deg] = departure_dv(v_inf, mu_planet, rp)`
- **When:** Ex. 8.4, Saturn template; compare total to `multiburn_leo_escape`.

#### `multiburn_leo_escape.m`
- **Purpose:** Three prograde perigee burns (two apogee-raises + escape) per exam Task 1.
- **Signature:** `[dv_total, dv] = multiburn_leo_escape(v_inf, mu, rp, Ra1, Ra2)`
- **`rp`:** perigee = parking orbit radius (km).
- **`Ra1`, `Ra2`:** first and second target apogees (km).
- **`dv`:** 3×1 vector of each burn.
- **Physics:** Each burn at perigee: \(v_p = \sqrt{2\mu/r_p - \mu/a}\); final burn to \(v_p = \sqrt{v_\infty^2 + 2\mu/r_p}\).

#### `capture_dv.m`
- **Purpose:** Eq. (8.60) — impulsive capture from arrival hyperbola to orbit at periapsis.
- **Signature:** `dv = capture_dv(v_inf, mu, rp, e_cap)`
- **`e_cap`:** eccentricity of capture orbit (0 = circular).
- **Formula:** \(v_\text{hyp} = \sqrt{v_\infty^2 + 2\mu/r_p}\); \(v_\text{cap} = \sqrt{\mu/r_p(1+e_\text{cap})}\); \(\Delta v = v_\text{hyp} - v_\text{cap}\).

#### `propagate_twobody.m`
- **Purpose:** Keplerian coast — propagate \(\mathbf{R}, \mathbf{V}\) forward by \(\Delta t\) about a central body.
- **Signature:** `[R, V] = propagate_twobody(R0, V0, dt, mu)`
- **When:** Verify Lambert leg closure after SOI patch; chained coast analysis.

#### `soi_patch_dv.m`
- **Purpose:** Impulsive burn at planet SOI to match next Lambert departure velocity after a passive flyby.
- **Signature:** `patch = soi_patch_dv(V_before, V_after, V_planet)`
- **Returns:** `patch.dv`, `patch.v_inf_gap` (planet-frame \(|v_\infty|\) mismatch).

#### `flyby_patch.m`
- **Purpose:** Section 8.9 — full vector gravity assist in patched conics.
- **Signature:** `fb = flyby_patch(Vp, Vin, rp, mu, leading)`
- **`Vp`:** planet heliocentric velocity (3×1).
- **`Vin`:** spacecraft heliocentric velocity **before** flyby (3×1).
- **`leading`:** `true` = leading-side (energy loss tendency); `false` = trailing-side (gain).
- **Method:** Compute \(v_{\infty,\text{in}} = V_\text{in} - V_p\); turn by \(\delta = 2\arcsin(1/e)\) about axis \(\hat{k} \propto v_{\infty,\text{in}} \times V_p\); add back \(V_p\).
- **Output:**

| Field | Meaning |
|-------|---------|
| `v_inf` | Hyperbolic excess speed in planet frame |
| `delta_deg` | Turn angle |
| `e` | Flyby hyperbola eccentricity |
| `V_out` | Heliocentric velocity after flyby |
| `v_inf_out` | Outgoing \(\|v_\infty\|\) in planet frame (equals `v_inf` for passive GA) |
| `dV_sun` | \(\|V_\text{out} - V_\text{in}\|\) — heliocentric speed change (not propulsive) |

#### `flyby_delta.m`
- **Purpose:** Eq. (8.54) only — turn angle and \(e\), no vectors.
- **Signature:** `[delta_deg, e] = flyby_delta(rp, v_inf, mu)`
- **When:** Prob. 8.12, quick what-if on flyby altitude.

---

### 6.7 Interplanetary — analysis & plotting

#### `asteroid_belt_crossing.m`
- **Purpose:** Exam Task 7 — does a transfer orbit intersect 2.1–3.3 AU?
- **Signature:** `belt = asteroid_belt_crossing(R1, V1, R2, V2, mu_sun, AU)`
- **Method:** From departure state, compute \(\varepsilon\), \(e\), \(r_p\), \(r_a\); test interval overlap.
- **Output:** `crosses` (logical), `rp_AU`, `ra_AU`, `depth_AU`, etc.

#### `synodic_period.m`
- **Purpose:** Eq. (8.10) — launch-window repeat interval.
- **Signature:** `T_syn = synodic_period(T1, T2)` — periods in days.

#### `sphere_of_influence.m`
- **Purpose:** Eq. (8.34) — patched-conics SOI radius.
- **Signature:** `r_soi = sphere_of_influence(a_orbit, m_planet, m_central)`

#### `plot_launch_window.m`
- **Purpose:** Optional porkchop — contour of C3 vs departure offset and TOF.
- **Signature:** `plot_launch_window(planet1, planet2)`
- **Warning:** Slow (225 Lambert solves default grid). Pre-run for reports.

---

### 6.8 Utils — Chapter 5 (time & tracking)

#### `julian_day.m`
- **Purpose:** Julian date from calendar epoch (Eqs. 5.47–5.48).
- **Signature:** `jd = julian_day(year, month, day, hour, minute, second)`
- **Required for:** Alg. 8.1, `days_between`. **Only utils function needed for Ch. 8 exams.**

#### `J0.m`
- **Purpose:** Julian day at 0 h UT on a date (Eq. 5.48).
- **Signature:** `j0 = J0(year, month, day)`

#### `local_sidereal_time.m`
- **Purpose:** Algorithm 5.3 — local sidereal time (degrees).
- **Signature:** `theta = local_sidereal_time(year, month, day, ut_hours, east_longitude_deg)`

#### `dms_to_deg.m`
- **Purpose:** DMS → decimal degrees with E/W/N/S sign.
- **Signature:** `deg = dms_to_deg(degrees, minutes, seconds, hemisphere)`

#### `wrap360.m`
- **Purpose:** Angle mod to \([0, 360)\) degrees.

#### `observer_position.m`
- **Purpose:** Eq. (5.56) — geocentric position of a ground station.

#### `state_vector_from_tracking.m`
- **Purpose:** Algorithm 5.4 — \(\mathbf{r}, \mathbf{v}\) from azimuth/elevation/range tracking data.

---

### 6.9 Exercises — homework (Ch. 5–7)

Not used in the E–M–E–J exam chain. Run individually for problem-set verification.

| Script | Curtis problem | Topic |
|--------|----------------|-------|
| `Example_5_04.m` | Ex. 5.4 | Julian day |
| `exercise_5_08.m` | Prob. 5.8 | Julian day table |
| `exercise_5_09.m` | — | Personal JD demo |
| `exercise_5_10.m` | Prob. 5.10 | Local sidereal time |
| `exercise_5_12.m` | Prob. 5.12 | Alg. 5.4 tracking → state vector |
| `exercise_6_10.m` | Prob. 6.10 | Hohmann / phasing (manual calc) |
| `exercise_7_2.m` | Prob. 7.2 | Fragment (incomplete) |

---

## 7. How scripts call each other

```
exam_earth_mars_earth_jupiter
│
├─ setup
├─ constants_curtis ─────────────────────────────┐
│                                                 │
├─ days_between ──► julian_day                    │
│                                                 │
├─ interplanetary_lambert (×3 legs)               │
│   ├─ planet_elements_and_sv                     │
│   │   ├─ julian_day                             │
│   │   ├─ kepler_E                               │
│   │   └─ heliocentric_coe_to_sv                 │
│   └─ lambert_universal                          │
│                                                 │
├─ heliocentric_phase_angle                       │
├─ multiburn_leo_escape                           │
├─ flyby_patch (×2)                               │
├─ soi_patch_dv (×2)                              │
├─ propagate_twobody (coast verify)               │
├─ capture_dv                                     │
└─ asteroid_belt_crossing                         │
                                                  │
exam_mission_saturn_titan ────────────────────────┤
├─ hohmann_interplanetary                         │
├─ synodic_period                                 │
├─ departure_dv                                   │
├─ capture_dv                                     │
├─ hohmann_planet                                 │
└─ interplanetary_lambert (optional Lambert cmp)  │
                                                  │
plot_launch_window ───────────────────────────────┘
└─ interplanetary_lambert (many calls)
```

**Data flow for one heliocentric leg:**

```
Calendar dates  →  days_between  →  TOF
                         ↓
              planet_elements_and_sv(dep)  →  R1, V_planet1
              planet_elements_and_sv(arr)  →  R2, V_planet2
                         ↓
              lambert_universal(R1, R2, TOF, μ_sun)  →  V_dep, V_arr
                         ↓
              v_inf = |V_sc - V_planet|  at each end
```

**Data flow for a flyby:**

```
Lambert V_arr (heliocentric)  +  planet V  →  flyby_patch
                         ↓
              v_inf in planet frame  →  turn δ  →  V_out
                         ↓
              dV_sun = |V_out - V_in|   (report, not propulsive)
```

---

## 8. Simplifications (say in the exam report)

1. **SOI patch burns** — after each passive GA, an impulsive burn matches the next Lambert `V_dep` (`soi_patch_dv`). Without these, \(|v_\infty|\) gaps total ~10.9 km/s.
2. **Coplanar ecliptic** — all vectors effectively in the ecliptic plane; Table 8.1 inclinations neglected for Δv.
3. **Instant SOI switch** — velocity transform at boundary; real n-body effects near SOI edges are weak (§8.5).
4. **Three-burn LEO** — apogee heights `Ra1`, `Ra2` are design choices, not optimized.
5. **Flyby aim angle** — `flyby_patch` rotates \(v_\infty\) in the plane of \(v_\infty\) and \(V_\text{planet}\); full §8.9 uses \(\phi_1, \alpha_1\) from approach trajectory.
6. **Moon transfers** — coplanar circular Hohmann only; no low-thrust, no CRTBP.

---

## 9. Δv budget rules

| Item | Propulsive? | Notes |
|------|-------------|-------|
| LEO escape (1 or 3 burns) | **Yes** | Chemical |
| Mars / Earth SOI patch | **Yes** | Bridge flyby exit → next Lambert `V_dep` |
| Mars / Earth GA rotation | **No** | Passive; `\|v∞\|` unchanged in planet frame |
| TCM reserve | **Yes** | §8.7 sensitivity |
| Planet capture | **Yes** | Hyperbola → orbit |
| Planet → moon Hohmann | **Yes** | Two burns about planet |
| Plane change | **Yes** | If included |

GA `dV_sun` values are **heliocentric speed change** from rotation, not fuel.

**Patched E–M–E–J total:** ~26.6 km/s (includes SOI patches).  
**Launch + capture only:** ~15.8 km/s (not flyby-compatible).  
**With Europa:** add ~12 km/s Hohmann after capture.

---

## 10. Curtis references

| Topic | Where in Curtis |
|-------|-----------------|
| Patched conics | §8.5 |
| Hohmann baseline | §8.2 |
| Phase angle, synodic | §8.3, Eqs. (8.7)–(8.10) |
| Departure hyperbola | §8.6, Eqs. (8.38)–(8.42) |
| Arrival / capture | §8.8, Eq. (8.60) |
| Flyby / GA | §8.9, Eqs. (8.52)–(8.74), Cassini Fig. 8.24 |
| Planet ephemeris | §8.10, Alg. 8.1, Table 8.1 |
| Lambert transfers | §8.11, Alg. 8.2 |
| Lambert solver | §5.3, Alg. 5.2 |
| Julian day | §5.4, Eqs. (5.47)–(5.48) |
| Planetocentric Hohmann | Ch. 6 |

---

*One-line reminder:* **dates → Alg. 8.1 positions → Lambert legs → \(v_\infty\) for launch → flybys for free heliocentric ΔV → capture at planet → (optional) Hohmann to moon.**
