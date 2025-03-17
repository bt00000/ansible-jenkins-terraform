import os
import requests
from requests.auth import HTTPBasicAuth

# Load Jenkins credentials from environment variables
JENKINS_URL = os.getenv('JENKINS_URL', 'http://localhost:8080')
JENKINS_USER = os.getenv('JENKINS_USER')
JENKINS_API_TOKEN = os.getenv('JENKINS_API_TOKEN')

def test_jenkins_running():
    """Test if Jenkins is running and responding with authentication."""
    try:
        response = requests.get(JENKINS_URL, timeout=5, auth=HTTPBasicAuth(JENKINS_USER, JENKINS_API_TOKEN))
        if response.status_code != 200:
            raise Exception(f"Jenkins is not running. Status code: {response.status_code}")
    except requests.exceptions.RequestException as e:
        raise Exception(f"Jenkins connection failed: {e}")
