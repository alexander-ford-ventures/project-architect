---
template_name: HARDWARE_FIRMWARE
generate_when: "decisions.project.type == 'embedded' AND decisions.hardware.combo == true"
required_decisions: [hardware.pcb_design, hardware.manufacturing]
optional_decisions: [hardware.certifications, hardware.enclosure, hardware.sourcing]
depends_on: [EMBEDDED_SPECIFIC]
revision_triggers: [hardware.pcb_design, hardware.manufacturing, hardware.certifications]
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Hardware & Firmware: {{project_name}}

## Hardware Overview (block diagram)
High-level block diagram of the device — MCU, sensors, radios, power tree, I/O — with a short walkthrough explaining data and power flow.

## PCB Design Strategy
PCB design tooling (KiCad, Altium, EasyEDA), layer count, design-for-EMI/EMC choices, design-for-manufacture (DFM) and design-for-test (DFT) considerations.

## BoM Strategy
Bill-of-materials approach: preferred suppliers, second-source components, lifecycle-status checks (Octopart, Z2Data), cost target per unit, and BoM management tooling.

## Manufacturing Partner
Contract manufacturer / EMS selection (JLCPCB, PCBWay, MacroFab, regional CM), PCBA volumes, panelization, and quality criteria (AOI, ICT, functional test).

## Certifications (FCC / CE / UL / RoHS)
Required certifications per target market (FCC Part 15, CE / RED, UL, IC, MIC, KC, ANATEL, RoHS, REACH), pre-compliance testing plan, and lab partners.

## Enclosure & Mechanical
Enclosure approach (off-the-shelf, custom injection-molded, 3D-printed), IP rating, drop / shock targets, tolerances, and CAD tooling.

## Component Sourcing Risk
Supply-chain risk profile per critical part, lead times, allocation status, alternates qualified, and inventory buffer policy.

## Firmware ↔ Hardware Interface Contracts
Hardware-firmware contract: pin assignments, register maps, version-detect strategy (hardware revision pins), and how firmware adapts to multiple hardware revisions.

## Revision Log
(none yet)

---

*Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
