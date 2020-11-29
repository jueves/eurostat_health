import os.path
import pandas as pd
import re
import requests
import json
from io import BytesIO
from zipfile import ZipFile

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
# Creates a json file for ICD-10 CM codes and short names

icd10_url = 'https://www.cms.gov/Medicare/Coding/ICD10/Downloads/2016-Code-Descriptions-in-Tabular-Order.zip'
icd10_file_name = 'data/icd10.json'
icd10_dic = dict()

if os.path.isfile(icd10_file_name):
  print('icd10.json is already downloaded.')
  
else:
  resp = requests.get(icd10_url).content
  data_zip = ZipFile(BytesIO(resp))
  for line in data_zip.open('icd10cm_order_2016.txt').readlines():
      code = line[6:14].strip().decode('utf-8')
      name = line[16:77].strip().decode('utf-8')
      icd10_dic[code] = name
  
  with open(icd10_file_name, 'w') as f:
    json_file = json.dumps(icd10_dic, indent=4)
    f.write(json_file)
