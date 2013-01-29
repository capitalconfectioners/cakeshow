import json, sys
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch

def generate_judging_forms(canvas, signup, entry):
	judging_header(canvas, signup, entry)
	if (entry.get('category') == 'Showcakes'):
		judging_showcake_body(canvas)
	else:
		judging_divisional_body(canvas)
	

def judging_header(canvas, signup, entry):
	# Prints Show info
	canvas.setFont("Helvetica-Bold", 20)
	canvas.drawString(inch, 10 * inch, "That Takes the Cake! " + signup.get('year'))
	canvas.setFont("Helvetica", 14)
	canvas.drawString(inch, 9.75 * inch, "Cake & Sugar Art Show & Competition")
	canvas.drawString(inch, 9.50 * inch, "Capital Confectioners, Austin, TX")
	canvas.drawString(inch, 9.25 * inch, "February 23 & 24, " + signup.get('year'))
	
	# Print entry number, division & category
	canvas.drawString(6.5 * inch, 10 * inch, "Entry #" + str(entry.get('id')))
	if (entry.get('category') == 'Showcakes'):
		canvas.drawString(6.5 * inch, 9.75 * inch, entry.get('category'))
	else:
		canvas.drawString(6.5 * inch, 9.75 * inch, signup.get('class'))
		canvas.drawString(6.5 * inch, 9.50 * inch, entry.get('category'))

def judging_divisional_body(canvas):
	criteria = ["Precision", "Originality", "Creativity", "Skill", "Color", "Design", "Difficulty", "Number of Techniques", "Overall Eye Appeal"]
#	canvas.drawString(4.5 * inch, 8.75 * inch, "Divisional Competition")
	
	# Table header
	canvas.drawString(3.30 * inch, 8.375 * inch, "    Needs")
	canvas.drawString(3.30 * inch, 8.125 * inch, "Improvement")
	canvas.drawString(4.85 * inch, 8.25 * inch, "Fair")
	canvas.drawString(5.750 * inch, 8.25 * inch, "Good")
	canvas.drawString(6.750 * inch, 8.25 * inch, "Excellent")
	
	# Display column of criteria
	offset = 7.75
	for criterium in criteria:
		canvas.drawString(1.125 * inch, offset * inch, criterium)
		offset -= 0.375
	
	# Build up rows
	rows = []
	offset = 8.00
	for criterium in criteria:
		rows.append(offset * inch)
		offset -= 0.375
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 3.25*inch, 4.50*inch, 5.50*inch, 6.50*inch, 7.75*inch], rows)
	
	
	# Display comments section
	offset -= 0.5
	canvas.drawString(inch, offset * inch, "Comments: ")
	canvas.line(2.25 * inch, offset * inch, 7.5 * inch, offset * inch)
	
	while (offset > 1.5):
		offset -= 0.5
		canvas.line(1 * inch, offset * inch, 7.5 * inch, offset * inch)
	

def judging_showcake_body(canvas):
	criteria = ["Application of Theme", "Precision of Techniques", "Originality & Creativity", "Appropriate Design", "Difficulty of Techniques", "Number of Techniques Used", "Overall Eye Appeal"]
	
	# Table header
	canvas.drawString(5.30 * inch, 8.375 * inch, "Maximum")
	canvas.drawString(5.30 * inch, 8.125 * inch, " Points")
	canvas.drawString(6.85 * inch, 8.375 * inch, " Points")
	canvas.drawString(6.85 * inch, 8.125 * inch, "Awarded")
	
	# Display column of criteria
	offset = 7.75
	for criterium in criteria:
		canvas.drawString(1.125 * inch, offset * inch, criterium)
		offset -= 0.375
	

if __name__ == "__main__":
	if (len(sys.argv) != 3): 
		print "ERROR: Must provide two parameters: JSON_FILE OUTPUT_DIR"
		sys.exit(2)
	json_file = str(sys.argv[1])
	output_dir = str(sys.argv[2])
	
	try: 
		json_data = open(json_file)
		data = json.load(json_data)
	except IOError as e:
		print "I/O error({0}): {1}".format(e.errno, e.strerror)
		sys.exit(2)
	
	canvas = canvas.Canvas("judging_forms.pdf", pagesize=letter)
	for contestant in data:
		for entry in contestant.get('entries'):
			generate_judging_forms(canvas, contestant.get('signup'), entry)
			canvas.showPage()
	canvas.save()