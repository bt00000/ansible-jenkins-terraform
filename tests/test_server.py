import os
import requests

# Load environment variables (falling back to defaults)
JENKINS_URL = os.getenv('JENKINS_URL', 'http://localhost:8080')
NGINX_URL = os.getenv('NGINX_URL', 'http://localhost')

def test_jenkins_running():
    """Test if Jenkins is running and responding."""
    try:
        response = requests.get(JENKINS_URL, timeout=5)
        assert response.status_code == 200, "Jenkins is not running"
        assert 'redirect' in response.text.lower(), "Jenkins login page not found"
    except requests.exceptions.RequestException as e:
        assert False, f"Jenkins connection failed: {e}"

def test_nginx_running():
    """Test if Nginx is running and serving content."""
    try:
        response = requests.get(NGINX_URL, timeout=5)
        assert response.status_code == 200, "Nginx is not responding"
        assert "nginx" in response.text.lower(), "Nginx page does not contain expected content"
    except requests.exceptions.RequestException as e:
        assert False, f"Nginx connection failed: {e}"
