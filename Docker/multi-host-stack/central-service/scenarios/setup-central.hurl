# Setup script for Central Server
# This initializes the Central Server and Management Security Server

# Wait for services to be ready
GET https://{{cs_host}}:4000
HTTP 200 302 401

# Additional setup steps can be added here
# For now, manual configuration through UI is recommended

