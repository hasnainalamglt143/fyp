import subprocess
import time
import random
from datetime import datetime
import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import logging
import json
import os
from selenium.common.exceptions import StaleElementReferenceException, TimeoutException

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def resolve_path(*parts):
    return os.path.join(BASE_DIR, *parts)

# File paths
output_path = resolve_path('enriched_leads_data.csv')  # Output CSV
missed_path = resolve_path('missed_leads.csv')  # Missed leads

# Records to generate per run
record_count = 5

# Ensure output CSV exists with correct columns
os.makedirs(os.path.dirname(output_path), exist_ok=True)
if not os.path.exists(output_path) or os.path.getsize(output_path) == 0:
    pd.DataFrame(columns=[
        "lead_source",
        "lead_age_days",
        "days_since_last_interaction",
        "total_interactions",
        "response_time_hours",
        "industry",
        "lead_status",
        "next_best_action",
        "lead_name",
        "confidence_score"
    ]).to_csv(output_path, index=False)
    print(f"'{output_path}' created with headers.")

# Start Chrome with remote debugging
chrome_path = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
remote_debugging_port = '9222'
user_data_dir = r'C:\Users\Muhammad Hasnain\AppData\Local\Google\Chrome\User Data\Profile 3'

cmd = f'"{chrome_path}" --remote-debugging-port={remote_debugging_port} --user-data-dir="{user_data_dir}"'
process = subprocess.Popen(cmd, shell=True)
print("Chrome launched with remote debugging.")

# Prompt user to manually log in and navigate to ChatGPT
input("Press Enter after you have navigated to the ChatGPT chat box and logged in. Make sure Chrome is still open...")

# Configure Selenium to attach to the existing Chrome session
chrome_options = Options()
chrome_options.add_experimental_option("debuggerAddress", "localhost:9222")

try:
    print("Attempting to connect to Chrome...")
    driver = webdriver.Chrome(options=chrome_options)
    print("Connected to Chrome. Current page title: " + driver.title)
except Exception as e:
    logging.error(f"Failed to connect to Chrome: {e}")
    print(f"Failed to connect to Chrome: {e}")
    exit()

# Function to add random delay
def random_delay(min_delay=2, max_delay=4):
    time.sleep(random.uniform(min_delay, max_delay))

# Function to send the initial requirements prompt
def send_requirements_prompt():
    requirements_text = """
    You are a CRM data generator. For each lead/company name I provide, generate realistic sales engagement data.

    Return ONLY a JSON array with objects containing these exact fields:
    
    - lead_source: Where this lead came from (choose from: "Website", "Referral", "Social Media", "Email Campaign", "Event", "Cold Call", "Partner", "Advertisement")
    - lead_age_days: Number of days since lead was created (integer between 1 and 90)
    - days_since_last_interaction: Days since last contact (integer between 0 and 60)
    - total_interactions: Total number of touches/interactions (integer between 0 and 25)
    - response_time_hours: Average response time in hours (float between 0.5 and 72)
    - industry: Industry sector (choose from: "Technology", "Healthcare", "Finance", "Retail", "Manufacturing", "Education", "Real Estate", "Transportation", "Hospitality", "Professional Services")
    - lead_status: Current status (choose from: "New", "Contacted", "Qualified", "Proposal Sent", "Negotiation", "Won", "Lost", "Disqualified")
    - next_best_action: Recommended next action (choose from: "Schedule Call", "Send Email", "Share Proposal", "Request Demo", "Follow Up", "Send Contract", "Schedule Meeting", "Add to Nurture Campaign")
    - confidence_score: How confident you are in this data (integer 0-100)

    Generate realistic, varied data that makes logical sense.
    Respond strictly in JSON array format only. No explanations.
    """
    try:
        input_box = WebDriverWait(driver, 15).until(
            EC.visibility_of_element_located((By.ID, 'prompt-textarea'))
        )
        input_box.click()
        input_box.clear()
        input_box.send_keys(requirements_text)
        random_delay()
        input_box.send_keys(Keys.RETURN)
        print("✅ Initial requirements prompt sent successfully.")
        random_delay(5, 8)
    except Exception as e:
        logging.error(f"Failed to send requirements prompt: {e}")
        print(f"Failed to send requirements prompt: {e}")

# Function to request CRM records without input CSV
def send_generation_prompt(count):
    prompt_text = (
        f"Generate {count} CRM records. Return ONLY a JSON array with objects containing these exact fields: "
        "lead_source (choose from Website, Referral, Social Media, Email Campaign, Event, Cold Call, Partner, Advertisement), "
        "lead_age_days (integer 1-90), days_since_last_interaction (integer 0-60), total_interactions (integer 0-25),"
        "response_time_hours (float 0.5-72), industry (choose which can be automated through an erp software(eg:Technology, Healthcare, Finance, Retail, Manufacturing,"
        "Education, Real Estate, Transportation, Hospitality, Professional Services), lead_status (choose from New, "
        "Contacted, Qualified, Proposal Sent, Negotiation, Won, Lost, Disqualified), next_best_action (choose like "
        "Schedule Call, Send Email, Share Proposal, Request Demo, Follow Up, Send Contract, Schedule Meeting, etc "
        "Add to Nurture Campaign), lead_name (realistic company name), confidence_score (integer 0-100). "
        "Make the data realistic and varied. No explanations."
    )

    retries = 3
    for attempt in range(retries):
        try:
            input_box = WebDriverWait(driver, 15).until(
                EC.visibility_of_element_located((By.ID, 'prompt-textarea'))
            )
            input_box.click()
            input_box.clear()
            
            for char in prompt_text:
                input_box.send_keys(char)
                time.sleep(0.008)
            
            random_delay()
            input_box.send_keys(Keys.RETURN)
            print(f"✅ Generation prompt sent for {count} records")
            random_delay(8, 12)
            return True
            
        except (StaleElementReferenceException, TimeoutException):
            print(f"⚠️ Error sending batch, retrying... (Attempt {attempt + 1}/{retries})")
            time.sleep(3)
        except Exception as e:
            logging.error(f"Error during batch prompt send: {e}")
    
    print("❌ Failed to send batch prompt after 3 attempts")
    return False

# Extract and parse JSON response from ChatGPT
def extract_response(max_wait=90, poll_interval=5):
    try:
        print("⏳ Waiting for ChatGPT response...")
        deadline = time.time() + max_wait

        possible_selectors = [
            "pre code",
            "div.markdown code",
            "code.language-json",
            "div[data-message-author-role='assistant'] code",
            "div.overflow-y-auto pre"
        ]

        while time.time() < deadline:
            responses = []

            for selector in possible_selectors:
                elements = driver.find_elements(By.CSS_SELECTOR, selector)
                if elements:
                    for e in elements:
                        response_text = e.text.strip()
                        if response_text:
                            if response_text.startswith('```json'):
                                response_text = response_text[7:]
                            if response_text.startswith('```'):
                                response_text = response_text[3:]
                            if response_text.endswith('```'):
                                response_text = response_text[:-3]
                            response_text = response_text.strip()

                            try:
                                data = json.loads(response_text)
                                if isinstance(data, list):
                                    responses.extend(data)
                                elif isinstance(data, dict):
                                    responses.append(data)
                                if responses:
                                    print(f"✅ Successfully parsed JSON response with {len(responses)} records")
                                    return responses
                            except json.JSONDecodeError:
                                continue

            try:
                assistant_messages = driver.find_elements(
                    By.CSS_SELECTOR, "div[data-message-author-role='assistant']"
                )
                if assistant_messages:
                    response_text = assistant_messages[-1].text.strip()
                    if response_text:
                        if response_text.startswith("```json"):
                            response_text = response_text[7:]
                        if response_text.startswith("```"):
                            response_text = response_text[3:]
                        if response_text.endswith("```"):
                            response_text = response_text[:-3]
                        response_text = response_text.strip()

                        start = response_text.find("[")
                        end = response_text.rfind("]")
                        if start != -1 and end != -1 and end > start:
                            response_text = response_text[start:end + 1]

                        data = json.loads(response_text)
                        if isinstance(data, list):
                            print(f"✅ Parsed JSON response with {len(data)} records")
                            return data
                        if isinstance(data, dict):
                            print("✅ Parsed JSON response with 1 record")
                            return [data]
            except Exception:
                pass

            time.sleep(poll_interval)

        print("❌ No valid JSON response found")
        return []

    except Exception as e:
        print(f"❌ Error extracting response: {e}")
        return []

# Append and clean data
def append_and_clean(data, file_path, lead_names=None):
    try:
        if not data:
            print("No data to append")
            return False
        
        new_data = pd.DataFrame(data)
        
        if lead_names and len(new_data) == len(lead_names):
            new_data.insert(0, "lead_name", lead_names)
        
        required_cols = ["lead_source", "lead_age_days", "days_since_last_interaction", 
                "total_interactions", "response_time_hours", "industry", 
                "lead_status", "next_best_action", "lead_name", "confidence_score"]
        
        for col in required_cols:
            if col not in new_data.columns:
                new_data[col] = "Unknown"
        
        numeric_cols = ["lead_age_days", "days_since_last_interaction", "total_interactions", 
                       "response_time_hours", "confidence_score"]
        for col in numeric_cols:
            if col in new_data.columns:
                new_data[col] = pd.to_numeric(new_data[col], errors='coerce').fillna(0)
        
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
            existing_data = pd.read_csv(file_path)
            if 'lead_name' in new_data.columns and 'lead_name' in existing_data.columns:
                new_data = new_data[~new_data['lead_name'].isin(existing_data['lead_name'])]
            final_data = pd.concat([existing_data, new_data], ignore_index=True)
        else:
            final_data = new_data
        
        final_data.to_csv(file_path, index=False)
        print(f"✅ Data appended to '{file_path}'. New rows: {len(new_data)}")
        return True
        
    except Exception as e:
        logging.error(f"Failed to append data: {e}")
        print(f"Failed to append data: {e}")
        return False

# Track missed leads
def track_missed_leads(leads):
    try:
        missed_data = pd.DataFrame({'Missed_Lead': leads, 'Timestamp': [datetime.now()] * len(leads)})
        if os.path.exists(missed_path) and os.path.getsize(missed_path) > 0:
            existing_data = pd.read_csv(missed_path)
            missed_data = pd.concat([existing_data, missed_data], ignore_index=True)
        missed_data.drop_duplicates(subset=['Missed_Lead'], keep='first').to_csv(missed_path, index=False)
        print(f"Missed leads saved to '{missed_path}'.")
    except Exception as e:
        logging.error(f"Failed to save missed leads: {e}")

# Main script
while True:
    print(f"\n📦 Generating {record_count} CRM records...")

    if send_generation_prompt(record_count):
        response = extract_response()
        if response:
            if not append_and_clean(response, output_path):
                print("Failed to append generated data")
        else:
            print("No response extracted")
            track_missed_leads(["no_response"])
    else:
        print("Failed to send generation prompt")
        track_missed_leads(["send_failed"])

    print("Waiting 5 seconds before next batch... (Press Ctrl+C to stop)")
    time.sleep(5)

print("\n🏁 Script finished.")
driver.quit()