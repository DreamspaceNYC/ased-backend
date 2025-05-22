#!/bin/bash

echo "🚀 Preparing Render deployment for ASED backend..."

# Ensure you're in the project root
cd ~/ased-backend || { echo "❌ Folder not found: ~/ased-backend"; exit 1; }

# Create render.yaml
cat << '__YAML__' > render.yaml
services:
  - type: web
    name: ased-backend
    runtime: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port 10000
    envVars:
      - key: PYTHON_VERSION
        value: 3.12
    plan: free
__YAML__

# Git add, commit, and push
git add render.yaml
git commit -m "Add Render deploy config"
git push origin master

echo "✅ render.yaml added and pushed to GitHub."

# Open Render dashboard
open "https://dashboard.render.com/new/web?name=ased-backend"

echo "🌍 Next step: In the browser, connect GitHub repo and deploy."
