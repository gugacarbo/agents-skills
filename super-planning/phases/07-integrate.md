# Phase 7: Integrate and Finish

After implementation is done and the plan is ready for final closure:

1. **Run the full test suite** once
2. **Dispatch a final whole-branch review** using the most capable model
3. **Address any remaining findings** from the final review
4. **Update `super-plan.json` through script** with final status so the progress ledger regenerates
5. **Offer next steps:** merge, PR, or keep working

Then transition the spec status to `implemented` and fill in `implemented-by` with the real paths that deliver the spec.

If `reviewCadence=final_only`, this phase must also perform the first independent review gate for the implementation before any task or requirement is considered fully accepted.
