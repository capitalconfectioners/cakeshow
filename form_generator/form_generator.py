import json, sys, calendar
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch

def generate_judging_form(canvas, signup, entry):
	header(canvas, signup, entry)
	if (entry.get('category') == 'Showcakes'):
		judging_showcake_body(canvas)
	elif ((entry.get('category').find("Tasting") >= 0) or (entry.get('category').find("tasting") >= 0)):
		judging_tasting_body(canvas)
	else:
		judging_divisional_body(canvas)
	

def header(canvas, signup, entry):
	year = signup.get('year')
	
	# Prints Show info
	canvas.setFont("Helvetica-Bold", 20)
	canvas.drawString(inch, 10 * inch, "That Takes the Cake! " + str(year))
	canvas.setFont("Helvetica", 14)
	canvas.drawString(inch, 9.75 * inch, "Cake & Sugar Art Show & Competition")
	canvas.drawString(inch, 9.50 * inch, "Capital Confectioners, Austin, TX")
	
	canvas.drawString(inch, 9.25 * inch, get_show_start_date(year) + " & " + get_show_end_date(year))
	
	# Print entry number, division & category
	canvas.drawString(6.5 * inch, 10 * inch, "Entry #" + str(entry.get('id')))
	if (entry.get('category') == 'Showcakes'):
		canvas.drawString(6.5 * inch, 9.75 * inch, entry.get('category'))
	elif ((entry.get('category').find("Tasting") >= 0) or (entry.get('category').find("tasting") >= 0)):
		canvas.drawString(6.5 * inch, 9.75 * inch, entry.get('category'))
	else:
		canvas.drawString(6.5 * inch, 9.75 * inch, signup.get('class'))
		className = signup.get('class')
		if (className):
			if ((className.find('Child') < 0) and (className.find('Junior') < 0)):
				canvas.drawString(6.5 * inch, 9.50 * inch, entry.get('category'))

def get_show_start_date(year):
	# Calculate date of show; Monday = 0
	last_day = calendar.weekday(int(year), 2, 28)
	saturday = 28 - last_day - 2
	return "February " + str(saturday)
	
def get_show_end_date(year):
	# Calculate date of show; Monday = 0
	last_day = calendar.weekday(int(year), 2, 28)
	sunday = 28 - last_day - 1
	# If the 28th is on a Saturday and not a leap year
	if (last_day == 5):
		if (calendar.isleap(year)):
			sunday = 29
		else:
			sunday = "March 1"
	else:
		sunday = str(sunday)
	return sunday

def judging_divisional_body(canvas):
	criteria = ["Precision", "Originality", "Creativity", "Skill", "Color", "Design", "Difficulty", "Number of Techniques", "Overall Eye Appeal"]
	
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
	criteria = ["Application of Theme", "Precision of Techniques", "Originality & Creativity", "Appropriate Design (size, shape, colors, etc.)", "Difficulty of Techniques", "Number of Techniques Used", "Overall Eye Appeal (Judge's discretion)"]
	maximum_points = [15, 15, 15, 15, 15, 15, 10]
	
	# Table header
	canvas.drawString(5.85 * inch, 8.375 * inch, "Maximum")
	canvas.drawString(5.85 * inch, 8.125 * inch, "  Points")
	canvas.drawString(6.85 * inch, 8.375 * inch, "  Points")
	canvas.drawString(6.85 * inch, 8.125 * inch, "Awarded")
	
	# Display column of criteria
	offset = 7.75
	index = 0
	for criterium in criteria:
		canvas.drawString(1.125 * inch, offset * inch, criterium)
		canvas.drawString(6.125 * inch, offset * inch, str(maximum_points[index]))
		offset -= 0.375
		index += 1
	canvas.drawString(6.125 * inch, offset * inch, "Total:")
	
	# Build up rows
	rows = []
	offset = 8.00
	for criterium in criteria:
		rows.append(offset * inch)
		offset -= 0.375
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 5.75*inch, 6.75*inch, 7.75*inch], rows)
	canvas.grid([6.75*inch, 7.75*inch], [offset * inch, (offset - 0.375) * inch])
	offset -= 0.375
	
	# Display comments section
	offset -= 0.5
	canvas.drawString(inch, offset * inch, "Comments: ")
	canvas.line(2.25 * inch, offset * inch, 7.5 * inch, offset * inch)
	
	while (offset > 1.5):
		offset -= 0.5
		canvas.line(1 * inch, offset * inch, 7.5 * inch, offset * inch)

def judging_tasting_body(canvas):
	criteria = ["Flavor", "Crumb", "Texture", "Density", "Appearance", "Theme"]
	maximum_points = [40, 10, 10, 10, 15, 15]
	
	# Table header
	canvas.drawString(5.85 * inch, 8.375 * inch, "Maximum")
	canvas.drawString(5.85 * inch, 8.125 * inch, "  Points")
	canvas.drawString(6.85 * inch, 8.375 * inch, "  Points")
	canvas.drawString(6.85 * inch, 8.125 * inch, "Awarded")
	
	# Display column of criteria
	offset = 7.75
	index = 0
	for criterium in criteria:
		canvas.drawString(1.125 * inch, offset * inch, criterium)
		canvas.drawString(6.125 * inch, offset * inch, str(maximum_points[index]))
		offset -= 0.375
		index += 1
	canvas.drawString(6.125 * inch, offset * inch, "Total:")
	
	# Build up rows
	rows = []
	offset = 8.00
	for criterium in criteria:
		rows.append(offset * inch)
		offset -= 0.375
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 5.75*inch, 6.75*inch, 7.75*inch], rows)
	canvas.grid([6.75*inch, 7.75*inch], [offset * inch, (offset - 0.375) * inch])
	offset -= 0.375
	
	# Display comments section
	offset -= 0.5
	canvas.drawString(inch, offset * inch, "Comments: ")
	canvas.line(2.25 * inch, offset * inch, 7.5 * inch, offset * inch)
	
	while (offset > 1.5):
		offset -= 0.5
		canvas.line(1 * inch, offset * inch, 7.5 * inch, offset * inch)


def generate_entry_form(canvas, signup, entry, registrant):
	line_count = 4
	header(canvas, signup, entry)
	
	canvas.drawString(inch, 8.0 * inch, "Entry Title:")
	canvas.line(2.25 * inch, 8.0 * inch, 7.5 * inch, 8.0 * inch)
	
	# Leave blank for tasting recipe
	category = entry.get('category')
	if ((category.find("Tasting") >= 0) or (category.find("tasting") >= 0)):
		canvas.drawString(inch, 7.5 * inch, "Recipe:")
	else:
		canvas.drawString(inch, 7.5 * inch, "Description:")
		canvas.line(2.25 * inch, 7.5 * inch, 7.5 * inch, 7.5 * inch)
	
		canvas.drawString(inch, 7.0 * inch, "Techniques Used:")
		line_num = 0
		offset = 6.5
		while (line_num < line_count):
			canvas.line(inch, offset * inch, 7.5 * inch, offset * inch)
			offset -= 0.5
			line_num += 1
	
		canvas.drawString(inch, offset * inch, "Media Used:")
		line_num = 0
		offset -= 0.5
		while (line_num < line_count):
			canvas.line(inch, offset * inch, 7.5 * inch, offset * inch)
			offset -= 0.5
			line_num += 1
	
	# print entry numbers on the labels
	canvas.drawString(0.75 * inch, inch, str(entry.get('id')))
	canvas.drawString(2.75 * inch, inch, str(entry.get('id')))
	canvas.drawString(4.75 * inch, inch, str(entry.get('id')))
	canvas.drawString(7.00 * inch, 1.125 * inch, str(entry.get('id')))
	
	# print name on last label
	canvas.setFont("Helvetica", 10)
	canvas.drawString(6.5 * inch, 0.90 *inch, str(registrant.get('firstname')))
	canvas.drawString(6.5 * inch, 0.75 *inch, str(registrant.get('lastname')))
	if (entry.get('category') == 'Showcakes'):
		canvas.drawString(6.5 * inch, 0.60 *inch, "Showcakes")
	elif ((entry.get('category').find("Tasting") >= 0) or (entry.get('category').find("tasting") >= 0)):
		canvas.drawString(6.5 * inch, 0.60 *inch, "Tasting")
	else:
		canvas.drawString(6.5 * inch, 0.60 *inch, str(signup.get('class')))
	
def generate_registration_and_release_form(canvas, signup, registrant, divisionals, tastings):
	year = signup.get('year')
	sunday = get_show_end_date(year)
	if (sunday.find("March") < 0):
		sunday = "February " + sunday

	canvas.setFont("Helvetica-Bold", 20)
	canvas.drawString(inch, 10 * inch, year + " Competition Registration and Release Form")
	canvas.setFont("Helvetica-Bold", 18)
	canvas.drawString(2.75 * inch, 9.50 * inch, "That Takes the Cake! " + str(year))
	canvas.setFont("Helvetica", 14)
	canvas.drawString(2.65 * inch, 9.25 * inch, "Cake & Sugar Art Show & Competition")
	canvas.drawString(2.90 * inch, 9.00 * inch, "Capital Confectioners, Austin, TX")
	
	canvas.setFont("Helvetica-Bold", 14)
	canvas.drawString(inch, 8.70 * inch, registrant.get('lastname') + ", " + registrant.get('firstname'))
	canvas.setFont("Helvetica", 14)
	if (registrant.get('address')):
		canvas.drawString(inch, 8.50 * inch, registrant.get('address'))
	if ((registrant.get('city')) and (registrant.get('state')) and (registrant.get('zipcode'))):
		canvas.drawString(inch, 8.30 * inch, registrant.get('city') + ", " + registrant.get('state') + " " + registrant.get('zipcode'))
	if (registrant.get('email')):
		canvas.drawString(inch, 8.10 * inch, registrant.get('email'))
	if (registrant.get('phone')):
		canvas.drawString(inch, 7.90 * inch, registrant.get('phone'))
	
	# Build up list of entry numbers by entry type
	entries = {}
	for entry in contestant.get('entries'):
		if (entries.get(entry['category']) is None):
			entries[entry['category']] = str(entry['id'])
		else:
			entries[entry['category']] += ", " + str(entry['id'])
	
	# Print Divisionals table
	canvas.setFont("Helvetica-Bold", 10)
	division = "Divisional Competition: "
	if (signup.get('class')):
		division += signup['class']
	canvas.drawString(inch, 7.55 * inch, division)
	canvas.setFont("Helvetica", 10)
	offset = 7.35
	for division in divisionals:
		canvas.drawString(1.1*inch, offset * inch, division)
		if (entries.get(division)):
			canvas.drawString(3.1*inch, offset * inch, entries[division])
		offset -= 0.2
		
	# Build up rows
	rows = []
	offset = 7.5
	for division in divisionals:
		rows.append(offset * inch)
		offset -= 0.2
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 3*inch, 7.75*inch], rows)
	
	# Print tastings table
	offset -= 0.4
	table_offset = offset
	canvas.setFont("Helvetica-Bold", 10)
	canvas.drawString(inch, offset * inch, "Tasting Competition: ")
	canvas.setFont("Helvetica", 10)
	offset -= 0.2
	for tasting in tastings:
		canvas.drawString(1.1*inch, offset * inch, tasting)
		if (entries.get(tasting)):
			canvas.drawString(3.1*inch, offset * inch, entries[tasting])
		offset -= 0.2
		
	# Build up rows
	rows = []
	offset = table_offset - 0.05
	for tasting in tastings:
		rows.append(offset * inch)
		offset -= 0.2
	rows.append(offset * inch)
	
	# Draw grid
	canvas.grid([inch, 3*inch, 7.75*inch], rows)
	
	# Print Showcakes table
	offset -= 0.4
	table_offset = offset - 0.05
	canvas.setFont("Helvetica-Bold", 10)
	canvas.drawString(inch, offset * inch, "Showcake Competition: ")
	canvas.setFont("Helvetica", 10)
	offset -= 0.2
	canvas.drawString(1.1*inch, offset * inch, "Showcakes")
	if (entries.get('Showcakes')):
			canvas.drawString(3.1*inch, offset * inch, entries['Showcakes'])
	# Draw grid
	canvas.grid([inch, 3*inch, 7.75*inch], [table_offset * inch, (table_offset - 0.2) * inch])

	canvas.setFont("Helvetica", 10)
	canvas.drawString(0.5 * inch, 3.10 * inch, "Release: By signing below, I understand that my entry(ies) may be photographed and published for the promotion of")
	canvas.drawString(0.5 * inch, 2.95 * inch, "Capital Confectioners, the Cake and Sugar Arts Show and general interest. I hereby agree to abide by the rules and ")
	canvas.drawString(0.5 * inch, 2.80 * inch, "regulations of the show. I understand that the Capital Confectioners Cake Club, Make It Sweet or any sponsors assume")
	canvas.drawString(0.5 * inch, 2.65 * inch, "no responsibility for loss, theft, or damage to displays or personal items at the Show. I agree to indemnify and hold")
	canvas.drawString(0.5 * inch, 2.50 * inch, "harmless the Capital Confectioners Cake Club, Make It Sweet, and all sponsors from and against all claims, demands,")
	canvas.drawString(0.5 * inch, 2.35 * inch, "costs, loss, damage, expense, attorney's fees and liabilities growing out of, or arising from, caused or occasioned by")
	canvas.drawString(0.5 * inch, 2.20 * inch, "my activities in the Capital Confectioners Cake and Sugar Art Show.")

	canvas.setFont("Helvetica-Bold", 10)
	canvas.drawString(0.5 * inch, 1.90 * inch, "I understand that I cannot remove my entry before 5 pm on Sunday, " + sunday + " and that entries left after 7 pm")
	canvas.drawString(0.5 * inch, 1.75 * inch, "become the property of Capital Confectioners.")
	
	canvas.drawString(0.5 * inch, 1.45 * inch, "I understand that any entries into the tasting competition become the property of Capital Confectioners and that")
	canvas.drawString(0.5 * inch, 1.3 * inch, "platters/plates or the remainder of the entry after judging will not be returned.")
	
	canvas.drawString(0.5 * inch, inch, "Signature:")
	canvas.line(1.4 * inch, inch, 5.65 * inch, inch)
	canvas.drawString(5.75 * inch, inch, "Date:")
	canvas.line(6.25 * inch, inch, 8 * inch, inch)
			

if __name__ == "__main__":
	if (len(sys.argv) != 3): 
		print "ERROR: Must provide two parameters: JSON_FILE OUTPUT_FILE"
		sys.exit(2)
	json_file = str(sys.argv[1])
	output_file = str(sys.argv[2])
	
	try: 
		json_data = open(json_file)
		data = json.load(json_data)
	except IOError as e:
		print "I/O error({0}): {1}".format(e.errno, e.strerror)
		sys.exit(2)
	
	canvas = canvas.Canvas(output_file, pagesize=letter)
	for contestant in data['entries']:
		# Put all of the contestant's entry forms together
		for entry in contestant.get('entries'):
			generate_entry_form(canvas, contestant.get('signup'), entry, contestant.get('registrant'))
			canvas.showPage()
	for contestant in data['entries']:
		# Print R&R form
		generate_registration_and_release_form(canvas, contestant.get('signup'), contestant.get('registrant'), data['metadata']['divisionals'], data['metadata']['tastings'])
		canvas.showPage()
		
		# Put all of the contestant's judging sheets together
		for entry in contestant.get('entries'):
			generate_judging_form(canvas, contestant.get('signup'), entry)
			canvas.showPage()
	canvas.save()