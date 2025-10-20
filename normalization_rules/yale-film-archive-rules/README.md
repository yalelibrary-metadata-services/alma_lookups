# Normalization Rules

This folder contains XSLT normalization rules related to Yale Film Archive for Alma. (WIP)

## Table of Contents
| Rule Name | Brief Summary | Update Log |
|---|---|---|
| [852-random.xsl](#852-randomxsl) | Adds a randomly generated four numerals + four letter id to each holdings record in 852 `$h` | *2025/10/20: Work in Progress* |
| [099-holdings.xsl](#099-holdingsxsl) | Matches generated ID in lookup dataset, replaces generated ID in 852 `$h` in holdings with the correct call number from 099 `$a` in bib, adds blank 866 with reel 1 | *2025/10/20: Work in Progress: What happens when unqique ID is not `$d` in query?* |
| [866-reels.xsl](#866-reelsxsl) | Matches call number against lookup dataset, checks 300 `$a`, adds -reel # in holdings 866 if there is more than 1 reel | *2025/10/22: Testing whether it can be added directly in [099-holdings.xsl](#099-holdingsxsl)*|

---
## Yale Film Archive Records Workflow

| Step | System | Action | Output |
|---|---|---|---|
| 1 | Alma | Import YFA marc records via MSU-YFA Import Profile | A set of records with incomplete holdings information |
| 2 | Alma | Create a physical holdings set: Click the three dots next to the recent import profile job → Click "Imported Records" → "Create and Filter Set" → Provide relevant information and set content type as "Physical Holdings" | A set of holdings records with incomplete information |
| 3 | Alma | Run "Change Holdings Information" job in Admin → Select the set from Step 2 → Check "Correct the data using norm processes" → Select [852-random.xsl](#852-randomxsl) | A set of holdings records with a unique generated ID in 852 `$h` |
| 4 | SRU | Run a [SRU query](https://yale-psb.alma.exlibrisgroup.com/view/sru/01YALE_INST?version=1.2&operation=searchRetrieve&recordSchema=marcxml&query=alma.mms_sip_id=263359): First replace the `mms_sip_id` at the end of the link with your set's mms_sip_id → Confirm the generated ID is present in tag="AVA" (Note: SRU query's holding record subfield code does NOT correspond to the subfield code in Alma. Do not panic if the subfield code is `$d` and not `$h`) | A query of a set of records (bib and holdings) with unique generated ID in `tag="AVA"` |
| 5 | SRU, GitHub | Download the query as XML and then upload it to GitHub repo. **Option 1:** Copy and paste it into an XML file. **Option 2:** Run this in terminal (Mac): `curl "query link" -o $HOME/Desktop/holding_record.xml` | A set of records in XML that allows us to perform lookup via normalization rule |
| 6 | Alma | Repeat Step 3 and run [099-holdings.xsl](#099-holdingsxsl) | A set of holdings records with the correct call number in 852 `$h` and generic 866 with reel 1 in `$a` |
| 7 | Alma | Repeat Step 3 and run [866-reels.xsl](#866-reelsxsl) | A set of holdings records with -reel # in holdings 866 `$a` if there is more than 1 reel|

---
## Possible Questions
### How to add a norm rule for holdings in Processes so it shows up when we run the Change Holdings Information job?
Navigate through the following path in Alma:
Configuration → Metadata Configuration → Active Profiles → MARC21 Holding → Normalization Processes → Add Process → Provide relevant details → Add Tasks → Select MARC XSL Normalization → Select relevant XSL File Key (Normalization Rule Name) → Save

**Note:** Holdings normalization rules will not appear in General → Processes. They must be added under MARC21 Holding as described above.
### What is the rule naming convention in Alma?
The same as how it is named in the folder, plus a prefix (MSU, MSU-DC, or MSU-YFA).
### Where do I find the mms_sip_id for querying?
In Alma, navigate to the prepared dataset → Click "Content" → You will see the `mms_sip_id` in the query. It will display as "MMS SIP ID Contains Keywords 'xxxxxx'"
### What is Search/Retrieve via URL (SRU)?
SRU is a search protocol for searching and retrieving records. See the [ExLibris SRU documentation](https://developers.exlibrisgroup.com/alma/integrations/SRU/) for further information.
###
---
## 852-random.xsl
### Overview
---
## 099-holdings.xsl
### Overview 
---
## 866-reels.xsl
### Overview