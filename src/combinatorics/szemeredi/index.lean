/-
Copyright (c) 2021 Yaël Dillies, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Bhavik Mehta
-/
import .mathlib
import combinatorics.choose.bounds
import data.sym.card

/-!
# Index
-/

open_locale big_operators
open finset fintype function relation

variables {α : Type*}

namespace finset
variable [decidable_pred (λ (ab : α × α), well_ordering_rel ab.fst ab.snd)]

/-- Pairs of parts. We exclude the diagonal, as these do not make sense nor
behave well in the context of Szemerédi's Regularity Lemma. -/
def distinct_pairs (s : finset α) :
  finset (α × α) :=
(s.product s).filter (λ ab, well_ordering_rel ab.1 ab.2)

variable {s : finset α}

lemma mem_distinct_pairs (a b : α) :
  (a, b) ∈ s.distinct_pairs ↔ a ∈ s ∧ b ∈ s ∧ well_ordering_rel a b :=
by rw [distinct_pairs, mem_filter, mem_product, and_assoc]

lemma distinct_pairs_subset_off_diag [decidable_eq α] : s.distinct_pairs ⊆ s.off_diag :=
begin
  rintro ⟨x₁, x₂⟩,
  simp only [mem_distinct_pairs, and_imp, mem_off_diag],
  rintro h₁ h₂ h,
  exact ⟨h₁, h₂, ne_of_irrefl h⟩,
end

@[simp] lemma off_diag_empty [decidable_eq α] :
  (∅ : finset α).off_diag = ∅ :=
by rw [off_diag, empty_product, filter_empty]

@[simp] lemma distinct_pairs_empty :
  (∅ : finset α).distinct_pairs = ∅ :=
begin
  rw eq_empty_iff_forall_not_mem,
  simp [mem_distinct_pairs],
end

lemma distinct_pairs_card [decidable_eq α] :
  s.distinct_pairs.card = s.card.choose 2 :=
begin
  rw ←sym2.card_image_off_diag,
  refine card_congr (λ a _, ⟦a⟧) _ _ _,
  { rintro ⟨a₁, a₂⟩ ha,
    apply mem_image_of_mem _ (distinct_pairs_subset_off_diag ha) },
  { rintro ⟨a₁, a₂⟩ ⟨b₁, b₂⟩,
    simp only [prod.mk.inj_iff, mem_distinct_pairs, and_imp, sym2.eq_iff],
    rintro _ _ h₁ _ _ h₂ (i | ⟨rfl, rfl⟩),
    { exact i },
    cases asymm h₁ h₂ },
  { refine quotient.ind _,
    simp only [mem_image, forall_exists_index, sym2.eq_iff, prod.forall, exists_prop, mem_off_diag,
      mem_distinct_pairs, prod.exists, and_assoc, and_imp],
    rintro a b x y _ _ dif h,
    obtain ⟨ha, hb⟩ : a ∈ s ∧ b ∈ s,
    { rcases h with (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩);
      exact ⟨‹_›, ‹_›⟩ },
    rcases trichotomous_of well_ordering_rel a b with lt | rfl | gt,
    { exact ⟨_, _, ‹a ∈ s›, ‹b ∈ s›, lt, by simp⟩ },
    { simp only [or_self] at h,
      cases dif (h.1.trans h.2.symm) },
    { exact ⟨_, _, ‹b ∈ s›, ‹a ∈ s›, gt, by simp⟩ } },
end

end finset

/-! ## finpartition_on.is_uniform -/

variables [decidable_eq α] {s : finset α} (P : finpartition_on s) (G : simple_graph α)

namespace finpartition_on
open_locale classical
open finset

noncomputable def non_uniform_pairs (ε : ℝ) :
  finset (finset α × finset α) :=
P.parts.distinct_pairs.filter (λ UV, ¬G.is_uniform ε UV.1 UV.2)
-- (P.parts.product P.parts).filter (λ UV, UV.1 ≠ UV.2 ∧ ¬G.is_uniform ε UV.1 UV.2)

lemma mem_non_uniform_pairs (U V : finset α) (ε : ℝ) :
  (U, V) ∈ P.non_uniform_pairs G ε ↔ U ∈ P.parts ∧ V ∈ P.parts ∧ well_ordering_rel U V ∧
  ¬G.is_uniform ε U V :=
by rw [non_uniform_pairs, mem_filter, mem_distinct_pairs, and_assoc, and_assoc]

/-- An finpartition is `ε-uniform` iff at most a proportion of `ε` of its pairs of parts are not
`ε-uniform`. -/
def is_uniform (ε : ℝ) : Prop :=
((P.non_uniform_pairs G ε).card : ℝ) ≤ ε * P.size.choose 2

lemma empty_is_uniform {P : finpartition_on s} (hP : P.parts = ∅) (G : simple_graph α) (ε : ℝ) :
  P.is_uniform G ε :=
begin
  rw [finpartition_on.is_uniform, finpartition_on.non_uniform_pairs, finpartition_on.size, hP],
  simp,
end

/-- The index is the auxiliary quantity that drives the induction process in the proof of
Szemerédi's Regularity Lemma (see `increment`). As long as we do not have a suitable equipartition,
we will find a new one that has an index greater than the previous one plus some fixed constant.
Then `index_le_half` ensures this process only happens finitely many times. -/
noncomputable def index (P : finpartition_on s) : ℝ :=
(∑ UV in P.parts.distinct_pairs, G.edge_density UV.1 UV.2^2)/P.size^2

lemma index_nonneg (P : finpartition_on s) :
  0 ≤ P.index G :=
div_nonneg (finset.sum_nonneg (λ _ _, sq_nonneg _)) (sq_nonneg _)

lemma index_le_half (P : finpartition_on s) :
  P.index G ≤ 1/2 :=
begin
  rw finpartition_on.index,
  apply div_le_of_nonneg_of_le_mul (sq_nonneg _),
  { norm_num },
  suffices h : (∑ UV in P.parts.distinct_pairs, G.edge_density UV.1 UV.2^2) ≤
    P.parts.distinct_pairs.card,
  { apply h.trans,
    rw [distinct_pairs_card, div_mul_eq_mul_div, one_mul],
    convert choose_le_pow 2 _,
    norm_num },
  rw [finset.card_eq_sum_ones, nat.cast_sum, nat.cast_one],
  refine finset.sum_le_sum (λ s _, _),
  rw [sq, ←abs_le_one_iff_mul_self_le_one, abs_eq_self.2 (G.edge_density_nonneg _ _)],
  exact G.edge_density_le_one _ _,
end

end finpartition_on

namespace discrete_finpartition_on

lemma non_uniform_pairs {ε : ℝ} (hε : 0 < ε) :
  (discrete_finpartition_on s).non_uniform_pairs G ε = ∅ :=
begin
  rw eq_empty_iff_forall_not_mem,
  rintro ⟨U, V⟩,
  simp only [finpartition_on.mem_non_uniform_pairs, discrete_finpartition_on_parts, mem_map,
    and_imp, exists_prop, not_and, not_not, ne.def, exists_imp_distrib, embedding.coe_fn_mk],
  rintro x hx rfl y hy rfl h U' hU' V' hV' hU hV,
  rw [card_singleton, nat.cast_one, one_mul] at hU hV,
  obtain rfl | rfl := finset.subset_singleton_iff.1 hU',
  { rw [finset.card_empty] at hU,
    exact (hε.not_le hU).elim },
  obtain rfl | rfl := finset.subset_singleton_iff.1 hV',
  { rw [finset.card_empty] at hV,
    exact (hε.not_le hV).elim },
  rwa [sub_self, abs_zero],
end

lemma is_uniform {ε : ℝ} (hε : 0 < ε) :
  (discrete_finpartition_on s).is_uniform G ε :=
begin
  rw [finpartition_on.is_uniform, discrete_finpartition_on.size, non_uniform_pairs _ hε,
    finset.card_empty, nat.cast_zero],
  exact mul_nonneg hε.le (nat.cast_nonneg _),
end

end discrete_finpartition_on
