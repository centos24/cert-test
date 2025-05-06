import csv
import xlsxwriter
import os

current_directory = os.path.dirname(os.path.abspath(__file__))
workbook = xlsxwriter.Workbook('data.xlsx')
for filename in os.listdir(current_directory):
    if filename.endswith('.csv'):
        with open(filename, 'r') as f:
            filename_split = filename.split(".")
            filename_lenght = len(filename_split)
            if filename_lenght <= 3:
                filename_sheet = filename_split[0]
            else:
                filename_sheet = ".".join([filename_split[0], filename_split[1]])
            worksheet = workbook.add_worksheet(filename_sheet)
            header_format = workbook.add_format({
                'bold': True,
                'bg_color': '#C4D79B',
                'align': 'center',
                'border': 1
            })
            worksheet.write(0, 0, 'Package', header_format)
            worksheet.write(0, 1, 'Current', header_format)
            worksheet.write(0, 2, 'New', header_format)
            row = csv.reader(f, delimiter=' ')
            data = list(row)
            for row_idx, line in enumerate(data, start=1):
                if len(line) == 3:
                    for kol_idx, value in enumerate(line):
                        worksheet.write(row_idx, kol_idx, value)
            worksheet.autofit()
workbook.close()
