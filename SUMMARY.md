# Mission design — short summary

Curtis Ch. 8 patched-conic scripts for the **Earth → Mars → Earth → Jupiter** exam.

| Doc | Purpose |
|-----|---------|
| [`PHYSICS.md`](PHYSICS.md) | Full physics walkthrough (Curtis + why each step) |
| [`README.md`](README.md) | Script reference and extension recipes |

```matlab
cd matlab
setup
exam_earth_mars_earth_jupiter
```

---

## E–M–E–J timeline

| Event | Date | Leg TOF |
|-------|------|---------|
| Earth departure | 2026-12-01 | — |
| Mars flyby | 2027-08-01 | 243 d |
| Earth flyby | 2028-12-01 | 488 d |
| Jupiter arrival | 2031-09-01 | 1004 d |
| **Total** | | **1735 d ≈ 4.75 yr** |

---

## Key results (default script)

| Item | Value |
|------|-------|
| LEO escape (3 burns, 300 km) | 4.02 km/s |
| C3 at launch | 18.6 km²/s² |
| Mars GA (heliocentric, no fuel) | 3.31 km/s |
| Earth GA (heliocentric, no fuel) | 7.32 km/s |
| Jupiter capture | 11.69 km/s |
| **Total propulsive** | **~15.8 km/s** |
| E–J leg crosses asteroid belt (2.1–3.3 AU) | Yes |

---

## Workflow (exam order)

1. **Dates** → `days_between` → TOF per leg  
2. **Planet positions** → `planet_elements_and_sv` (Alg. 8.1)  
3. **Heliocentric legs** → `interplanetary_lambert` (Alg. 8.2) — **not Hohmann** (dates are fixed)  
4. **Earth escape** → `multiburn_leo_escape` using leg-1 \(v_\infty\)  
5. **Flybys** → `flyby_patch` (Mars **leading**, Earth **trailing**)  
6. **Jupiter capture** → `capture_dv`  
7. **Asteroid belt** → `asteroid_belt_crossing` on E–J leg  

**One-liner:** dates → positions → Lambert → \(v_\infty\) for launch → flybys for free speed → capture.

---

## Δv budget rules

| Count as propulsive | Do **not** count |
|---------------------|------------------|
| LEO escape | Gravity assists |
| TCM reserve | Heliocentric kinematic burns at SOI |
| Planet capture | |
| Planet → moon Hohmann (if added) | |

GA `dV_sun` = heliocentric speed gain/loss, not fuel.

---

## Main scripts

| Run | Purpose |
|-----|---------|
| `exam_earth_mars_earth_jupiter` | Full E–M–E–J exam |
| `exam_mission_saturn_titan` | Saturn → Titan template |
| `interplanetary_lambert` | Any dated planet→planet leg |
| `multiburn_leo_escape` | 3-burn Earth escape |
| `flyby_patch` | Gravity assist |
| `capture_dv` | Arrival at planet |
| `hohmann_planet` | Planet parking → moon |
| `example_8_4`, `problem_8_1` | Verify book answers |

---

## Extending the mission

| Add | How | Extra Δv (typical) |
|-----|-----|-------------------|
| Jupiter moon (Europa) | `hohmann_planet` after capture | +12 km/s → **~28 km/s total** |
| Enceladus / Titan | `exam_mission_saturn_titan`, change `r_moon` | varies |
| Extra flyby (Venus…) | `flyby_patch` + new Lambert leg | 0 propulsive |
| New dates / altitudes | Edit epochs, `rp`, `Ra1`/`Ra2` in exam script | recalc all |

Galilean moon \(a\) (km): Io 421700, Europa 671034, Ganymede 1070412, Callisto 1882709.

---

## Exam report — limitations to mention

- Patched conics; coplanar ecliptic; instant SOI switches  
- Flyby `V_out` is **not** chained into the next Lambert leg (dates fixed by exam sheet)  
- Hohmann \(\phi\) is reference only — real TOFs come from calendar dates  
- Three-burn apogee heights are design choices, not optimized  

---

## Curtis cheat sheet

| Topic | Section |
|-------|---------|
| Patched conics | §8.5 |
| Hohmann baseline | §8.2 |
| Phase / synodic | §8.3, Eqs. 8.7–8.10 |
| Departure hyperbola | §8.6, Eq. 8.42 |
| Capture | §8.8, Eq. 8.60 |
| Gravity assist | §8.9, Eq. 8.54 |
| Ephemeris | §8.10, Alg. 8.1 |
| Lambert | §8.11, Alg. 8.2 |
