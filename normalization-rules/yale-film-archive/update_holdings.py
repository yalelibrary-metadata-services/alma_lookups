#!/usr/bin/env python3
"""
Download holdings record from Alma SRU API and commit to git.

Usage:
    python update_holdings.py
"""

import sys
import subprocess
import random
from datetime import datetime
from pathlib import Path
from xml.etree import ElementTree as ET

try:
    import requests
except ImportError:
    print("Error: requests library not found. Install with: pip install requests")
    sys.exit(1)


def run_command(cmd, description):
    """Run a shell command and handle errors."""
    print(f"{description}...", end=" ", flush=True)
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            capture_output=True,
            text=True
        )
        print("✓")
        return result.stdout
    except subprocess.CalledProcessError as e:
        print("✗")
        print(f"Error: Command failed with exit code {e.returncode}")
        if e.stderr:
            print(f"Stderr: {e.stderr}")
        if e.stdout:
            print(f"Stdout: {e.stdout}")
        print(f"Command was: {cmd}")
        sys.exit(1)


def main():
    # Display a random happy kaomoji with time-based greeting
    happy_kaomojis = [
        "(◕‿◕)",
        "(づ｡◕‿‿◕｡)づ",
        "ヽ(•‿•)ノ",
        "ฅ^>⩊<^ฅ",
        "₍^. .^₎⟆",
        "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧",
        "＼(^o^)／",
        "ദ്ദി（• ˕ •マ.ᐟ",
        "₊˚⊹♡ ᓚ₍ ^. .^₎",
        "°‧ 𓆝 𓆟 𓆞 ·｡",
        "(ﾉ´ヮ`)ﾉ*: ･ﾟ",
        "╰(*°▽°*)╯",
        "(★^O^★)",
        "(*^▽^*)",
        "ヽ(♡‿♡)ノ",
        "(=^･ω･^=)",
        "(=^‥^=)",
        "ฅ^•ﻌ•^ฅ",
        "(ᵔᴥᵔ)",
        "ʕ•ᴥ•ʔ",
        "ʕ￫ᴥ￩ʔ",
        "(ᵔᴥᵔ)ノ",
        "▼・ᴥ・▼",
        "U・ᴥ・U"
    ]
    kaomoji = random.choice(happy_kaomojis)

    # Determine greeting based on current time
    current_hour = datetime.now().hour
    if 5 <= current_hour < 12:
        greeting = "Good morning"
    elif 12 <= current_hour < 17:
        greeting = "Good afternoon"
    else:
        greeting = "Good evening"

    print(f"\n{kaomoji} {greeting}! Let's enhance some records!\n")

    # Prompt for number of SIP IDs
    while True:
        try:
            num_sips = input("How many SIP IDs do you have? Enter a number: ").strip()
            num_sips = int(num_sips)
            if num_sips < 1:
                print("Error: Please enter a number greater than 0.")
                continue
            break
        except ValueError:
            print("Error: Please enter a valid number.")

    # Prompt for SIP IDs
    sip_input = input("Please enter your SIP IDs separated by comma space: ").strip()

    # Parse and validate SIP IDs
    sip_ids = [sip.strip() for sip in sip_input.split(",")]
    sip_ids = [sip for sip in sip_ids if sip]  # Remove empty strings

    if len(sip_ids) == 0:
        print("Error: No valid SIP IDs entered.")
        sys.exit(1)

    if len(sip_ids) != num_sips:
        print(f"Warning: You said you have {num_sips} SIP IDs, but entered {len(sip_ids)}.")
        confirm = input(f"Continue with {len(sip_ids)} SIP ID(s)? (y/n): ").strip().lower()
        if confirm != 'y':
            sys.exit(0)

    print(f"Processing {len(sip_ids)} SIP ID(s): {', '.join(sip_ids)}")

    # Prompt user to choose environment
    print("Choose environment:")
    print("1. Production")
    print("2. Sandbox")
    choice = input("Enter choice (1 or 2): ").strip()

    if choice == "1":
        base_url = "https://yale.alma.exlibrisgroup.com/view/sru/01YALE_INST"
        env_name = "Production"
    elif choice == "2":
        base_url = "https://yale-psb.alma.exlibrisgroup.com/view/sru/01YALE_INST"
        env_name = "Sandbox"
    else:
        print("Error: Invalid choice. Please enter 1 or 2.")
        sys.exit(1)

    print(f"Using {env_name} environment")

    # Prompt user to choose save method
    print("\nChoose how to save the holdings record:")
    print("1. Git operations (commit and push to a git repository)")
    print("   - Saves file to your specified git repo directory")
    print("   - Automatically commits changes with timestamp")
    print("   - Pushes to remote repository")
    print("2. Download directly (save file locally without git)")
    print("   - Saves file to the same directory as this script")
    print("   - No git operations performed")

    save_choice = input("Enter choice (1 or 2): ").strip()

    if save_choice == "1":
        use_git = True
        # Prompt for repo directory
        default_repo_path = "/Users/dc2666/alma_rules_testing/datasets"
        print("\nEnter the path to your git repository where you want to save the file.")
        print(f"Press Enter for default: {default_repo_path}")
        print("Or enter a custom path:")
        repo_path_input = input("Repository path: ").strip()

        # Use default if empty or "default" is entered
        if not repo_path_input or repo_path_input.lower() == "default":
            repo_path_input = default_repo_path
            print(f"Using default path: {default_repo_path}")

        repo_dir = Path(repo_path_input)
        if not repo_dir.exists():
            print(f"Error: Directory not found: {repo_dir}")
            sys.exit(1)

        print(f"Navigating to {repo_dir}...", end=" ", flush=True)
        try:
            import os
            os.chdir(repo_dir)
            print("✓")
        except Exception as e:
            print("✗")
            print(f"Error changing directory: {e}")
            sys.exit(1)
    elif save_choice == "2":
        use_git = False
        # Use current directory where script is located
        import os
        script_dir = Path(os.path.dirname(os.path.abspath(__file__)))
        print(f"Will save to: {script_dir}")
    else:
        print("Error: Invalid choice. Please enter 1 or 2.")
        sys.exit(1)

    # Fetch XML for each SIP ID
    all_records = []
    namespaces = {}
    total_number_of_records = 0

    for idx, sip_id in enumerate(sip_ids, 1):
        print(f"[{idx}/{len(sip_ids)}] Downloading holdings record for SIP ID: {sip_id}...", end=" ", flush=True)

        # Construct URL parameters with maximumRecords=100
        params = {
            "version": "1.2",
            "operation": "searchRetrieve",
            "recordSchema": "marcxml",
            "query": f"alma.mms_sip_id={sip_id}",
            "maximumRecords": "100"
        }

        try:
            response = requests.get(base_url, params=params, timeout=30)
            response.raise_for_status()
            xml_content = response.text
            print("✓")
        except requests.exceptions.RequestException as e:
            print("✗")
            print(f"Error: Failed to download XML for SIP ID '{sip_id}': {e}")
            print(f"Stopping execution. No changes have been committed.")
            sys.exit(1)

        # Parse XML and extract records
        print(f"[{idx}/{len(sip_ids)}] Parsing XML for SIP ID: {sip_id}...", end=" ", flush=True)
        try:
            root = ET.fromstring(xml_content)

            # Capture namespaces from first response
            if idx == 1:
                # Extract namespaces from the root element
                for key, value in root.attrib.items():
                    if key.startswith('{http://www.w3.org/2000/xmlns/}'):
                        ns_name = key.split('}')[1] if '}' in key else ''
                        namespaces[ns_name] = value

            # Extract numberOfRecords from this response
            sru_ns = "{http://www.loc.gov/zing/srw/}"
            num_records_elem = root.find(f".//{sru_ns}numberOfRecords")
            if num_records_elem is not None and num_records_elem.text:
                try:
                    num_records_in_response = int(num_records_elem.text)
                    total_number_of_records += num_records_in_response
                except ValueError:
                    pass  # If we can't parse it, just skip adding to total

            # Find all record elements (adjust namespace as needed)
            # SRU responses typically have records in a specific namespace
            records = root.findall(".//{http://www.loc.gov/zing/srw/}record")

            if not records:
                # Try without namespace
                records = root.findall(".//record")

            if not records:
                print("✗")
                print(f"Error: No records found in response for SIP ID '{sip_id}'")
                print(f"Stopping execution. No changes have been committed.")
                sys.exit(1)

            all_records.extend(records)
            print(f"✓ (found {len(records)} record(s))")

        except ET.ParseError as e:
            print("✗")
            print(f"Error: Failed to parse XML for SIP ID '{sip_id}': {e}")
            print(f"Stopping execution. No changes have been committed.")
            sys.exit(1)
        except Exception as e:
            print("✗")
            print(f"Error: Unexpected error processing SIP ID '{sip_id}': {e}")
            print(f"Stopping execution. No changes have been committed.")
            sys.exit(1)

    # Combine all records into a single XML structure
    print(f"Combining {len(all_records)} record(s) into single XML file...", end=" ", flush=True)
    try:
        # Create root searchRetrieveResponse element
        sru_ns = "http://www.loc.gov/zing/srw/"
        ET.register_namespace('', sru_ns)
        ET.register_namespace('marc', "http://www.loc.gov/MARC21/slim")

        combined_root = ET.Element(f"{{{sru_ns}}}searchRetrieveResponse")

        # Add version element
        version_elem = ET.SubElement(combined_root, f"{{{sru_ns}}}version")
        version_elem.text = "1.2"

        # Add numberOfRecords element
        num_records_elem = ET.SubElement(combined_root, f"{{{sru_ns}}}numberOfRecords")
        num_records_elem.text = str(len(all_records))

        # Add records element
        records_elem = ET.SubElement(combined_root, f"{{{sru_ns}}}records")

        # Append all collected records
        for record in all_records:
            records_elem.append(record)

        # Convert to string with XML declaration and comment
        xml_string = ET.tostring(combined_root, encoding='unicode', method='xml')

        # Add comment with total number of records at the top
        xml_comment = f"<!-- Total number of records across all SIP queries: {total_number_of_records} -->"
        xml_content = f'<?xml version="1.0" encoding="UTF-8"?>\n{xml_comment}\n{xml_string}'

        print("✓")
    except Exception as e:
        print("✗")
        print(f"Error: Failed to combine XML records: {e}")
        print(f"Stopping execution. No changes have been committed.")
        sys.exit(1)

    # Save to file
    if use_git:
        output_file = Path("holdings_record.xml")
    else:
        output_file = script_dir / "holdings_record.xml"

    print(f"Saving to {output_file}...", end=" ", flush=True)
    try:
        output_file.write_text(xml_content, encoding="utf-8")
        print("✓")
    except Exception as e:
        print("✗")
        print(f"Error: Failed to save file: {e}")
        if use_git:
            print(f"Stopping execution. No changes have been committed.")
        sys.exit(1)

    # Perform git operations only if user chose that option
    if use_git:
        # Git add
        run_command("git add holdings_record.xml", "Adding to git")

        # Check if there are changes to commit
        print("Checking for changes...", end=" ", flush=True)
        result = subprocess.run(
            "git status --porcelain",
            shell=True,
            capture_output=True,
            text=True
        )

        if not result.stdout.strip():
            print("✓")
            print("\nNo changes detected - holdings record is identical to existing file.")
            print("Skipping commit and push.")
        else:
            print("✓")
            # Git commit
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            if len(sip_ids) == 1:
                commit_message = f"Update holdings record with SIP ID: {sip_ids[0]} - {timestamp}"
            else:
                commit_message = f"Update holdings record with SIP IDs: {', '.join(sip_ids)} - {timestamp}"

            run_command(
                f'git commit -m "{commit_message}"',
                "Committing changes"
            )

            # Git push
            run_command("git push", "Pushing to remote")

    # Success message
    if len(sip_ids) == 1:
        print(f"\nSuccess! Holdings record updated for SIP ID: {sip_ids[0]}")
    else:
        print(f"\nSuccess! Holdings record updated for {len(sip_ids)} SIP IDs: {', '.join(sip_ids)}")

    if not use_git:
        print(f"File saved to: {output_file}")


if __name__ == "__main__":
    main()
