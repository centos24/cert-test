import pandas as pd

input_file = 'data.xlsx'
df = pd.read_excel(input_file)

columns = df.iloc[:, :4]

output_file = 'output.txt'

with open(output_file, 'w', encoding='utf-8') as f:
    for i, row in columns.iterrows():
        col1 = str(row.iloc[0])[:50].ljust(50)
        col2 = str(row.iloc[1])[:60].ljust(60)
        col3 = str(row.iloc[2])[:70].ljust(70)
        if i == 0:
            f.write(f"^ {col1}^ {col2}^ {col3}^\n")
        else:
            f.write(f"| {col1}| {col2}| {col3}|\n")
print(f"Data saved to {output_file}")
