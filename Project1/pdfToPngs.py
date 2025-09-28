from pdf2image import convert_from_path
import pdfplumber
import re
import os

pdf_path = "SIMD_Advantage_Profiling_Graphs.pdf"
output_folder = "pngImages"
dpi = 200

# Make sure the output folder exists
os.makedirs(output_folder, exist_ok=True)

# Convert PDF pages to images
images = convert_from_path(pdf_path, dpi=dpi)

# Open PDF with pdfplumber to extract text
with pdfplumber.open(pdf_path) as pdf:
	for i, (page, img) in enumerate(zip(pdf.pages, images), 1):
		# Extract text from page
		text = page.extract_text() or ""
		first_line = text.splitlines()[0].strip() if text else f"page_{i}"
		safe_name = re.sub(r'[^A-Za-z0-9_\-]+', '_', first_line)
		if (safe_name[-1] == "_"):
			first_line += text.splitlines()[1].strip() if text else f"page_{i}"
			safe_name = re.sub(r'[^A-Za-z0-9_\-]+', '_', first_line)

		# Save image with first line as filename
		img.save(os.path.join(output_folder, f"GF_{safe_name}.png"), "PNG")
