import probability.martingale
import probability.independence
import probability.integration

open measure_theory filter set finset

noncomputable theory

open_locale topological_space big_operators measure_theory probability_theory ennreal nnreal

namespace probability_theory

def variance {Ω : Type*} {m : measurable_space Ω} (f : Ω → ℝ) (μ : measure Ω) :=
μ[(f - (λ x, μ[f])) ^ 2]

@[simp] lemma variance_zero {Ω : Type*} {m : measurable_space Ω} (μ : measure Ω) :
  variance 0 μ = 0 :=
by simp [variance]

lemma variance_nonneg {Ω : Type*} {m : measurable_space Ω} (f : Ω → ℝ) (μ : measure Ω) :
  0 ≤ variance f μ :=
integral_nonneg (λ x, sq_nonneg _)

localized "notation `Var[` X `]` := probability_theory.variance X volume" in probability_theory
localized "notation `ℙ` := volume" in probability_theory

variables {Ω : Type*} [measure_space Ω] [is_probability_measure (ℙ : measure Ω)]

lemma variance_def' {X : Ω → ℝ} (hX : mem_ℒp X 2) :
  Var[X] = 𝔼[X^2] - 𝔼[X]^2 :=
begin
  rw [variance, sub_sq', integral_sub', integral_add'], rotate,
  { exact hX.integrable_sq },
  { convert integrable_const (𝔼[X] ^ 2),
    apply_instance },
  { apply hX.integrable_sq.add,
    convert integrable_const (𝔼[X] ^ 2),
    apply_instance },
  { apply integrable.mul_const',
    apply integrable.const_mul _ 2,
    exact hX.integrable ennreal.one_le_two },
  simp only [integral_mul_right, pi.pow_apply, pi.mul_apply, pi.bit0_apply, pi.one_apply,
    integral_const (integral ℙ X ^ 2), integral_mul_left (2 : ℝ), one_mul,
    variance, pi.pow_apply, measure_univ, ennreal.one_to_real, algebra.id.smul_eq_mul],
  ring,
end

theorem meas_ge_le_mul_variance {X : Ω → ℝ} (hX : mem_ℒp X 2) {c : ℝ≥0} (hc : c ≠ 0) :
  ℙ {ω | (c : ℝ) ≤ |X ω - 𝔼[X]|} ≤ 1/c^2 * ennreal.of_real (Var[X]) :=
begin
  have B : ae_strongly_measurable (λ (ω : Ω), 𝔼[X]) ℙ := ae_strongly_measurable_const,
  convert meas_ge_le_mul_pow_snorm ℙ ennreal.two_ne_zero ennreal.two_ne_top
    (hX.ae_strongly_measurable.sub B) (ennreal.coe_ne_zero.2 hc),
  { ext ω,
    simp only [pi.sub_apply, ennreal.coe_le_coe, ← real.norm_eq_abs, ← coe_nnnorm,
      nnreal.coe_le_coe] },
  { norm_cast,
    simp only [hc, one_div, inv_pow₀, ennreal.coe_inv, ne.def, pow_eq_zero_iff, nat.succ_pos',
      not_false_iff] },
  { rw (hX.sub (mem_ℒp_const _)).snorm_eq_rpow_integral_rpow_norm
      ennreal.two_ne_zero ennreal.two_ne_top,
    simp only [pi.sub_apply, ennreal.to_real_bit0, ennreal.one_to_real],
    rw ennreal.of_real_rpow_of_nonneg _ zero_le_two, rotate,
    { apply real.rpow_nonneg_of_nonneg,
      apply integral_nonneg (λ x, _),
      apply real.rpow_nonneg_of_nonneg (norm_nonneg _) },
    rw [variance, ← real.rpow_mul, inv_mul_cancel], rotate,
    { exact two_ne_zero },
    { apply integral_nonneg (λ x, _),
      apply real.rpow_nonneg_of_nonneg (norm_nonneg _) },
    simp only [pi.pow_apply, pi.sub_apply, real.rpow_two, real.rpow_one, real.norm_eq_abs,
      pow_bit0_abs] }
end

theorem indep_fun.Var_add {X Y : Ω → ℝ} (hX : mem_ℒp X 2) (hY : mem_ℒp Y 2) (h : indep_fun X Y) :
  Var[X + Y] = Var[X] + Var[Y] :=
calc
Var[X + Y] = 𝔼[λ a, (X a)^2 + (Y a)^2 + 2 * X a * Y a] - 𝔼[X+Y]^2 :
  by simp [variance_def' (hX.add hY), add_sq']
... = (𝔼[X^2] + 𝔼[Y^2] + 2 * 𝔼[X * Y]) - (𝔼[X] + 𝔼[Y])^2 :
begin
  simp only [pi.add_apply, pi.pow_apply, pi.mul_apply, mul_assoc],
  rw [integral_add, integral_add, integral_add, integral_mul_left],
  { exact hX.integrable ennreal.one_le_two },
  { exact hY.integrable ennreal.one_le_two },
  { exact hX.integrable_sq },
  { exact hY.integrable_sq },
  { exact hX.integrable_sq.add hY.integrable_sq },
  { apply integrable.const_mul,
    exact h.integrable_mul (hX.integrable ennreal.one_le_two) (hY.integrable ennreal.one_le_two) }
end
... = (𝔼[X^2] + 𝔼[Y^2] + 2 * (𝔼[X] * 𝔼[Y])) - (𝔼[X] + 𝔼[Y])^2 :
begin
  congr,
  exact h.integral_mul_of_integrable
    (hX.integrable ennreal.one_le_two) (hY.integrable ennreal.one_le_two),
end
... = Var[X] + Var[Y] :
  by { simp only [variance_def', hX, hY, pi.pow_apply], ring }

theorem indep_fun.Var_sum {ι : Type*} {X : ι → Ω → ℝ} {s : finset ι}
  (hs : ∀ i ∈ s, mem_ℒp (X i) 2) (h : set.pairwise ↑s (λ i j, indep_fun (X i) (X j))) :
  Var[∑ i in s, X i] = ∑ i in s, Var[X i] :=
begin
  classical,
  induction s using finset.induction_on with k s ks IH,
  { simp only [finset.sum_empty, variance_zero] },
  rw [variance_def' (mem_ℒp_finset_sum' _ hs), sum_insert ks, sum_insert ks],
  simp only [add_sq'],
  calc 𝔼[X k ^ 2 + (∑ i in s, X i) ^ 2 + 2 * X k * ∑ i in s, X i] - 𝔼[X k + ∑ i in s, X i] ^ 2
  = (𝔼[X k ^ 2] + 𝔼[(∑ i in s, X i) ^ 2] + 𝔼[2 * X k * ∑ i in s, X i])
    - (𝔼[X k] + 𝔼[∑ i in s, X i]) ^ 2 :
  begin
    rw [integral_add', integral_add', integral_add'],
    { exact mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_self _ _)) },
    { apply integrable_finset_sum' _ (λ i hi, _),
      exact mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_of_mem hi)) },
    { exact mem_ℒp.integrable_sq (hs _ (mem_insert_self _ _)) },
    { apply mem_ℒp.integrable_sq,
      exact mem_ℒp_finset_sum' _ (λ i hi, (hs _ (mem_insert_of_mem hi))) },
    { apply integrable.add,
      { exact mem_ℒp.integrable_sq (hs _ (mem_insert_self _ _)) },
      { apply mem_ℒp.integrable_sq,
        exact mem_ℒp_finset_sum' _ (λ i hi, (hs _ (mem_insert_of_mem hi))) } },
    { rw mul_assoc,
      apply integrable.const_mul _ 2,
      simp only [mul_sum, sum_apply, pi.mul_apply],
      apply integrable_finset_sum _ (λ i hi, _),
      apply indep_fun.integrable_mul _
        (mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_self _ _)))
        (mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_of_mem hi))),
      apply h (mem_insert_self _ _) (mem_insert_of_mem hi),
      assume hki,
      rw hki at ks,
      exact ks hi }
  end
  ... = Var[X k] + Var[∑ i in s, X i] +
    (𝔼[2 * X k * ∑ i in s, X i] - 2 * 𝔼[X k] * 𝔼[∑ i in s, X i]) :
  begin
    rw [variance_def' (hs _ (mem_insert_self _ _)),
        variance_def' (mem_ℒp_finset_sum' _ (λ i hi, (hs _ (mem_insert_of_mem hi))))],
    ring,
  end
  ... = Var[X k] + Var[∑ i in s, X i] :
  begin
    simp only [mul_assoc, integral_mul_left, pi.mul_apply, pi.bit0_apply, pi.one_apply, sum_apply,
      add_right_eq_self, mul_sum],
    rw integral_finset_sum s (λ i hi, _), swap,
    { apply integrable.const_mul _ 2,
      apply indep_fun.integrable_mul _
        (mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_self _ _)))
        (mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_of_mem hi))),
      apply h (mem_insert_self _ _) (mem_insert_of_mem hi),
      assume hki,
      rw hki at ks,
      exact ks hi },
    rw [integral_finset_sum s
      (λ i hi, (mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_of_mem hi)))),
      mul_sum, mul_sum, ← sum_sub_distrib],
    apply finset.sum_eq_zero (λ i hi, _),
    rw [integral_mul_left, indep_fun.integral_mul_of_integrable', sub_self],
    { apply h (mem_insert_self _ _) (mem_insert_of_mem hi),
      assume hki,
      rw hki at ks,
      exact ks hi },
    { exact mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_self _ _)) },
    { exact mem_ℒp.integrable ennreal.one_le_two (hs _ (mem_insert_of_mem hi)) }
  end
  ... = Var[X k] + ∑ i in s, Var[X i] :
    by rw IH (λ i hi, hs i (mem_insert_of_mem hi))
      (h.mono (by simp only [coe_insert, set.subset_insert]))
end

section truncation

variables {α : Type*}

def truncation {α : Type*} (f : α → ℝ) (A : ℝ) :=
(indicator (Icc (-A) A) id) ∘ f

variables {m : measurable_space α} {μ : measure α} {f : α → ℝ}

lemma _root_.measure_theory.ae_strongly_measurable.truncation
  (hf : ae_strongly_measurable f μ) {A : ℝ} :
  ae_strongly_measurable (truncation f A) μ :=
begin
  apply ae_strongly_measurable.comp_ae_measurable _ hf.ae_measurable,
  exact (strongly_measurable_id.indicator measurable_set_Icc).ae_strongly_measurable,
end

lemma neg_abs_le_neg (a : ℝ) : -|a| ≤ -a :=
by simp [le_abs_self]

lemma abs_truncation_le_bound (f : α → ℝ) (A : ℝ) (x : α) :
  abs (truncation f A x) ≤ |A| :=
begin
  simp only [truncation, indicator, set.mem_Icc, id.def, function.comp_app],
  split_ifs,
  { simp only [real.norm_eq_abs, abs_le],
    split,
    { linarith [neg_abs_le_neg A, h.1] },
    { linarith [le_abs_self A, h.2] } },
  { simp [abs_nonneg] }
end

lemma abs_truncation_le_abs_self (f : α → ℝ) (A : ℝ) (x : α) :
  |truncation f A x| ≤ |f x| :=
begin
  simp only [truncation, indicator, set.mem_Icc, id.def, function.comp_app],
  split_ifs,
  { exact le_rfl },
  { simp [abs_nonneg] },
end

lemma _root_.measure_theory.ae_strongly_measurable.mem_ℒp_truncation [is_finite_measure μ]
  (hf : ae_strongly_measurable f μ) {A : ℝ} {p : ℝ≥0∞} :
  mem_ℒp (truncation f A) p μ :=
begin
  refine mem_ℒp.mem_ℒp_of_exponent_le _ le_top,
  apply mem_ℒp_top_of_bound hf.truncation _
    (eventually_of_forall (λ x, abs_truncation_le_bound _ _ _)),
end

lemma tendsto_integral_truncation {f : α → ℝ} (hf : integrable f μ) :
  tendsto (λ A, ∫ x, truncation f A x ∂μ) at_top (𝓝 (∫ x, f x ∂μ)) :=
begin
  apply tendsto_integral_filter_of_dominated_convergence (λ x, abs (f x)),
  { exact eventually_of_forall (λ A, hf.ae_strongly_measurable.truncation) },
  { apply eventually_of_forall (λ A, _),
    apply eventually_of_forall (λ x, _),
    rw real.norm_eq_abs,
    exact abs_truncation_le_abs_self _ _ _ },
  { apply integrable.norm,

  }

end



#exit

theorem
  strong_law1
  (X : ℕ → Ω → ℝ) (hint : ∀ i, integrable (X i))
  (hindep : pairwise (λ i j, indep_fun (X i) (X j)))
  (h'i : ∀ i j, measure.map (X i) ℙ = measure.map (X j) ℙ)
  (h''i : ∀ i ω, 0 ≤ X i ω) :
  ∀ᵐ ω, tendsto (λ n, (∑ i in finset.range n, X i ω) / (n : ℝ)) at_top (𝓝 (𝔼[X 0])) :=
begin
  have A : ∀ i, strongly_measurable (indicator (Icc (0 : ℝ) i) id) :=
    λ i, strongly_measurable_id.indicator measurable_set_Icc,
  let Y := λ (n : ℕ), (indicator (Icc (0 : ℝ) n) id) ∘ (X n),
  have Y_meas : ∀ n, ae_strongly_measurable (Y n) ℙ :=
    λ n, (A n).ae_strongly_measurable.comp_ae_measurable (hint n).ae_measurable,
  have : pairwise (λ i j, indep_fun (Y i) (Y j) ℙ),
  { assume i j hij,
    exact (hindep i j hij).comp (A i).measurable (A j).measurable },
  have Itop : ∀ i, mem_ℒp (Y i) ∞,
  { assume i,
    apply mem_ℒp_top_of_bound (Y_meas i) i (eventually_of_forall (λ x, _)),
    simp only [Y, indicator, set.mem_Icc, id.def, function.comp_app],
    split_ifs,
    { simp only [h.1, h.2, real.norm_eq_abs, abs_of_nonneg] },
    { simp only [norm_zero, nat.cast_nonneg] } },
  have : ∀ i, mem_ℒp (Y i) 2 := λ i, (Itop i).mem_ℒp_of_exponent_le le_top,

end

end probability_theory
