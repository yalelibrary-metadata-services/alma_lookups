# Normalization Rules

This folder contains XSLT normalization rules related to Yale Film Archive for Alma.

## Table of Contents
| Rule Name | Brief Summary | Update Log |
|---|---|---|
| [(archived) 852-random.xsl](#852-randomxsl) | It adds a randomly generated number + four letter id to each holdings record in 852 `$h` | *2025/10/23 No longer in use. Replaced by the process adding 001* |
| [099-holdings.xsl](#099-holdingsxsl) | Matches 001 in holdings and `$8` in `tag="AVA"`in lookup dataset, adds  the correct call number in 852 `$h` from 099 `$a` in bib, adds blank 866 with reel 1 | *2025/10/23 Uniquely generated ID replaced by 001* |
| [866-reels.xsl](#866-reelsxsl) | Matches call number against lookup dataset, checks 300 `$a`, adds -reel # in holdings 866 if there is more than 1 reel | *2025/10/21: Can be added in a process with other rules* |

---
## Yale Film Archive Records Workflow

| Step | System | Action | Output |
|---|---|---|---|
| 1: Import Records | Alma | Import YFA marc records via MSU-YFA Import Profile | A set of records with incomplete holdings information |
| 2: Create a physical holdings set | Alma | Click the three dots next to the recent import profile job → Click "Imported Records" → "Create and Filter Set" → Provide relevant information and set content type as **"Physical Holdings"** | A set of holdings records with incomplete information |
| 3: Add 001 to holdings | Alma | Run "Change Holdings Information" job in Admin → Select the set from Step 2 → Check "Correct the data using norm processes" → Select MSU-YFA-001. This existing task adds the correct 001 (holdings ID) to the holdings record. | A set of holdings records with its holdings ID in 001 |
| 4: Prepare Lookup Dataset | Terminal (SRU and GitHub) | Clone this repository or download `update_holdings.py` from this folder. Run the script and follow its instructions. See [manual steps](#what-does-the-update_holdingspy-script-do-and-can-i-do-it-manually) for detailed explanation or if you prefer to do it manually. | A lookup dataset in GitHub |
| 5: Add call number, reels #, etc to holdings | Alma | Repeat Step 3 and run the process `MSU-YFA-complete`. The process first runs [099-holdings.xsl](#099-holdingsxsl), then runs  [866-reels.xsl](#866-reelsxsl), runs an existing DROOL rule that adds indicator 2 in 852 based on existing 866, and resequence all the fields appropriately. | A set of holdings records with complete information. |

---
## Possible Questions
### How to add a norm rule for holdings in Processes so it shows up when we run the Change Holdings Information job?
Navigate through the following path in Alma:
Configuration → Metadata Configuration → Active Profiles → MARC21 Holding → Normalization Processes → Add Process → **Provide relevant details** → Add Tasks → **Select** MARC XSL Normalization → **Select** relevant XSL File Key (Normalization Rule Name) → Save

**Note:** Holdings normalization rules will not appear in General → Processes. They must be added under MARC21 Holding as described above.
### What is the rule naming convention in Alma?
The same as how it is named in the folder, plus a prefix (MSU, MSU-DC, or MSU-YFA).
### Where do I find the mms_sip_id for querying?
In Alma, navigate to the prepared dataset → Click "Content" → You will see the `mms_sip_id` in the query. It will display as "MMS SIP ID Contains Keywords 'xxxxxx'"
### What is Search/Retrieve via URL (SRU)?
SRU is a search protocol for searching and retrieving records. See the [ExLibris SRU documentation](https://developers.exlibrisgroup.com/alma/integrations/SRU/) for further information.
### What does the update_holdings.py script do? And can I do it manually?

**Note:** The script will be uploaded to this folder soon. In the meantime, follow the manual steps below.

Yes! The script automates the SRU query and file management process. Here are the manual steps:

#### 1. Query the SRU API
Use this URL template, replacing `YOUR_MMS_SIP_ID` with your set's MMS SIP ID:
```
https://yale-psb.alma.exlibrisgroup.com/view/sru/01YALE_INST?version=1.2&operation=searchRetrieve&recordSchema=marcxml&query=alma.mms_sip_id=YOUR_MMS_SIP_ID&maximumRecords=100
```
**For production environment:** Remove `-psb` from the URL:
```
https://yale.alma.exlibrisgroup.com/view/sru/01YALE_INST?version=1.2&operation=searchRetrieve&recordSchema=marcxml&query=alma.mms_sip_id=YOUR_MMS_SIP_ID&maximumRecords=100
```
**Note:** The `maximumRecords=100` parameter is important—without it, SRU only returns the first 10 records even when more exist in the set. The number 100 is arbitrary; it's unlikely to exceed 50 records in one SIP ID since Alma breaks import jobs into smaller files.


#### 2. Download the XML
**IMPORTANT:** The file must be named exactly `holdings_record.xml` for the normalization rules to work correctly.

Choose one of these methods:
**Option 1 - Edit Directly in GitHub:**
- Open [`holdings_record.xml`](https://github.com/yalelibrary-metadata-services/alma_rules_testing/blob/main/datasets/holdings_record.xml) in the GitHub repository
- Click the "Edit" button (pencil icon)
- Replace all content with the XML from your SRU query or queries
- Commit the changes

**Option 2 - Copy/Paste:**
- Copy the XML from your browser
- Open the existing [`holdings_record.xml`](https://github.com/yalelibrary-metadata-services/alma_rules_testing/blob/main/datasets/holdings_record.xml) file locally
- Replace all content with the copied XML
- Save the file (keeping the exact filename)

**Option 3 - Command Line:**
```bash
curl "YOUR_FULL_QUERY_URL" -o holdings_record.xml
```
*(Works on Mac, Linux, and Windows 10+ with curl installed)*

This saves `holdings_record.xml` to your current directory. Replace the existing file in the `datasets/` directory with this one.

#### 3. Process Multiple SIP IDs (if applicable)
If you have multiple SIP IDs:
- Repeat steps 1-2 for each SIP ID
- Combine all `<record>` elements into a single file
- Ensure the final file is still named `holdings_record.xml`

#### 4. Commit to Repository
- If you edited directly in GitHub (Option 1), you're done!
- If you used Option 2 or 3, commit and push `holdings_record.xml` to the `datasets/` directory

This file serves as the lookup dataset for Step 5 of the workflow.
###