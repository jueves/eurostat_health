import os.path
import pandas as pd
import re
import json


###################
# spain_nuts.json #
###################
# Creates json file for spanish NUTS2 codes and names.

nuts_url = 'https://ec.europa.eu/eurostat/documents/345175/629341/NUTS2021.xlsx'
nuts_file_name = 'data/spain_nuts2.json'

if os.path.isfile(nuts_file_name):
  print(nuts_file_name, 'is already downloaded.')
else:
  nuts = pd.read_excel(nuts_url, sheet_name='NUTS & SR 2021')
  
  dic_nuts = {}
  for index, row in nuts.iterrows():
    code = row['Code 2021']
    if isinstance(code, str):
      spain_match = re.match('^ES\d', code)
      if isinstance(spain_match, re.Match) and row['NUTS level']==2:
        dic_nuts[code] = row['NUTS level 2']
  
  # Export dictionary to json
  with open(nuts_file_name, 'w') as f:
    json_dic = json.dumps(dic_nuts, indent=4)
    f.write(json_dic)
