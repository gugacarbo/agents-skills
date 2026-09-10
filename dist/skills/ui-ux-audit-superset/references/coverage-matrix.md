# Coverage Matrix

Use this as a final “did we miss a domain?” check for a full audit.

| Domain | Runtime | Source | Design source | Typical evidence |
|---|---|---|---|---|
| User task & friction | ✓ | optional | optional | completed flow |
| Action hierarchy | ✓ | optional | ✓ | screen states |
| Navigation/IA | ✓ | optional | optional | routes/history |
| Visual hierarchy | ✓ | optional | ✓ | screenshots |
| Typography/color/spacing | ✓ | ✓ | ✓ | tokens/specs |
| Design-system reuse | ✓ | ✓ | ✓ | components |
| Variants/states | ✓ | ✓ | ✓ | state matrix |
| Keyboard/focus | ✓ | ✓ | optional | manual testing |
| Screen reader | ✓ | ✓ | optional | real AT if available |
| WCAG semantics | ✓ | ✓ | optional | DOM/a11y tree |
| Forms | ✓ | ✓ | optional | submit/error |
| Responsive/reflow | ✓ | ✓ | ✓ | viewport matrix |
| Touch/gestures | ✓ | ✓ | optional | device/emulation |
| Dark/high contrast | ✓ | ✓ | ✓ | theme matrix |
| Motion/reduced motion | ✓ | ✓ | ✓ | preference test |
| Empty/loading/error | ✓ | ✓ | optional | forced states |
| Copy/microcopy | ✓ | ✓ | optional | task language |
| i18n/locale | ✓ | ✓ | optional | locale switch |
| URL/deep-link state | ✓ | ✓ | optional | copy/reload URL |
| Images/media | ✓ | ✓ | optional | network/layout |
| Perceived performance | ✓ | ✓ | optional | interaction |
| Hydration/SSR | ✓ | ✓ | n/a | console/source |
| Safe areas/mobile viewport | ✓ | ✓ | ✓ | device test |
| AI/error transparency | ✓ | ✓ | optional | generated/error states |
| Destructive safety | ✓ | ✓ | optional | confirmation/recovery |

A Full Product Audit should cover every applicable row or explicitly list it as not verified/not applicable.
