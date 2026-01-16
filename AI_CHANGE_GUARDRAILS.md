# AI Change Guardrails & Project Invariants

## Purpose

This document defines **non‑negotiable rules** for any AI tool (ChatGPT, Antigravity, Gemini, Cursor, Copilot, etc.) interacting with this repository.

The goal is to **protect business‑critical logic, database integrity, and financial correctness**.

Any AI‑suggested change that violates this document **must be rejected**.

---

## ABSOLUTE RULES (DO NOT VIOLATE)

### 1. Database Schema Is Read‑Only

AI is **NOT allowed** to:

* Rename tables
* Rename columns
* Drop tables or columns
* Add new columns without explicit human instruction
* Reorder or reinterpret existing fields
* Normalize, denormalize, or redesign schema

The database schema is a **stable contract** used across the entire application.

---

### 2. Money, Ledger & Accounting Logic Is Human‑Owned

AI must **NOT modify**:

* Money calculations
* Ledger balance logic
* Debit / credit flows
* Cancel / reverse sale logic
* Stock quantity adjustments
* Rounding or currency handling

AI may only:

* Explain existing logic
* Identify potential bugs
* Suggest fixes **without changing behavior**

---

### 3. No Cross‑Layer Changes

AI must **never change multiple layers at once**.

Disallowed combinations:

* UI + Database
* UI + Repository
* Repository + Database
* Logic + Schema

Each change must stay **within one layer only**.

---

### 4. No Silent Renames

AI must **never rename**:

* Classes
* Methods
* Variables
* Files
* Routes

Unless explicitly instructed by a human.

Renames break hidden dependencies.

---

## ALLOWED AI TASKS

AI **may assist** with:

* UI layout cleanup (spacing, widgets, styling)
* Code formatting
* Readability improvements
* Commenting and documentation
* Explaining code behavior
* Identifying dead code (without deleting it)
* Suggesting UI/UX improvements **conceptually**

---

## UI/UX‑SPECIFIC RULES

When working on UI/UX, AI must:

* Not touch business logic
* Not touch repositories
* Not touch models
* Not touch database helpers

UI changes must be:

* Visual only
* Layout only
* Component‑level

---

## REQUIRED AI BEHAVIOR

Before suggesting changes, AI must:

1. State **which file** it will change
2. State **what layer** it belongs to
3. Confirm **no schema or logic change** will occur

If this confirmation cannot be made, the change is rejected.

---

## CHANGE REVIEW POLICY

Every AI suggestion must be reviewed by a human.

Blind acceptance is **strictly forbidden**.

If unsure:

* Reject the change
* Ask for explanation
* Compare with this document

---

## FAILURE MODE ACKNOWLEDGEMENT

This project previously suffered severe regressions due to:

* Blind AI acceptance
* Schema modifications
* Cross‑layer refactors

This document exists to **prevent recurrence**.

---

## FINAL DECLARATION

> AI is an **assistant**, not an **architect**.
>
> Structural decisions belong to humans.
>
> Stability is more important than speed.

---

**All AI tools must comply with this document before making any suggestion or modification.**
