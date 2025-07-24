#!/usr/bin/env python3
"""
Selenium Form Automation Example
"""

import json
import datetime
import socket
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, WebDriverException
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def setup_chrome_driver():
    """Set up Chrome driver with headless options"""
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    
    import os
    os.environ['DISPLAY'] = ':99'
    
    try:
        driver = webdriver.Chrome(options=chrome_options)
        return driver
    except Exception as e:
        logger.error(f"Failed to create Chrome driver: {e}")
        return None

def test_semaphore_login():
    """Test automated login to Semaphore UI"""
    driver = setup_chrome_driver()
    if not driver:
        return None
    
    try:
        start_time = time.time()
        
        # Navigate to Semaphore
        driver.get('http://localhost:3000')
        
        # Wait for login form
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, "username"))
        )
        
        # Fill login form
        username_field = driver.find_element(By.NAME, "username")
        password_field = driver.find_element(By.NAME, "password")
        
        username_field.send_keys("admin")
        password_field.send_keys("semaphorepassword")
        
        # Submit form
        login_button = driver.find_element(By.XPATH, "//button[@type='submit']")
        login_button.click()
        
        # Wait for redirect or dashboard
        time.sleep(3)
        
        # Check if login was successful
        current_url = driver.current_url
        page_title = driver.title
        
        execution_time = round((time.time() - start_time) * 1000, 2)
        
        result = {
            'log_type': 'selenium_automation',
            'automation_type': 'semaphore_login',
            'timestamp': datetime.datetime.now().isoformat(),
            'hostname': socket.gethostname(),
            'execution_time_ms': execution_time,
            'final_url': current_url,
            'page_title': page_title,
            'status': 'success' if 'dashboard' in current_url.lower() or 'project' in current_url.lower() else 'failed'
        }
        
        return result
        
    except Exception as e:
        return {
            'log_type': 'selenium_automation',
            'automation_type': 'semaphore_login',
            'timestamp': datetime.datetime.now().isoformat(),
            'hostname': socket.gethostname(),
            'status': 'error',
            'error': str(e)
        }
    finally:
        if driver:
            driver.quit()

def main():
    """Run form automation tests"""
    try:
        # Test Semaphore login
        login_result = test_semaphore_login()
        if login_result:
            print(json.dumps(login_result))
        
        logger.info("Form automation completed")
        
    except Exception as e:
        error_result = {
            'log_type': 'selenium_automation',
            'timestamp': datetime.datetime.now().isoformat(),
            'hostname': socket.gethostname(),
            'status': 'error',
            'error': str(e)
        }
        print(json.dumps(error_result))
        logger.error(f"Automation failed: {e}")

if __name__ == "__main__":
    main()
