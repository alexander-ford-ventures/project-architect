---
template_name: INTERNATIONALIZATION
generate_when: "decisions.i18n.languages.length > 1"
required_decisions:
  - i18n.languages
optional_decisions:
  - i18n.library
  - i18n.translation_workflow
  - i18n.rtl_support
depends_on:
  - UI_UX_DESIGN
revision_triggers:
  - i18n.languages
  - i18n.library
  - i18n.rtl_support
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Internationalization: {{project_name}}

## Supported Locales
Full locale list (BCP-47 tags), launch tier vs follow-on tier, fallback chain (e.g., `pt-BR` → `pt` → `en`), and default locale resolution from headers/geo.

## i18n Library
Chosen library (next-intl, react-intl/FormatJS, i18next, Lingui, Vue I18n, Rails I18n, gettext) and rationale. Note runtime vs build-time extraction and bundle-size implications.

## Translation Workflow
Source-of-truth for source strings (in-repo JSON/PO files, CMS, headless service like Crowdin/Lokalise/Phrase/Tolgee). Document push/pull cadence, reviewer workflow, and machine-translation pre-fill policy.

## String Externalization Conventions
Where strings live in the codebase, key naming convention (namespaced vs flat), interpolation syntax, ICU MessageFormat usage, lint rules to forbid hard-coded copy.

## Date / Number / Currency Formatting
Use of `Intl.*` APIs vs library helpers, currency rendering rules (symbol position, decimal/thousands separators), timezone handling for date-only vs datetime fields.

## RTL Support
Right-to-left coverage strategy (logical CSS properties, `dir` attribute, mirroring of icons/animations), QA checklist for RTL locales.

## Pluralization & Gender
ICU plural categories per locale, gendered forms where required (Slavic, Semitic, etc.), context disambiguation conventions for translators.

## Revision Log
(none yet)

---

*Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
