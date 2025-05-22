#!/bin/bash

echo "🔧 Setting up ASED backend locally..."

# Step 1: Create project folder if not already in it
mkdir -p ~/ased-backend && cd ~/ased-backend

# Step 2: Create and activate virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Step 3: Install required packages
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install fastapi uvicorn opencv-python pytesseract fpdf python-docx qrcode

# Step 4: Fix main.py with working root route (prevent overwrite)
cat << '__PY__' > main.py
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import StreamingResponse
import pytesseract, cv2, io, numpy as np
from fpdf import FPDF
from docx import Document
import qrcode

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "ASED backend is live"}

@app.post("/ocr")
async def ocr(file: UploadFile = File(...)):
    image = await file.read()
    npimg = cv2.imdecode(np.frombuffer(image, np.uint8), cv2.IMREAD_COLOR)
    text = pytesseract.image_to_string(npimg)
    return {"text": text}

@app.post("/export-pdf")
async def export_pdf(content: dict):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=12)
    for line in content.get("content", "").split("\n"):
        pdf.cell(200, 10, txt=line, ln=1)
    buf = io.BytesIO()
    pdf.output(buf)
    buf.seek(0)
    return StreamingResponse(buf, media_type="application/pdf")

@app.post("/export-docx")
async def export_docx(content: dict):
    doc = Document()
    for line in content.get("content", "").split("\n"):
        doc.add_paragraph(line)
    buf = io.BytesIO()
    doc.save(buf)
    buf.seek(0)
    return StreamingResponse(buf, media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document")

@app.post("/generate-qr")
async def generate_qr(data: dict):
    qr = qrcode.make(data.get("data", ""))
    buf = io.BytesIO()
    qr.save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(buf, media_type="image/png")
__PY__

# Step 5: Generate updated requirements.txt
pip freeze > requirements.txt

# Step 6: Kill anything using port 8000
echo "🧼 Cleaning up port 8000 if in use..."
PORT_PID=$(lsof -ti:8000)
if [ ! -z "$PORT_PID" ]; then
  kill -9 $PORT_PID
  echo "⚠️ Killed process on port 8000 (PID $PORT_PID)"
fi

# Step 7: Start the FastAPI server
echo "🚀 Starting ASED backend..."
uvicorn main:app --reload --host 0.0.0.0 --port 8000
