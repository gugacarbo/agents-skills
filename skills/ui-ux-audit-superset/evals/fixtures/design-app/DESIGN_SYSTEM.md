# Canonical product UI standard

This repository uses the fictional Northwind Ops design system.

## Semantic tokens

- `--action-primary`: #075ab5
- `--action-primary-hover`: #04499a
- `--action-danger`: #a4262c
- `--surface`: #ffffff
- `--text`: #17202a
- `--border`: #5b6875
- `--focus`: #b35c00
- spacing unit: 4px
- control height: 40px
- radius: 6px

## Buttons

Use the shared button classes or their exact token values:

- `primary`: filled `--action-primary`, white text, 40px height, 6px radius,
  hover `--action-primary-hover`, visible focus ring using `--focus`.
- `secondary`: transparent background, `--action-primary` text, 1px current
  border, same height/radius/focus treatment.
- `danger`: filled `--action-danger`, white text; never place it before the
  safe action in a confirmation.

Buttons must expose disabled and pending treatments.

## Approved exception

The dense inline row action in data tables may use a 32px height because the
operations team requires compact scanning. This exception is approved and must
not be reported as drift.

## Inputs

Persistent label above the control, 1px `--border`, 40px height, 6px radius.
Errors use `--action-danger` plus text; never color alone.
