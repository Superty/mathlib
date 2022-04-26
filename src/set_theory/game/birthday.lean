/-
Copyright (c) 2022 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/

import set_theory.game.ordinal
import set_theory.ordinal.arithmetic

/-!
# Birthdays of games

The birthday of a game is an ordinal that represents at which "step" the game was constructed. We
define it recursively as the least ordinal larger than the birthdays of its left and right games. We
prove the basic properties about these.

# Main declarations

- `pgame.birthday`: The birthday of a pre-game.

# Todo

- Define the birthdays of `game`s and `surreal`s.
- Characterize the birthdays of basic arithmetical operations.
-/

universe u

open ordinal

namespace pgame

/-- The birthday of a pre-game is inductively defined as the least strict upper bound of the
birthdays of its left and right games. It may be thought as the "step" in which a certain game is
constructed. -/
noncomputable def birthday : pgame.{u} → ordinal.{u}
| ⟨xl, xr, xL, xR⟩ :=
    max (lsub.{u u} $ λ i, birthday (xL i)) (lsub.{u u} $ λ i, birthday (xR i))

theorem birthday_def (x : pgame) : birthday x = max
  (lsub.{u u} (λ i, birthday (x.move_left i)))
  (lsub.{u u} (λ i, birthday (x.move_right i))) :=
by { cases x, rw birthday, refl }

theorem birthday_move_left_lt {x : pgame} (i : x.left_moves) :
  (x.move_left i).birthday < x.birthday :=
by { cases x, rw birthday, exact lt_max_of_lt_left (lt_lsub _ i) }

theorem birthday_move_right_lt {x : pgame} (i : x.right_moves) :
  (x.move_right i).birthday < x.birthday :=
by { cases x, rw birthday, exact lt_max_of_lt_right (lt_lsub _ i) }

theorem lt_birthday_iff {x : pgame} {o : ordinal} : o < x.birthday ↔
  (∃ i : x.left_moves, o ≤ (x.move_left i).birthday) ∨
  (∃ i : x.right_moves, o ≤ (x.move_right i).birthday) :=
begin
  split,
  { rw birthday_def,
    intro h,
    cases lt_max_iff.1 h with h' h',
    { left,
      rwa lt_lsub_iff at h' },
    { right,
      rwa lt_lsub_iff at h' } },
  { rintro (⟨i, hi⟩ | ⟨i, hi⟩),
    { exact hi.trans_lt (birthday_move_left_lt i) },
    { exact hi.trans_lt (birthday_move_right_lt i) } }
end

theorem relabelling.birthday_congr : ∀ {x y : pgame.{u}}, relabelling x y → birthday x = birthday y
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨L, R, hL, hR⟩ := begin
  rw [birthday, birthday],
  congr' 1,
  all_goals
  { apply lsub_eq_of_range_eq.{u u u},
    ext i,
    split },
  { rintro ⟨j, rfl⟩,
    exact ⟨L j, (relabelling.birthday_congr (hL j)).symm⟩ },
  { rintro ⟨j, rfl⟩,
    refine ⟨L.symm j, relabelling.birthday_congr _⟩,
    convert hL (L.symm j),
    rw L.apply_symm_apply },
  { rintro ⟨j, rfl⟩,
    refine ⟨R j, (relabelling.birthday_congr _).symm⟩,
    convert hR (R j),
    rw R.symm_apply_apply },
  { rintro ⟨j, rfl⟩,
    exact ⟨R.symm j, relabelling.birthday_congr (hR j)⟩ }
end
using_well_founded { dec_tac := pgame_wf_tac }

@[simp] theorem birthday_zero : birthday 0 = 0 :=
by rw [birthday_def, lsub_empty, lsub_empty, max_self]

@[simp] theorem neg_birthday : ∀ x : pgame, (-x).birthday = x.birthday
| ⟨xl, xr, xL, xR⟩ := begin
  rw [birthday_def, birthday_def, max_comm],
  congr; funext; apply neg_birthday
end

@[simp] theorem to_pgame_birthday (o : ordinal) : o.to_pgame.birthday = o :=
begin
  induction o using ordinal.induction with o IH,
  rw pgame.birthday_def,
  convert max_eq_left_iff.2 (ordinal.zero_le _),
  { apply lsub_empty },
  { nth_rewrite_lhs 0 ←lsub_typein o,
    congr,
    { exact (to_pgame_left_moves o).symm },
    { apply function.hfunext (to_pgame_left_moves o).symm,
      rintro a b h,
      have hwf := typein_lt_self a,
      have : to_left_moves_to_pgame a = b := cast_eq_iff_heq.2 h,
      rw [←this, to_pgame_move_left, IH _ (typein_lt_self a)] } }
end

theorem le_birthday (x : pgame) : x ≤ x.birthday.to_pgame :=
begin
  suffices : ∀ (o : ordinal) (y : pgame), y.birthday = o → y ≤ o.to_pgame,
  { exact this _ x rfl },
  { intro o,
    induction o using ordinal.induction with o IH,
    rintros x rfl,
    rw le_def,
    refine ⟨λ i, or.inl _, is_empty_elim⟩,
    have := birthday_move_left_lt i,
    use to_left_moves_to_pgame (enum (<) (x.move_left i).birthday (by rwa type_lt)),
    simp [IH _ this] }
end

theorem neg_birthday_le (x : pgame) : -x.birthday.to_pgame ≤ x :=
let h := le_birthday (-x) in by rwa [neg_birthday, le_iff_neg_ge, neg_neg] at h

end pgame
