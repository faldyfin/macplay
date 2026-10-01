# Data Model: Indonesian UI

## Language preference (`lang`, UserDefaults)

| Value | Meaning |
|---|---|
| `system` (default) | first preferred macOS language: `fr…` → French, `id…` → Indonesian, else English |
| `en` | English |
| `fr` | French |
| `id` | Indonesian (**new**) |

## UI string

- Every call: `L.t(english, french, indonesian)`, all three string literals.
- **Validation**: the Indonesian literal contains exactly the same `\( )` expressions and the same
  `%` format specifiers, in any order, as the English one.
