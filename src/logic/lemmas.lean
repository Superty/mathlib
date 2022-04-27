/-
Copyright (c) 2022 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import tactic.split_ifs

/-!
# More basic logic properties

A few more lemmas that could not be in `logic.basic` because of import cycles.
-/

variables {α : Type*} {p q r : Prop} [decidable p] [decidable q] {a b c : α}

lemma dite_dite_distrib_left {a : p → α} {b : ¬ p → q → α} {c : ¬ p → ¬ q → α} :
  dite p a (λ hp, dite q (b hp) (c hp)) =
    dite q (λ hq, dite p a $ λ hp, b hp hq) (λ hq, dite p a $ λ hp, c hp hq) :=
by split_ifs; refl

lemma dite_dite_distrib_right {a : p → q → α} {b : p → ¬ q → α} {c : ¬ p → α} :
  dite p (λ hp, dite q (a hp) (b hp)) c =
    dite q (λ hq, dite p (λ hp, a hp hq) c) (λ hq, dite p (λ hp, b hp hq) c) :=
by split_ifs; refl

lemma ite_ite_distrib_left : ite p a (ite q b c) = ite q (ite p a b) (ite p a c) :=
dite_dite_distrib_left

lemma ite_ite_distrib_right : ite p (ite q a b) c = ite q (ite p a c) (ite p b c) :=
dite_dite_distrib_right
