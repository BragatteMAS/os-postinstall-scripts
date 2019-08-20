# Read .csv

import csv

file = '__name__.csv'

with open(file, 'r') as f:
	csv_reader = csv.reader(f, delimiter = ',')
	#next(csv_reader, None)
	for row in csv_reader:
		print(row)
