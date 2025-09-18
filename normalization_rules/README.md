# Normalization Rules

This folder contains XSLT normalization rules for Alma.  

## Table of Contents
- [extract-dates-from-100a.xsl](#extract-dates-from-100axsl)  
  Moves date from 100 $a into a new 100 $d when $9 = no_linkage.  
- *(new rule)*
---
## extract-dates-from-100a.xsl
### Overview
Moves date ranges from **100 $a** into a new **100 $d**
### Conditions
- Field: `100`
- Requires: `100 $9 = "no_linkage"`
- Must **not** have an existing `100 $d`
- `100 $a` ends strictly with `YYYY-` **or** `YYYY-YYYY`, optionally followed by `.` or `,` and whitespace
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
