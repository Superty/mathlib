/-
Copyright (c) 2019 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kalle Kytölä
-/
import topology.continuous_function.bounded

/-!
# Thickenings and thickened indicators

## Main definitions

## Main results

-/
noncomputable theory
open_locale classical nnreal ennreal topological_space bounded_continuous_function

open nnreal ennreal set metric emetric filter

lemma _root_.ennreal.div_le_div {a b c d : ℝ≥0∞} (hab : a ≤ b) (hdc : d ≤ c) :
  a / c ≤ b / d :=
begin
  rw [div_eq_mul_inv, div_eq_mul_inv],
  apply ennreal.mul_le_mul hab (ennreal.inv_le_inv.mpr hdc),
end

section thickened_indicator

variables {α : Type*} [pseudo_emetric_space α]

/-- The `δ`-thickened indicator of a set `E` is the function that equals `1` on `E`
and `0` outside a `δ`-thickening of `E` and interpolates (continuously) between
these values using `inf_edist _ E`.

`thickened_indicator_aux` is the unbundled `ℝ≥0∞`-valued function. See `thickened_indicator`
for the (bundled) bounded continuous function with `ℝ≥0`-values. -/
def thickened_indicator_aux (δ : ℝ) (E : set α) : α → ℝ≥0∞ :=
λ (x : α), (1 : ℝ≥0∞) - (inf_edist x E) / (ennreal.of_real δ)

lemma continuous_thickened_indicator_aux {δ : ℝ} (δ_pos : 0 < δ) (E : set α) :
  continuous (thickened_indicator_aux δ E) :=
begin
  unfold thickened_indicator_aux,
  let f := λ (x : α), (⟨1, (inf_edist x E) / (ennreal.of_real δ)⟩ : ℝ≥0 × ℝ≥0∞),
  let sub := λ (p : ℝ≥0 × ℝ≥0∞), ((p.1 : ℝ≥0∞) - p.2),
  rw (show (λ (x : α), ((1 : ℝ≥0∞)) - (inf_edist x E) / (ennreal.of_real δ)) = sub ∘ f, by refl),
  apply continuous.comp (@ennreal.continuous_nnreal_sub 1),
  apply (ennreal.continuous_div_const (ennreal.of_real δ) _).comp continuous_inf_edist,
  norm_num [δ_pos],
end

lemma thickened_indicator_aux_le_one (δ : ℝ) (E : set α) (x : α) :
  thickened_indicator_aux δ E x ≤ 1 :=
by apply @tsub_le_self _ _ _ _ (1 : ℝ≥0∞)

lemma thickened_indicator_aux_lt_top {δ : ℝ} {E : set α} {x : α} :
  thickened_indicator_aux δ E x < ∞ :=
lt_of_le_of_lt (thickened_indicator_aux_le_one _ _ _) one_lt_top

lemma thickened_indicator_aux_closure_eq (δ : ℝ) (E : set α) :
  thickened_indicator_aux δ (closure E) = thickened_indicator_aux δ E :=
by simp_rw [thickened_indicator_aux, inf_edist_closure]

lemma thickened_indicator_aux_one (δ : ℝ) (E : set α) {x : α} (x_in_E : x ∈ E) :
  thickened_indicator_aux δ E x = 1 :=
by simp [thickened_indicator_aux, inf_edist_zero_of_mem x_in_E, tsub_zero]

lemma thickened_indicator_aux_one_of_mem_closure
  (δ : ℝ) (E : set α) {x : α} (x_mem : x ∈ closure E) :
  thickened_indicator_aux δ E x = 1 :=
by rw [←thickened_indicator_aux_closure_eq, thickened_indicator_aux_one δ (closure E) x_mem]

lemma thickened_indicator_aux_zero
  {δ : ℝ} (δ_pos : 0 < δ) (E : set α) {x : α} (x_out : x ∉ thickening δ E) :
  thickened_indicator_aux δ E x = 0 :=
begin
  rw [thickening, mem_set_of_eq, not_lt] at x_out,
  unfold thickened_indicator_aux,
  apply le_antisymm _ bot_le,
  have key := tsub_le_tsub (@rfl _ (1 : ℝ≥0∞)).le (ennreal.div_le_div x_out rfl.le),
  rw [ennreal.div_self (ne_of_gt (ennreal.of_real_pos.mpr δ_pos)) of_real_ne_top] at key,
  simpa using key,
end

lemma thickened_indicator_aux_mono {δ₁ δ₂ : ℝ} (hle : δ₁ ≤ δ₂) (E : set α) :
  thickened_indicator_aux δ₁ E ≤ thickened_indicator_aux δ₂ E :=
begin
  intro x,
  apply tsub_le_tsub (@rfl ℝ≥0∞ 1).le,
  exact ennreal.div_le_div rfl.le (of_real_le_of_real hle),
end

lemma thickened_indicator_aux_subset (δ : ℝ) {E₁ E₂ : set α} (subset : E₁ ⊆ E₂) :
  thickened_indicator_aux δ E₁ ≤ thickened_indicator_aux δ E₂ :=
begin
  intro x,
  apply tsub_le_tsub (@rfl ℝ≥0∞ 1).le,
  exact ennreal.div_le_div (inf_edist_le_inf_edist_of_subset subset) rfl.le,
end

lemma thickened_indicator_aux_tendsto_indicator_closure
  {δseq : ℕ → ℝ} (δseq_lim : tendsto δseq at_top (𝓝 0)) (E : set α) :
  tendsto (λ n, (thickened_indicator_aux (δseq n) E)) at_top
    (𝓝 (indicator (closure E) (λ x, (1 : ℝ≥0∞)))) :=
begin
  rw tendsto_pi_nhds,
  intro x,
  by_cases x_mem_closure : x ∈ closure E,
  { simp_rw [thickened_indicator_aux_one_of_mem_closure _ E x_mem_closure],
    rw (show (indicator (closure E) (λ _, (1 : ℝ≥0∞))) x = 1,
        by simp only [x_mem_closure, indicator_of_mem]),
    exact tendsto_const_nhds, },
  { rw (show (closure E).indicator (λ _, (1 : ℝ≥0∞)) x = 0,
        by simp only [x_mem_closure, indicator_of_not_mem, not_false_iff]),
    rw mem_closure_iff_inf_edist_zero at x_mem_closure,
    obtain ⟨ε, ⟨ε_pos, ε_le⟩⟩ : ∃ (ε : ℝ), 0 < ε ∧ ennreal.of_real ε ≤ inf_edist x E,
    { by_cases dist_infty : inf_edist x E = ∞,
      { rw dist_infty,
        use [1, zero_lt_one, le_top], },
      { use (inf_edist x E).to_real,
        exact ⟨(to_real_lt_to_real zero_ne_top dist_infty).mpr (pos_iff_ne_zero.mpr x_mem_closure),
                of_real_to_real_le⟩, }, },
    rw metric.tendsto_nhds at δseq_lim,
    specialize δseq_lim ε ε_pos,
    simp only [dist_zero_right, real.norm_eq_abs, eventually_at_top, ge_iff_le] at δseq_lim,
    rcases δseq_lim with ⟨N, hN⟩,
    apply @tendsto_at_top_of_eventually_const _ _ _ _ _ _ _ N,
    intros n n_large,
    have key : x ∉ thickening ε E, by rwa [thickening, mem_set_of_eq, not_lt],
    refine le_antisymm _ bot_le,
    apply (thickened_indicator_aux_mono (lt_of_abs_lt (hN n n_large)).le E x).trans,
    exact (thickened_indicator_aux_zero ε_pos E key).le, },
end

/-- The `δ`-thickened indicator of a set `E` is the function that equals `1` on `E`
and `0` outside a `δ`-thickening of `E` and interpolates (continuously) between
these values using `inf_edist _ E`.

`thickened_indicator` is the (bundled) bounded continuous function with `ℝ≥0`-values.
See `thickened_indicator_aux` for the unbundled `ℝ≥0∞`-valued function. -/
@[simps] def thickened_indicator {δ : ℝ} (δ_pos : 0 < δ) (E : set α) : α →ᵇ ℝ≥0 :=
{ to_fun := λ (x : α), (thickened_indicator_aux δ E x).to_nnreal,
  continuous_to_fun := begin
    apply continuous_on.comp_continuous
            continuous_on_to_nnreal (continuous_thickened_indicator_aux δ_pos E),
    intro x,
    rw mem_set_of_eq,
    apply ne_of_lt,
    exact lt_of_le_of_lt (@thickened_indicator_aux_le_one _ _ δ E x) one_lt_top,
  end,
  map_bounded' := begin
    use 2,
    intros x y,
    rw [nnreal.dist_eq],
    apply (abs_sub _ _).trans,
    rw [nnreal.abs_eq, nnreal.abs_eq, ←one_add_one_eq_two],
    have key := @thickened_indicator_aux_le_one _ _ δ E,
    apply add_le_add;
    { norm_cast,
      refine (to_nnreal_le_to_nnreal ((lt_of_le_of_lt (key _) one_lt_top).ne) one_ne_top).mpr
             (key _), },
  end, }

lemma thickened_indicator.coe_fn_eq_comp {δ : ℝ} (δ_pos : 0 < δ) (E : set α) :
  ⇑(thickened_indicator δ_pos E) = ennreal.to_nnreal ∘ thickened_indicator_aux δ E := rfl

lemma thickened_indicator_le_one {δ : ℝ} (δ_pos : 0 < δ) (E : set α) (x : α) :
  thickened_indicator δ_pos E x ≤ 1 :=
begin
  rw [thickened_indicator.coe_fn_eq_comp],
  simpa using (to_nnreal_le_to_nnreal thickened_indicator_aux_lt_top.ne one_ne_top).mpr
    (thickened_indicator_aux_le_one δ E x),
end

lemma thickened_indicator_one_of_mem_closure
  {δ : ℝ} (δ_pos : 0 < δ) (E : set α) {x : α} (x_mem : x ∈ closure E) :
  thickened_indicator δ_pos E x = 1 :=
by rw [thickened_indicator_apply,
       thickened_indicator_aux_one_of_mem_closure δ E x_mem, one_to_nnreal]

lemma thickened_indicator_one {δ : ℝ} (δ_pos : 0 < δ) (E : set α) {x : α} (x_in_E : x ∈ E) :
  thickened_indicator δ_pos E x = 1 :=
thickened_indicator_one_of_mem_closure _ _ (subset_closure x_in_E)

lemma thickened_indicator_zero
  {δ : ℝ} (δ_pos : 0 < δ) (E : set α) {x : α} (x_out : x ∉ thickening δ E) :
  thickened_indicator δ_pos E x = 0 :=
by rw [thickened_indicator_apply, thickened_indicator_aux_zero δ_pos E x_out, zero_to_nnreal]

lemma thickened_indicator_mono {δ₁ δ₂ : ℝ}
  (δ₁_pos : 0 < δ₁) (δ₂_pos : 0 < δ₂) (hle : δ₁ ≤ δ₂) (E : set α) :
  ⇑(thickened_indicator δ₁_pos E) ≤ thickened_indicator δ₂_pos E :=
begin
  intro x,
  apply (to_nnreal_le_to_nnreal thickened_indicator_aux_lt_top.ne
         thickened_indicator_aux_lt_top.ne).mpr,
  apply thickened_indicator_aux_mono hle,
end

lemma thickened_indicator_subset {δ : ℝ} (δ_pos : 0 < δ) {E₁ E₂ : set α} (subset : E₁ ⊆ E₂) :
  ⇑(thickened_indicator δ_pos E₁) ≤ thickened_indicator δ_pos E₂ :=
begin
  intro x,
  exact (to_nnreal_le_to_nnreal thickened_indicator_aux_lt_top.ne
         thickened_indicator_aux_lt_top.ne).mpr (thickened_indicator_aux_subset δ subset x),
end

lemma thickened_indicator_tendsto_indicator_closure
  {δseq : ℕ → ℝ} (δseq_pos : ∀ n, 0 < δseq n) (δseq_lim : tendsto δseq at_top (𝓝 0)) (E : set α) :
  tendsto (λ n, (thickened_indicator (δseq_pos n) E).to_fun) at_top
    (𝓝 (indicator (closure E) (λ x, (1 : ℝ≥0)))) :=
begin
  have key := thickened_indicator_aux_tendsto_indicator_closure δseq_lim E,
  rw tendsto_pi_nhds at *,
  intro x,
  rw (show indicator (closure E) (λ x, (1 : ℝ≥0)) x
         = (indicator (closure E) (λ x, (1 : ℝ≥0∞)) x).to_nnreal,
      by refine (congr_fun (comp_indicator_const 1 ennreal.to_nnreal zero_to_nnreal) x).symm),
  refine tendsto.comp (tendsto_to_nnreal _) (key x),
  by_cases x_mem : x ∈ closure E; simp [x_mem],
end

end thickened_indicator -- section
