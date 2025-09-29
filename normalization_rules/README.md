# Normalization Rules

This folder contains XSLT normalization rules for Alma.  

## Table of Contents
| Rule Name | Brief Summary | Update Log |
|---|---|---|
| [file-size-test.xsl](#file-size-testxsl) | Matches 245 in one record against external dataset, if an exact match is found, returns TRUE in $9. This rule is for testing calling external documents in Alma only | *2025/09/29: Work in Progress*|
| [add-$e-in-100.xsl](#add-e-in-100xsl) | Matches relationship designator against lookup file, extract each term as individual $e | *2025/09/24: Work in Progress*|
| [add-$d-in-100-with-conditions.xsl](#add-d-in-100-with-conditionsxsl) | Moves date from 100 $a into a new 100 $d when $9 = no_linkage. | *2025/09/24: Allows embedded dates* |
| [replace-gmgpc-with-lctgm.xsl](#replace-gmgpc-with-lctgmxsl) | Replaces gmgpc with lctgm |  |

---
## file-size-test.xsl
### Overview 
Checks whether the `245` field of the current record exactly matches a `245` field in an external MARC dataset. If an exact match is found, it appends `$9` to `245` with value TRUE. This rule is used to test the file size limitation of calling external documents in Alma only.

*Note: Not in shared*

### Conditions
- Field: `245`
- Comparisons performed against an external MARC XML dataset (tested datasets are stored in [datasets folder](https://github.com/yalelibrary-metadata-services/alma_rules_testing/tree/main/datasets))
- Indicators, subfield, subfield order, and content must be exact match. 

### Testing Dataset
- See [datasets folder](https://github.com/yalelibrary-metadata-services/alma_rules_testing/tree/main/datasets)

### Output
- If an exact match exists in the called dataset, a new `$9` with value `TRUE` is appended in `245`.
- External files within GitHub’s size upload limit can be successfully called. 
- Files above 25 MB but under 100 MB cannot be uploaded via the GitHub web interface, but can be pushed through a local Git client/terminal.
- Git [Large File Storage](https://git-lfs.com/) can upload larger files but cannot perform lookups. 

### Future Considerations
- Test whether rules can follow index paths and locate the correct files based on conditions. 
- For datasets larger than 100 MB, explore splitting them into multiple smaller fies that can be called separately. 

---
## add-$e-in-100.xsl
### Overview 
Extracts relationship designators (e.g., author, illustrator) from `100 $a` and moves them into new `100 $e` subfields. Relator terms are validated against an external lookup file (rel_designator.xml). Relationship designator terms are extracted from original RDA toolkit.

*Note: Not in shared*

### Conditions
- Field `100`
- Requires: Relator terms must be listed in external [rel_designator.xml](https://github.com/yalelibrary-metadata-services/alma_rules_testing/blob/main/normalization_lookup/rel_designator.xml) lookup file
- Relator terms in `$a` are removed after being moved into `$e`
- Existing `$d` subfields are preserved if they are present. 
- Existing `$e` subfields are ignored when reconstructing new `$e`

### Testing Dataset
- Sample records extracted from previous `100` related datasets.

### Output
- New `100 $a` = name and any other content (erroneous or not), with relator terms removed
- New `100 $e` = one per matched relator term, validated from the lookup
- `$d` subfields are preserved in their original position after `$a`  
  *i.e., if the authorized access point needs to be correctly established later added `$e` will not interfere with reestablishing the link*
- Each `$e` includes a **comma after the term**, except the final one (no punctuation,  will be fixed)

### Sample
- Input: `100 1_ $a Pilkey, Dav, 1966- author, illustrator. $9 no_linkage`
- Output: `100 1_ $a Pilkey, Dav, 1966- $e author, $e illustrator $9 no_linkage` 

*Note: This rule intentionally does not fix the concatenated date; if needed, use the [add-$d-in-100-with-conditions](#add-d-in-100-with-conditionsxsl) rule to address dates.*

### Future Considerations
- Add period at the end of last `$e` unless other conditions exist
- Check for edge cases
- Figure out a way to filter out a dataset that has this issue in Alma?
- Prepare a more complete relationship designator lookup file, including additional agent roles beyond creators
---

## add-$d-in-100-with-conditions.xsl
### Overview
Moves date ranges from **100 $a** into a new **100 $d**
### Conditions
- Field: `100`
- Subfield:`$9 = "no_linkage"`
- Must **not** have an existing `100 $d`
- `100 $a` ends strictly with `YYYY-` **or** `YYYY-YYYY`, optionally followed by `.` or `,` and whitespace, either at the end of $a or embedded
- Ignores any number of `$e` relator terms when checking the next significant subfield

### Testing Dataset
- A filtered **books set** based on an indication rule requiring digits in `100 $a`, filtered by `008` = `eng`, filtered by `100` containing `$9` (institution-specific)  
- Pymarc was used to narrow down the dataset further, specifically to examine edge cases. 
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

### Conditions
- Fields: `650`, `655`, `690`
- Indcator: `ind2 = '7'`

### Output
- If a matching `$2` exists with **exact value** `gmgpc`, its content becomes `lctgm`.
- If any subfield text **contains** a concatenated `$2gmgpc`, that token is **removed from the text**, and a new `<subfield code="2">lctgm</subfield>` is **appended** to the same datafield.
- Runs only when `ind2='7'` to avoid touching fields that aren’t source-coded.

### Testing Dataset
- Filtered set prepared via **Alma Analytics** and **Set Filter** to include records where `gmgpc` appears in `650` and/or `655` (and applicable `690`) with `ind2=7`.
- Includes both well-formed `$2 gmgpc` and concatenated patterns like `$a ...$2gmgpc`.
