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
    
##############
# icd10.json #
##############
# This file has been manually edited due to numerous and diverse format
# inconsistencies in relation to codes found in data.
# 
# Here the most repetitive inconsistences are fixed and the table reformated as
# a json file in a convenient structure to be used in R.

icd10 = pd.read_csv('data/COD_2012_edited.csv')

icd10.ICD_10_edited = icd10.ICD_10_edited.apply(lambda x:
                                                  re.sub(', ', '_', x).strip())

icd10_dic = {'names': dict(), 'levels': dict()}

for index, row in icd10.iterrows():
  icd10_dic['names'][row.ICD_10_edited] = row.DESC_EN
  icd10_dic['levels'][row.ICD_10_edited] = row.LEVEL

with open('data/icd10.json', 'w') as f:
  json_text = json.dumps(icd10_dic)
  f.write(json_text)
