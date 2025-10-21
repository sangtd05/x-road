# Setup script for Security Server
# This can be used to automate Security Server initialization

# Wait for Security Server to be ready
GET https://{{ss_host}}:4000
HTTP 200 302 401

# Additional setup steps can be added here
# For now, manual configuration through UI is recommended

