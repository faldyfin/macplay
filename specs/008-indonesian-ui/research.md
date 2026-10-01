# Research: Indonesian UI

## Keep `L.t` with a third argument

- **Decision**: `L.t(en, fr, id)` at every call site.
- **Rationale**: matches the existing pattern; the compiler then guarantees no string is missing a
  language (a two-argument call no longer compiles), which is spec SC-001.
- **Alternatives**: Apple string catalogs / `Localizable.strings` (a project-wide migration, keyed
  strings away from the code); a dictionary keyed by the English text (cannot handle interpolated
  strings, which are built before `L.t` sees them, and gives no compile-time completeness).

## Inserting 229 translations safely

- **Decision**: a one-off script parses each call (string literals with escapes and nested
  `\( )` interpolations), looks the English literal up in a translation table and appends the
  Indonesian literal. It refuses a translation whose `\( )` expressions or `%` specifiers differ
  from the English one.
- **Rationale**: hand-editing 229 calls risks broken literals; the checks catch mismatched
  placeholders, which the compiler would not (they are just text).
- **Alternatives**: manual edits per file.

## Language selection

- **Decision**: `lang` = `system` | `fr` | `en` | `id`; under `system` the first preferred macOS
  language decides (prefix `fr` → French, `id` → Indonesian, else English).
- **Rationale**: same rule as today, extended; English stays the fallback.

## Tone

- **Decision**: informal Indonesian ("kamu"), product and engine names untranslated.
- **Rationale**: the English and French text address the player directly and informally ("you",
  "tu").

## Data-file text

- **Decision**: `notes`, `symptom`, `fix` show the French variant only in French; in Indonesian they
  show English.
- **Rationale**: the data has no Indonesian fields (spec FR-005).
