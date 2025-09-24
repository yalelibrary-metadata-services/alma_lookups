# Normalization Rules

This folder contains XSLT normalization rules for Alma.  

## Table of Contents
|Rule Name|Brief Summary|Update Log|
|---|---|---|
|[add-$e-in-100.xsl](#add-$e-in-100xsl)|Matches relationship designator against lookup file, extract each term as individual $e|Work in Progress|
|[add-$d-in-100-with-conditions.xsl](#add-$d-in-100-with-conditionsxsl)|Moves date from 100 $a into a new 100 $d when $9 = no_linkage.|*2025/09/24: Allows embedded dates*|
|[replace-gmgpc-with-lctgm.xsl](#replace-gmgpc-with-lctgmxsl)|Replaces gmgpc with lctgm|  |
---
## add-$e-in-100.xsl
### Overview 
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\
.\













## add-$d-in-100-with-conditions.xsl
### Overview
Moves date ranges from **100 $a** into a new **100 $d**
### Conditions
- Field: `100`
- Requires: `100 $9 = "no_linkage"`
- Must **not** have an existing `100 $d`
- `100 $a` ends strictly with `YYYY-` **or** `YYYY-YYYY`, optionally followed by `.` or `,` and whitespace, either at the end of $a or embedded
- Ignores any number of `$e` relator terms when checking the next significant subfield

### Testing Dataset
- A filtered **books set** based on an indication rule requiring digits in `100 $a`, filtered by `008` = `eng`, filtered by `100` containing `$9` (institution-specific)  
- Out of ~9,000 records, about 8,500+ were affected by this rule

### Output
- New `100 $a` = name only, with trailing `", "`
- New `100 $d` = space + dates; punctuation:
  - `YYYY-YYYY` → period if `$9` immediately follows `$a`, else comma
  - `YYYY-` (open range) → no trailing punctuation
- Preserves original subfield order (inserts `$d` after rewritten `$a`)

### Sample
- Input: `100  $a Campbell, John Campbell, Baron, 1779-1861. $e author. $9 no_linkage`
- Output: `100  $a Campbell, John Campbell, Baron, $d 1779-1861, $e author. $9 no_linkage`
- Input: `$a Yeboah, Anthony K. (Anthony Kwadwo), 1957- $e author. $9 no_linkage`
- Output: `$a Yeboah, Anthony K. (Anthony Kwadwo), $$d 1957- $$e author. $9 no_linkage`
- Intput: `$a Dubin, Dale, 1940- $9 no_linkage`
- Output: `$a Dubin, Dale, $d 1940- $9 no_linkage`
### Future Considerations
This rule may later be expanded to cover additional cataloging practices, such as:
- Dates with question marks (`1779?-1861?`)
- Words like *approximately* or *century*
- Three-digit dates for early resources
- etc

---

## replace-gmgpc-with-lctgm.xsl

### Overview
Normalizes subject/thesaurus source codes by replacing **`$2 gmgpc`** with **`$2 lctgm`** in **650/655/690** when **indicator 2 = 7**. Also fixes cases where the `$2` is incorrectly concatenated into another subfield’s text (e.g., `$a ...$2gmgpc`), extracting it and emitting a correct `$2 lctgm`.

### Scope & Preconditions
- Fields: `650`, `655`
- Condition: `ind2 = '7'`
- Targets:
  - Proper `$2 gmgpc` subfields → change to `$2 lctgm`
  - Malformed text containing `$2gmgpc` (e.g., in `$a`) → remove the stray token from the text and append a proper `$2 lctgm`

### Behavior
- If a matching `$2` exists with **exact value** `gmgpc`, its content becomes `lctgm`.
- If any subfield text **contains** a concatenated `$2gmgpc`, that token is **removed from the text**, and a new `<subfield code="2">lctgm</subfield>` is **appended** to the same datafield.
- Leaves other `$2` values unchanged.
- Runs only when `ind2='7'` to avoid touching fields that aren’t source-coded.

### Testing Dataset
- Filtered set prepared via **Alma Analytics** and **Set Filter** to include records where `gmgpc` appears in `650` and/or `655` (and applicable `690`) with `ind2=7`.
- Includes both well-formed `$2 gmgpc` and concatenated patterns like `$a ...$2gmgpc`.

### Files
- `replace-gmgpc-with-lctgm.xsl` — transformation for 650/655/690 with `ind2=7`
