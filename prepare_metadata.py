import os.path
import pandas as pd
import re
import json
import requests

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


#############
# nuts.json #
#############
# Creates json file all NUTS codes.

nuts_url = 'https://ec.europa.eu/eurostat/documents/345175/629341/NUTS2021.xlsx'
nuts_file_name = 'data/nuts.json'

if os.path.isfile(nuts_file_name):
  print(nuts_file_name, 'is already downloaded.')
else:
  nuts = pd.read_excel(nuts_url, sheet_name='NUTS & SR 2021')
  
  dic_nuts = {0:dict(), 1:dict(), 2:dict(), 3:dict()}
  for index, row in nuts.iterrows():
    if not pd.isna(row["NUTS level"]):
      level = int(row["NUTS level"])
      code = row['Code 2021']
      name = row[1+level]
      dic_nuts[level][code] = name

  
  # Export dictionary to json
  with open(nuts_file_name, 'w') as f:
    json_dic = json.dumps(dic_nuts, indent=4)
    f.write(json_dic)

    
####################
# icd10_v2012.json #
####################
# This file has been manually edited due to numerous and diverse format
# inconsistencies in relation to codes found in data.
# 
# Here the most repetitive inconsistences are fixed and the table reformated as
# a json file in a convenient structure to be used in R.

icd10_df = pd.read_csv('data/COD_2012_edited.csv')

icd10_df.ICD_10_edited = icd10_df.ICD_10_edited.apply(lambda x:
                                                  re.sub(', ', '_', x).strip())

icd10_v2012_dic = {'names': dict(), 'levels': dict()}

for index, row in icd10_df.iterrows():
  icd10_v2012_dic['names'][row.ICD_10_edited] = row.DESC_EN
  icd10_v2012_dic['levels'][row.ICD_10_edited] = row.LEVEL

with open('data/icd10_v2012.json', 'w') as f:
  json_text = json.dumps(icd10_v2012_dic)
  f.write(json_text)

####################
# idc10_v2007.json #
####################
# This file has been updated regulary, but doesn't include levels for diagnoses.
icd10_file_name = 'data/icd10_v2007.json'
icd10_url = 'http://dd.eionet.europa.eu/vocabulary/eurostat/icd10/json' # json

# Get file
if os.path.isfile(icd10_file_name):
  print(icd10_file_name, 'is already downloaded.')
else:
  icd10_req = requests.get(icd10_url)
  icd10 = json.loads(icd10_req.content)
  
  # Process file
  icd10_v2007_dic = {'names': dict(), 'levels': dict(),
                     'inverse_levels': {0:list(), 1:list(), 2:list(), 3:list()}}
  for element in icd10['concepts']:
    icd10_v2007_dic['names'][element['Notation']] = element['Label']

  # Add levels from ICD10 v2007
  for index, row in icd10_df.iterrows():
    icd10_v2007_dic['levels'][row.ICD_10_edited] = row.LEVEL
    icd10_v2007_dic['inverse_levels'][row.LEVEL].append(row.ICD_10_edited)
    
  # Export to json
  with open('data/icd10_v2007.json', 'w') as f:
    json_text = json.dumps(icd10_v2007_dic)
    f.write(json_text)

