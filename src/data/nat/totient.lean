/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import algebra.big_operators.basic
import data.nat.prime
import data.zmod.basic
import data.nat.prime_factorization
import tactic.field_simp

/-!
# Euler's totient function

This file defines [Euler's totient function](https://en.wikipedia.org/wiki/Euler's_totient_function)
`nat.totient n` which counts the number of naturals less than `n` that are coprime with `n`.
We prove the divisor sum formula, namely that `n` equals `φ` summed over the divisors of `n`. See
`sum_totient`. We also prove two lemmas to help compute totients, namely `totient_mul` and
`totient_prime_pow`.
-/

open finset
open_locale big_operators

namespace nat

/-- Euler's totient function. This counts the number of naturals strictly less than `n` which are
coprime with `n`. -/
def totient (n : ℕ) : ℕ := ((range n).filter (nat.coprime n)).card

localized "notation `φ` := nat.totient" in nat

@[simp] theorem totient_zero : φ 0 = 0 := rfl

@[simp] theorem totient_one : φ 1 = 1 :=
by simp [totient]

lemma totient_eq_card_coprime (n : ℕ) : φ n = ((range n).filter (nat.coprime n)).card := rfl

lemma totient_le (n : ℕ) : φ n ≤ n :=
calc totient n ≤ (range n).card : card_filter_le _ _
           ... = n              : card_range _

lemma totient_lt (n : ℕ) (hn : 1 < n) : φ n < n :=
calc totient n ≤ ((range n).filter (≠ 0)).card :
  begin
    apply card_le_of_subset (monotone_filter_right _ _),
    intros n1 hn1 hn1',
    simpa only [hn1', coprime_zero_right, hn.ne'] using hn1,
  end
... = n - 1 : by simp only [filter_ne' (range n) 0, card_erase_of_mem, n.pred_eq_sub_one,
                card_range, pos_of_gt hn, mem_range]
... < n : nat.sub_lt (pos_of_gt hn) zero_lt_one

lemma totient_pos : ∀ {n : ℕ}, 0 < n → 0 < φ n
| 0 := dec_trivial
| 1 := by simp [totient]
| (n+2) := λ h, card_pos.2 ⟨1, mem_filter.2 ⟨mem_range.2 dec_trivial, coprime_one_right _⟩⟩

open zmod

/-- Note this takes an explicit `fintype (units (zmod n))` argument to avoid trouble with instance
diamonds. -/
@[simp] lemma _root_.zmod.card_units_eq_totient (n : ℕ) [fact (0 < n)] [fintype (units (zmod n))] :
  fintype.card (units (zmod n)) = φ n :=
calc fintype.card (units (zmod n)) = fintype.card {x : zmod n // x.val.coprime n} :
  fintype.card_congr zmod.units_equiv_coprime
... = φ n :
begin
  apply finset.card_congr (λ (a : {x : zmod n // x.val.coprime n}) _, a.1.val),
  { intro a, simp [(a : zmod n).val_lt, a.prop.symm] {contextual := tt} },
  { intros _ _ _ _ h, rw subtype.ext_iff_val, apply val_injective, exact h, },
  { intros b hb,
    rw [finset.mem_filter, finset.mem_range] at hb,
    refine ⟨⟨b, _⟩, finset.mem_univ _, _⟩,
    { let u := unit_of_coprime b hb.2.symm,
      exact val_coe_unit_coprime u },
    { show zmod.val (b : zmod n) = b,
      rw [val_nat_cast, nat.mod_eq_of_lt hb.1], } }
end

lemma totient_mul {m n : ℕ} (h : m.coprime n) : φ (m * n) = φ m * φ n :=
if hmn0 : m * n = 0
  then by cases nat.mul_eq_zero.1 hmn0 with h h;
    simp only [totient_zero, mul_zero, zero_mul, h]
  else
  begin
    haveI : fact (0 < (m * n)) := ⟨nat.pos_of_ne_zero hmn0⟩,
    haveI : fact (0 < m) := ⟨nat.pos_of_ne_zero $ left_ne_zero_of_mul hmn0⟩,
    haveI : fact (0 < n) := ⟨nat.pos_of_ne_zero $ right_ne_zero_of_mul hmn0⟩,
    rw [← zmod.card_units_eq_totient, ← zmod.card_units_eq_totient,
      ← zmod.card_units_eq_totient, fintype.card_congr
      (units.map_equiv (zmod.chinese_remainder h).to_mul_equiv).to_equiv,
      fintype.card_congr (@mul_equiv.prod_units (zmod m) (zmod n) _ _).to_equiv,
      fintype.card_prod]
  end

lemma sum_totient (n : ℕ) : ∑ m in (range n.succ).filter (∣ n), φ m = n :=
if hn0 : n = 0 then by simp [hn0]
else
calc ∑ m in (range n.succ).filter (∣ n), φ m
    = ∑ d in (range n.succ).filter (∣ n), ((range (n / d)).filter (λ m, gcd (n / d) m = 1)).card :
  eq.symm $ sum_bij (λ d _, n / d)
    (λ d hd, mem_filter.2 ⟨mem_range.2 $ lt_succ_of_le $ nat.div_le_self _ _,
      by conv {to_rhs, rw ← nat.mul_div_cancel' (mem_filter.1 hd).2}; simp⟩)
    (λ _ _, rfl)
    (λ a b ha hb h,
      have ha : a * (n / a) = n, from nat.mul_div_cancel' (mem_filter.1 ha).2,
      have 0 < (n / a), from nat.pos_of_ne_zero (λ h, by simp [*, lt_irrefl] at *),
      by rw [← nat.mul_left_inj this, ha, h, nat.mul_div_cancel' (mem_filter.1 hb).2])
    (λ b hb,
      have hb : b < n.succ ∧ b ∣ n, by simpa [-range_succ] using hb,
      have hbn : (n / b) ∣ n, from ⟨b, by rw nat.div_mul_cancel hb.2⟩,
      have hnb0 : (n / b) ≠ 0, from λ h, by simpa [h, ne.symm hn0] using nat.div_mul_cancel hbn,
      ⟨n / b, mem_filter.2 ⟨mem_range.2 $ lt_succ_of_le $ nat.div_le_self _ _, hbn⟩,
        by rw [← nat.mul_left_inj (nat.pos_of_ne_zero hnb0),
          nat.mul_div_cancel' hb.2, nat.div_mul_cancel hbn]⟩)
... = ∑ d in (range n.succ).filter (∣ n), ((range n).filter (λ m, gcd n m = d)).card :
  sum_congr rfl (λ d hd,
    have hd : d ∣ n, from (mem_filter.1 hd).2,
    have hd0 : 0 < d, from nat.pos_of_ne_zero (λ h, hn0 (eq_zero_of_zero_dvd $ h ▸ hd)),
    card_congr (λ m hm, d * m)
      (λ m hm, have hm : m < n / d ∧ gcd (n / d) m = 1, by simpa using hm,
        mem_filter.2 ⟨mem_range.2 $ nat.mul_div_cancel' hd ▸
          (mul_lt_mul_left hd0).2 hm.1,
          by rw [← nat.mul_div_cancel' hd, gcd_mul_left, hm.2, mul_one]⟩)
      (λ a b ha hb h, (nat.mul_right_inj hd0).1 h)
      (λ b hb, have hb : b < n ∧ gcd n b = d, by simpa using hb,
        ⟨b / d, mem_filter.2 ⟨mem_range.2
            ((mul_lt_mul_left (show 0 < d, from hb.2 ▸ hb.2.symm ▸ hd0)).1
              (by rw [← hb.2, nat.mul_div_cancel' (gcd_dvd_left _ _),
                nat.mul_div_cancel' (gcd_dvd_right _ _)]; exact hb.1)),
            hb.2 ▸ coprime_div_gcd_div_gcd (hb.2.symm ▸ hd0)⟩,
          hb.2 ▸ nat.mul_div_cancel' (gcd_dvd_right _ _)⟩))
... = ((filter (∣ n) (range n.succ)).bUnion (λ d, (range n).filter (λ m, gcd n m = d))).card :
  (card_bUnion (by intros; apply disjoint_filter.2; cc)).symm
... = (range n).card :
  congr_arg card (finset.ext (λ m, ⟨by finish,
    λ hm, have h : m < n, from mem_range.1 hm,
      mem_bUnion.2 ⟨gcd n m, mem_filter.2
        ⟨mem_range.2 (lt_succ_of_le (le_of_dvd (lt_of_le_of_lt (zero_le _) h)
          (gcd_dvd_left _ _))), gcd_dvd_left _ _⟩, mem_filter.2 ⟨hm, rfl⟩⟩⟩))
... = n : card_range _

/-- When `p` is prime, then the totient of `p ^ (n + 1)` is `p ^ n * (p - 1)` -/
lemma totient_prime_pow_succ {p : ℕ} (hp : p.prime) (n : ℕ) :
  φ (p ^ (n + 1)) = p ^ n * (p - 1) :=
calc φ (p ^ (n + 1))
    = ((range (p ^ (n + 1))).filter (coprime (p ^ (n + 1)))).card :
  totient_eq_card_coprime _
... = (range (p ^ (n + 1)) \ ((range (p ^ n)).image (* p))).card :
  congr_arg card begin
    rw [sdiff_eq_filter],
    apply filter_congr,
    simp only [mem_range, mem_filter, coprime_pow_left_iff n.succ_pos,
      mem_image, not_exists, hp.coprime_iff_not_dvd],
    intros a ha,
    split,
    { rintros hap b _ rfl,
      exact hap (dvd_mul_left _ _) },
    { rintros h ⟨b, rfl⟩,
      rw [pow_succ] at ha,
      exact h b (lt_of_mul_lt_mul_left ha (zero_le _)) (mul_comm _ _) }
  end
... = _ :
have h1 : set.inj_on (* p) (range (p ^ n)),
  from λ x _ y _, (nat.mul_left_inj hp.pos).1,
have h2 : (range (p ^ n)).image (* p) ⊆ range (p ^ (n + 1)),
  from λ a, begin
    simp only [mem_image, mem_range, exists_imp_distrib],
    rintros b h rfl,
    rw [pow_succ'],
    exact (mul_lt_mul_right hp.pos).2 h
  end,
begin
  rw [card_sdiff h2, card_image_of_inj_on h1, card_range,
    card_range, ← one_mul (p ^ n), pow_succ, ← tsub_mul,
    one_mul, mul_comm]
end

/-- When `p` is prime, then the totient of `p ^ ` is `p ^ (n - 1) * (p - 1)` -/
lemma totient_prime_pow {p : ℕ} (hp : p.prime) {n : ℕ} (hn : 0 < n) :
  φ (p ^ n) = p ^ (n - 1) * (p - 1) :=
by rcases exists_eq_succ_of_ne_zero (pos_iff_ne_zero.1 hn) with ⟨m, rfl⟩;
  exact totient_prime_pow_succ hp _

lemma totient_prime {p : ℕ} (hp : p.prime) : φ p = p - 1 :=
by rw [← pow_one p, totient_prime_pow hp]; simp

lemma totient_eq_iff_prime {p : ℕ} (hp : 0 < p) : p.totient = p - 1 ↔ p.prime :=
begin
  refine ⟨λ h, _, totient_prime⟩,
  replace hp : 1 < p,
  { apply lt_of_le_of_ne,
    { rwa succ_le_iff },
    { rintro rfl,
      rw [totient_one, tsub_self] at h,
      exact one_ne_zero h } },
  rw [totient_eq_card_coprime, range_eq_Ico, ←Ico_insert_succ_left hp.le, finset.filter_insert,
    if_neg (tactic.norm_num.nat_coprime_helper_zero_right p hp), ←nat.card_Ico 1 p] at h,
  refine p.prime_of_coprime hp (λ n hn hnz, finset.filter_card_eq h n $ finset.mem_Ico.mpr ⟨_, hn⟩),
  rwa [succ_le_iff, pos_iff_ne_zero],
end

lemma card_units_zmod_lt_sub_one {p : ℕ} (hp : 1 < p) [fintype (units (zmod p))] :
  fintype.card (units (zmod p)) ≤ p - 1 :=
begin
  haveI : fact (0 < p) := ⟨zero_lt_one.trans hp⟩,
  rw zmod.card_units_eq_totient p,
  exact nat.le_pred_of_lt (nat.totient_lt p hp),
end

lemma prime_iff_card_units (p : ℕ) [fintype (units (zmod p))] :
  p.prime ↔ fintype.card (units (zmod p)) = p - 1 :=
begin
  by_cases hp : p = 0,
  { substI hp,
    simp only [zmod, not_prime_zero, false_iff, zero_tsub],
    -- the substI created an non-defeq but subsingleton instance diamond; resolve it
    suffices : fintype.card (units ℤ) ≠ 0, { convert this },
    simp },
  haveI : fact (0 < p) := ⟨nat.pos_of_ne_zero hp⟩,
  rw [zmod.card_units_eq_totient, nat.totient_eq_iff_prime (fact.out (0 < p))],
end

@[simp] lemma totient_two : φ 2 = 1 :=
(totient_prime prime_two).trans (by norm_num)

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------


variables {α M N : Type*}



lemma finsupp.prod_congr [has_zero M] [comm_monoid N] {f : α →₀ M} (g1 g2 : α → M → N) :
  (∀ x ∈ f.support, g1 x (f x) = g2 x (f x)) → (f.prod g1 = f.prod g2) :=
fold_congr

-- TODO: Generalise this
lemma finsupp.prod_coe [has_zero M] {f : α →₀ M} (g : α → M → ℕ) :
  f.prod (λ a b, (↑(g a b):ℚ)) = ↑(f.prod g) :=
by push_cast [finsupp.prod]

---------------------------------------------------------------------------------------------------

theorem totient_Euler_product_formula (n:ℕ) :
  ↑(φ n) = ↑n * ∏ p in (n.factors.to_finset), (1 - p⁻¹:ℚ)
  :=
begin
-- If n = 0 then the identity holds trivially
  rcases n.eq_zero_or_pos with rfl | hn0, { simp },

-- Otherwise n is the product over its prime factorization
  nth_rewrite_rhs 0 (prime_factorization_prod_pow hn0),

-- Since φ is multiplicative (and primes are coprime) we can rewrite φ n
  rw (multiplicative_factorization hn0 (λ a b, totient_mul) totient_one),

-- So if we rebase the product over prime factors ...
  simp only [←(rebase_prod_prime_factorization (λ x, (1 - (↑x:ℚ)⁻¹)))],

-- ... we can gather the RHS into a single product
  simp only [←finsupp.prod_coe, ←finsupp.prod_mul],

-- So now it suffices to prove that the multiplicands are equal
  apply finsupp.prod_congr _ _,

  intros p hp,
  set k := n.prime_factorization p,

  have hpp : prime p := prime_of_mem_factors (factor_iff_mem_factorization.mp hp),
  have hp_pos : 0 < p := prime.pos hpp,
  have : (p : ℚ) ≠ 0 := cast_ne_zero.mpr hp_pos.ne',

  have hk : 0 < k, { rwa [finsupp.mem_support_iff, ←zero_lt_iff] at hp },
  rw totient_prime_pow hpp hk,

  -- Finally, we need to prove: ↑(p ^ (k - 1) * (p - 1)) = ↑p ^ k * (1 - (↑p)⁻¹)
  field_simp,
  push_cast [←(pow_sub_mul_pow ↑p hk), pow_one, mul_right_comm],
end




end nat
